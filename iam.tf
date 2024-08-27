#------------------------------------------------------------------------------
# TFE IAM role
#------------------------------------------------------------------------------
resource "aws_iam_role" "tfe_ec2" {
  name        = "${var.friendly_name_prefix}-tfe-instance-role-${data.aws_region.current.name}"
  path        = "/"
  description = "TFE instance role for EC2 instances"

  assume_role_policy = data.aws_iam_policy_document.tfe_ec2_assume_role.json

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-instance-role-${data.aws_region.current.name}" },
    var.common_tags
  )
}

data "aws_iam_policy_document" "tfe_ec2_assume_role" {
  statement {
    sid     = "TFEEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#------------------------------------------------------------------------------
# TFE IAM role policy
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "tfe_ec2" {
  name   = "${var.friendly_name_prefix}-tfe-instance-role-policy-${data.aws_region.current.name}"
  role   = aws_iam_role.tfe_ec2.id
  policy = data.aws_iam_policy_document.tfe_ec2_combined.json
}

data "aws_iam_policy_document" "tfe_ec2_allow_s3" {
  count = var.tfe_object_storage_s3_use_instance_profile ? 1 : 0

  statement {
    sid    = "TfeEc2AllowS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.tfe.arn}",
      "${aws_s3_bucket.tfe.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_cost_estimation" {
  count = var.tfe_cost_estimation_iam_enabled ? 1 : 0

  statement {
    sid    = "TfeEc2AllowCostEstimation"
    effect = "Allow"
    actions = [
      "pricing:DescribeServices",
      "pricing:GetAttributeValues",
      "pricing:GetProducts"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_license_secret" {
  count = var.tfe_license_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetLicenseSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_license_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_enc_password_secret" {
  count = var.tfe_encryption_password_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetEncPasswordSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_encryption_password_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_tls_cert_secret" {
  count = var.tfe_tls_cert_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetTlsCertSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_tls_cert_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_tls_privkey_secret" {
  count = var.tfe_tls_privkey_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetTlsPrivKeySecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_tls_privkey_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_tls_ca_bundle_secret" {
  count = var.tfe_tls_ca_bundle_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetTlsCaBundleSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_tls_ca_bundle_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_get_rds_password_secret" {
  count = var.tfe_database_password_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2GetRdsPasswordSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_database_password_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_get_redis_password_secret" {
  count = var.tfe_redis_password_secret_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowGetRedisPasswordSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.tfe_redis_password_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_rds_kms_cmk" {
  count = var.rds_kms_key_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowRdsKmsCmk"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*"
    ]
    resources = [
      var.rds_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_s3_kms_cmk" {
  count = var.s3_kms_key_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowS3KmsCmk"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*"
    ]
    resources = [
      var.s3_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_redis_kms_cmk" {
  count = var.redis_kms_key_arn != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowRedisKmsCmk"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*"
    ]
    resources = [
      var.redis_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_s3_log_fwd" {
  count = var.tfe_log_forwarding_enabled && var.s3_log_fwd_bucket_name != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowS3LogFwd"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${data.aws_s3_bucket.log_fwd[0].arn}",
      "${data.aws_s3_bucket.log_fwd[0].arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_allow_cloudwatch" {
  count = var.tfe_log_forwarding_enabled && var.cloudwatch_log_group_name != null ? 1 : 0

  statement {
    sid    = "TfeEc2AllowCloudWatch"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "${data.aws_cloudwatch_log_group.log_fwd[0].arn}",
      "${data.aws_cloudwatch_log_group.log_fwd[0].arn}:*"
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_ecr_image_pull" {
  count = var.tfe_run_pipeline_image_ecr_repo_name != null ? 1 : 0

  statement {
    sid    = "TfeEc2PullImageFromEcr"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage"
    ]

    resources = [
      data.aws_ecr_repository.tfe_run_pipeline_image[0].arn
    ]
  }

  statement {
    sid    = "TfeEc2AuthToEcr"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "tfe_ec2_combined" {
  source_policy_documents = [
    var.tfe_object_storage_s3_use_instance_profile ? data.aws_iam_policy_document.tfe_ec2_allow_s3[0].json : "",
    var.tfe_cost_estimation_iam_enabled ? data.aws_iam_policy_document.tfe_ec2_allow_cost_estimation[0].json : "",
    var.tfe_license_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_license_secret[0].json : "",
    var.tfe_encryption_password_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_enc_password_secret[0].json : "",
    var.tfe_tls_cert_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_tls_cert_secret[0].json : "",
    var.tfe_tls_privkey_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_tls_privkey_secret[0].json : "",
    var.tfe_tls_ca_bundle_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_tls_ca_bundle_secret[0].json : "",
    var.tfe_database_password_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_get_rds_password_secret[0].json : "",
    var.tfe_redis_password_secret_arn != null ? data.aws_iam_policy_document.tfe_ec2_allow_get_redis_password_secret[0].json : "",
    var.rds_kms_key_arn != null ? data.aws_iam_policy_document.tfe_ec2_allow_rds_kms_cmk[0].json : "",
    var.s3_kms_key_arn != null ? data.aws_iam_policy_document.tfe_ec2_allow_s3_kms_cmk[0].json : "",
    var.redis_kms_key_arn != null ? data.aws_iam_policy_document.tfe_ec2_allow_redis_kms_cmk[0].json : "",
    var.tfe_log_forwarding_enabled && var.s3_log_fwd_bucket_name != null ? data.aws_iam_policy_document.tfe_ec2_allow_s3_log_fwd[0].json : "",
    var.tfe_log_forwarding_enabled && var.cloudwatch_log_group_name != null ? data.aws_iam_policy_document.tfe_ec2_allow_cloudwatch[0].json : "",
    var.tfe_run_pipeline_image_ecr_repo_name != null ? data.aws_iam_policy_document.tfe_ec2_ecr_image_pull[0].json : ""
  ]
}

resource "aws_iam_role_policy_attachment" "aws_ssm" {
  count = var.ec2_allow_ssm ? 1 : 0

  role       = aws_iam_role.tfe_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#------------------------------------------------------------------------------
# TFE instance profile
#------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "tfe_ec2" {
  name = "${var.friendly_name_prefix}-tfe-instance-profile-${data.aws_region.current.name}"
  path = "/"
  role = aws_iam_role.tfe_ec2.name
}
