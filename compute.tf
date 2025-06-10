# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Log forwarding (Fluent Bit) config
#------------------------------------------------------------------------------
locals {
  // CloudWatch destination
  fluent_bit_cloudwatch_args = {
    aws_region                = data.aws_region.current.name
    cloudwatch_log_group_name = var.cloudwatch_log_group_name == null ? "" : var.cloudwatch_log_group_name
  }
  fluent_bit_cloudwatch_config = (var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "cloudwatch" ?
    (templatefile("${path.module}/templates/fluent-bit-cloudwatch.conf.tpl", local.fluent_bit_cloudwatch_args))
    : ""
  )

  // S3 destination
  fluent_bit_s3_args = {
    aws_region             = data.aws_region.current.name
    s3_log_fwd_bucket_name = var.s3_log_fwd_bucket_name == null ? "" : var.s3_log_fwd_bucket_name
  }
  fluent_bit_s3_config = (var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "s3" ?
    (templatefile("${path.module}/templates/fluent-bit-s3.conf.tpl", local.fluent_bit_s3_args))
    : ""
  )

  // Custom destination
  fluent_bit_custom_config = (var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "custom" ?
    var.custom_fluent_bit_config
    : ""
  )

  // Final rendered config
  fluent_bit_rendered_config = join("", [local.fluent_bit_cloudwatch_config, local.fluent_bit_s3_config, local.fluent_bit_custom_config])
}

#------------------------------------------------------------------------------
# User data (cloud-init) script arguments
#------------------------------------------------------------------------------
locals {
  s3_no_proxy              = "${aws_s3_bucket.tfe.bucket_domain_name},${aws_s3_bucket.tfe.bucket_regional_domain_name}"
  secrets_manager_no_proxy = "secretsmanager.${data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"

  addl_no_proxy_base = join(",", [
    "localhost",
    "127.0.0.1",
    "169.254.169.254",
    var.tfe_fqdn,
    local.s3_no_proxy,
    local.secrets_manager_no_proxy
  ])

  user_data_args = {
    # Bootstrap
    aws_region                         = data.aws_region.current.name
    tfe_license_secret_arn             = var.tfe_license_secret_arn
    tfe_tls_cert_secret_arn            = var.tfe_tls_cert_secret_arn
    tfe_tls_privkey_secret_arn         = var.tfe_tls_privkey_secret_arn
    tfe_tls_ca_bundle_secret_arn       = var.tfe_tls_ca_bundle_secret_arn
    tfe_encryption_password_secret_arn = var.tfe_encryption_password_secret_arn
    tfe_image_repository_url           = var.tfe_image_repository_url
    tfe_image_name                     = var.tfe_image_name
    tfe_image_tag                      = var.tfe_image_tag
    tfe_image_repository_username      = var.tfe_image_repository_username
    tfe_image_repository_password      = var.tfe_image_repository_password == null ? "" : var.tfe_image_repository_password
    container_runtime                  = var.container_runtime
    docker_version                     = var.docker_version

    # https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/configuration
    # Application settings
    tfe_hostname                  = var.tfe_fqdn
    tfe_operational_mode          = var.tfe_operational_mode
    tfe_capacity_concurrency      = var.tfe_capacity_concurrency
    tfe_capacity_cpu              = var.tfe_capacity_cpu
    tfe_capacity_memory           = var.tfe_capacity_memory
    tfe_license_reporting_opt_out = var.tfe_license_reporting_opt_out
    tfe_run_pipeline_driver       = "docker"
    tfe_run_pipeline_image        = var.tfe_run_pipeline_image == null ? "" : var.tfe_run_pipeline_image
    tfe_backup_restore_token      = ""
    tfe_node_id                   = ""
    tfe_http_port                 = var.tfe_http_port
    tfe_https_port                = var.tfe_https_port

    # Database settings
    tfe_database_host       = "${aws_rds_cluster.tfe.endpoint}:5432"
    tfe_database_name       = aws_rds_cluster.tfe.database_name
    tfe_database_user       = var.tfe_database_user
    tfe_database_password   = data.aws_secretsmanager_secret_version.tfe_database_password.secret_string
    tfe_database_parameters = var.tfe_database_parameters

    # Object storage settings
    tfe_object_storage_type                                 = "s3"
    tfe_object_storage_s3_bucket                            = aws_s3_bucket.tfe.id
    tfe_object_storage_s3_region                            = data.aws_region.current.name
    tfe_object_storage_s3_endpoint                          = "" # check if needed for GovCloud
    tfe_object_storage_s3_use_instance_profile              = var.tfe_object_storage_s3_use_instance_profile
    tfe_object_storage_s3_access_key_id                     = !var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_access_key_id : ""
    tfe_object_storage_s3_secret_access_key                 = !var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_secret_access_key : ""
    tfe_object_storage_s3_server_side_encryption            = var.s3_kms_key_arn == null ? "AES256" : "aws:kms"
    tfe_object_storage_s3_server_side_encryption_kms_key_id = var.s3_kms_key_arn == null ? "" : var.s3_kms_key_arn

    # Redis settings
    tfe_redis_host     = var.tfe_operational_mode == "active-active" ? aws_elasticache_replication_group.redis_cluster[0].primary_endpoint_address : ""
    tfe_redis_password = var.tfe_operational_mode == "active-active" && var.tfe_redis_password_secret_arn != null ? data.aws_secretsmanager_secret_version.tfe_redis_password[0].secret_string : ""
    tfe_redis_use_auth = var.tfe_operational_mode == "active-active" && var.tfe_redis_password_secret_arn != null ? true : false
    tfe_redis_use_tls  = var.tfe_operational_mode == "active-active" && var.redis_transit_encryption_enabled ? true : false

    # TLS settings
    tfe_tls_cert_file      = "/etc/ssl/private/terraform-enterprise/cert.pem"
    tfe_tls_key_file       = "/etc/ssl/private/terraform-enterprise/key.pem"
    tfe_tls_ca_bundle_file = "/etc/ssl/private/terraform-enterprise/bundle.pem"
    tfe_tls_enforce        = var.tfe_tls_enforce
    tfe_tls_ciphers        = "" # Leave blank to use the default ciphers
    tfe_tls_version        = "" # Leave blank to use both TLS v1.2 and TLS v1.3

    # Observability settings
    tfe_log_forwarding_enabled = var.tfe_log_forwarding_enabled
    tfe_metrics_enable         = var.tfe_metrics_enable
    tfe_metrics_http_port      = var.tfe_metrics_http_port
    tfe_metrics_https_port     = var.tfe_metrics_https_port
    fluent_bit_rendered_config = local.fluent_bit_rendered_config

    # Vault settings
    tfe_vault_use_external  = false
    tfe_vault_disable_mlock = var.tfe_vault_disable_mlock

    # Docker driver settings
    tfe_run_pipeline_docker_network = var.tfe_run_pipeline_docker_network == null ? "" : var.tfe_run_pipeline_docker_network
    tfe_hairpin_addressing          = var.tfe_hairpin_addressing
    #tfe_run_pipeline_docker_extra_hosts = "" // computed inside of tfe_user_data script if `tfe_hairpin_addressing` is `true` because EC2 private IP is used

    # Initial admin creation token settings
    tfe_iact_token           = var.tfe_iact_token == null ? "" : var.tfe_iact_token
    tfe_iact_subnets         = var.tfe_iact_subnets == null ? "" : var.tfe_iact_subnets
    tfe_iact_time_limit      = var.tfe_iact_time_limit
    tfe_iact_trusted_proxies = var.tfe_iact_trusted_proxies == null ? "" : var.tfe_iact_trusted_proxies

    # Network settings
    http_proxy  = var.http_proxy != null ? var.http_proxy : ""
    https_proxy = var.https_proxy != null ? var.https_proxy : ""
    no_proxy    = var.additional_no_proxy != null ? "${var.additional_no_proxy},${local.addl_no_proxy_base}" : local.addl_no_proxy_base
  }

  tfe_startup_script_tpl      = var.custom_tfe_startup_script_template != null ? "${path.cwd}/templates/${var.custom_tfe_startup_script_template}" : "${path.module}/templates/tfe_user_data.sh.tpl"
  user_data_template_rendered = templatefile(local.tfe_startup_script_tpl, local.user_data_args)
}

#------------------------------------------------------------------------------
# Launch template
#------------------------------------------------------------------------------
locals {
  // If an AMI ID is provided via `var.ec2_ami_id`, use it. Otherwise,
  // use the latest AMI for the specified OS distro via `var.ec2_os_distro`.
  ami_id_list = tolist([
    var.ec2_ami_id,
    join("", data.aws_ami.ubuntu.*.image_id),
    join("", data.aws_ami.rhel.*.image_id),
    join("", data.aws_ami.al2023.*.image_id),
  ])
}

// Query the specific AMI being used to retrieve root_device_name.
data "aws_ami" "selected" {
  filter {
    name   = "image-id"
    values = [coalesce(local.ami_id_list...)]
  }
}

resource "aws_launch_template" "tfe" {
  name                   = "${var.friendly_name_prefix}-tfe-ec2-launch-template"
  image_id               = data.aws_ami.selected.id
  instance_type          = var.ec2_instance_size
  key_name               = var.ec2_ssh_key_pair
  user_data              = base64gzip(local.user_data_template_rendered)
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.tfe_ec2.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_allow_ingress.id,
    aws_security_group.ec2_allow_egress.id
  ]

  block_device_mappings {
    device_name = data.aws_ami.selected.root_device_name

    ebs {
      volume_type = var.ebs_volume_type
      volume_size = var.ebs_volume_size
      throughput  = var.ebs_throughput
      iops        = var.ebs_iops
      encrypted   = var.ebs_is_encrypted
      kms_key_id  = var.ebs_is_encrypted && var.ebs_kms_key_arn != null ? var.ebs_kms_key_arn : null
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.friendly_name_prefix}-tfe-ec2" },
      { "Type" = "autoscaling-group" },
      { "OS_distro" = var.ec2_os_distro },
      var.common_tags
    )
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-ec2-launch-template" },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Autoscaling group
#------------------------------------------------------------------------------
resource "aws_autoscaling_group" "tfe" {
  name                      = "${var.friendly_name_prefix}-tfe-asg"
  min_size                  = 0
  max_size                  = var.tfe_operational_mode == "active-active" ? var.asg_max_size : 1
  desired_capacity          = var.asg_instance_count
  vpc_zone_identifier       = var.ec2_subnet_ids
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.tfe.id
    version = "$Latest"
  }

  target_group_arns = [var.lb_type == "alb" ? aws_lb_target_group.alb_443[0].arn : aws_lb_target_group.nlb_443[0].arn]

  tag {
    key                 = "Name"
    value               = "${var.friendly_name_prefix}-tfe-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "ec2_allow_ingress" {
  name   = "${var.friendly_name_prefix}-tfe-ec2-allow-ingress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-ec2-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_ingress_tfe_https_from_lb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_allow_ingress.id
  description              = "Allow TCP/443 (HTTPS) inbound to TFE EC2 instances from TFE load balancer."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_ssh" {
  count = var.cidr_allow_ingress_ec2_ssh != null ? 1 : 0

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_ec2_ssh
  description = "Allow TCP/22 (SSH) inbound to TFE EC2 instances from specified CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_vault" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  type        = "ingress"
  from_port   = 8201
  to_port     = 8201
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/8201 between TFE EC2 instances for internal Vault cluster communication with Active/Active operational mode."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_cidr_ingress_tfe_metrics_http" {
  count = var.tfe_metrics_enable && var.cidr_allow_ingress_tfe_metrics_http != null ? 1 : 0

  type        = "ingress"
  from_port   = var.tfe_metrics_http_port
  to_port     = var.tfe_metrics_http_port
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_metrics_http
  description = "Allow TCP/9090 (HTTP) or specified port inbound to metrics endpoint on TFE EC2 instances from specified CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_cidr_ingress_tfe_metrics_https" {
  count = var.tfe_metrics_enable && var.cidr_allow_ingress_tfe_metrics_https != null ? 1 : 0

  type        = "ingress"
  from_port   = var.tfe_metrics_https_port
  to_port     = var.tfe_metrics_https_port
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_metrics_https
  description = "Allow TCP/9091 (HTTPS) or specified port inbound to metrics endpoint on TFE EC2 instances from specified CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group" "ec2_allow_egress" {
  name   = "${var.friendly_name_prefix}-tfe-ec2-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-ec2-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_egress_all" {
  count = var.ec2_allow_all_egress ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_http" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_egress_ec2_http
  description = "Allow TCP/80 (HTTP) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_https" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_egress_ec2_http
  description = "Allow TCP/443 (HTTPS) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_allow_ingress.id
  description              = "Allow TCP/5432 (PostgreSQL) outbound to RDS Aurora cluster from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_redis" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis_allow_ingress[0].id
  description              = "Allow TCP/6379 (Redis) outbound to Redis cluster from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_vault" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  type        = "egress"
  from_port   = 8201
  to_port     = 8201
  protocol    = "tcp"
  self        = true
  description = "Allow TCP/8201 between TFE EC2 instances for internal Vault cluster communication in Active/Active operational mode."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_dns_tcp" {
  count = var.cidr_allow_egress_ec2_dns != null ? 1 : 0

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_egress_ec2_dns
  description = "Allow TCP/53 (DNS) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_dns_udp" {
  count = var.cidr_allow_egress_ec2_dns != null ? 1 : 0

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = var.cidr_allow_egress_ec2_dns
  description = "Allow UDP/53 (DNS) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

locals {
  http_proxy_port  = var.http_proxy != null ? replace(regexall(":[0-9]+$", var.http_proxy)[0], ":", "") : null
  https_proxy_port = var.https_proxy != null ? replace(regexall(":[0-9]+$", var.https_proxy)[0], ":", "") : null
}

resource "aws_security_group_rule" "ec2_allow_egress_proxy_http" {
  count = var.cidr_allow_egress_ec2_proxy != null && local.http_proxy_port != null ? 1 : 0

  type        = "egress"
  from_port   = local.http_proxy_port
  to_port     = local.http_proxy_port
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_egress_ec2_proxy
  description = "Allow TCP/${local.http_proxy_port} (HTTP proxy port) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}

resource "aws_security_group_rule" "ec2_allow_egress_proxy_https" {
  count = var.cidr_allow_egress_ec2_proxy != null && local.https_proxy_port != null ? 1 : 0

  type        = "egress"
  from_port   = local.https_proxy_port
  to_port     = local.https_proxy_port
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_egress_ec2_proxy
  description = "Allow TCP/${local.https_proxy_port} (HTTPS proxy port) outbound to specified CIDR ranges from TFE EC2 instances."

  security_group_id = aws_security_group.ec2_allow_egress.id
}
