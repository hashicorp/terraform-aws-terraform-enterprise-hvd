#------------------------------------------------------------------------------
# S3 bucket
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "tfe" {
  bucket = "${var.friendly_name_prefix}-tfe-app-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-app-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}" },
    var.common_tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfe" {
  bucket = aws_s3_bucket.tfe.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "tfe" {
  bucket = aws_s3_bucket.tfe.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfe" {
  count = var.s3_kms_key_arn != null ? 1 : 0

  bucket = aws_s3_bucket.tfe.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "tfe" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.tfe]

  bucket = aws_s3_bucket.tfe.id
  role   = aws_iam_role.s3_crr[0].arn

  rule {
    id     = "tfe-s3-crr"
    status = "Enabled"

    dynamic "source_selection_criteria" {
      for_each = var.s3_destination_bucket_kms_key_arn == null ? [] : [1]

      content {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
      }
    }

    destination {
      bucket = var.s3_destination_bucket_arn

      dynamic "encryption_configuration" {
        for_each = var.s3_destination_bucket_kms_key_arn == null ? [] : [1]

        content {
          replica_kms_key_id = var.s3_destination_bucket_kms_key_arn
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
# S3 cross-region replication IAM
#------------------------------------------------------------------------------
resource "aws_iam_role" "s3_crr" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-s3-crr-iam-role-${data.aws_region.current.name}"
  path        = "/"
  description = "Custom IAM role for TFE S3 bucket cross-region replication."

  assume_role_policy = data.aws_iam_policy_document.s3_crr_assume_role[0].json

  tags = merge(
    { Name = "${var.friendly_name_prefix}-tfe-s3-crr-iam-role-${data.aws_region.current.name}" },
    var.common_tags
  )
}

data "aws_iam_policy_document" "s3_crr_assume_role" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "s3_crr" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-s3-crr-iam-policy-${data.aws_region.current.name}"
  description = "Custom IAM policy for TFE S3 bucket cross-region replication."
  policy      = data.aws_iam_policy_document.s3_crr[0].json
}

data "aws_iam_policy_document" "s3_crr" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.tfe.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.tfe.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    effect = "Allow"
    resources = [
      "${var.s3_destination_bucket_arn}/*"
    ]
  }

  # Conditionally add the KMS permissions
  dynamic "statement" {
    for_each = var.s3_kms_key_arn != "" ? [1] : []

    content {
      actions = [
        "kms:Decrypt"
      ]
      effect = "Allow"
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.${split(":", var.s3_kms_key_arn)[3]}.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values = [
          "${aws_s3_bucket.tfe.arn}/*"
        ]
      }
      resources = [
        var.s3_kms_key_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.s3_kms_key_arn != "" ? [1] : []

    content {
      actions = [
        "kms:Encrypt"
      ]
      effect = "Allow"
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.${split(":", var.s3_destination_bucket_kms_key_arn)[3]}.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values = [
          "${var.s3_destination_bucket_arn}/*"
        ]
      }
      resources = [
        var.s3_destination_bucket_kms_key_arn
      ]
    }
  }
}

resource "aws_iam_policy_attachment" "s3_crr" {
  count = var.s3_enable_bucket_replication && !var.is_secondary_region ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-s3-crr-iam-policy-attach-${data.aws_region.current.name}"
  roles      = [aws_iam_role.s3_crr[0].name]
  policy_arn = aws_iam_policy.s3_crr[0].arn
}