# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
  }
}

provider "aws" {
  region = var.region
}

module "tfe" {
  source = "../.."

  # --- Common --- #
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- Bootstrap --- #
  tfe_license_secret_arn             = var.tfe_license_secret_arn
  tfe_encryption_password_secret_arn = var.tfe_encryption_password_secret_arn
  tfe_tls_cert_secret_arn            = var.tfe_tls_cert_secret_arn
  tfe_tls_privkey_secret_arn         = var.tfe_tls_privkey_secret_arn
  tfe_tls_ca_bundle_secret_arn       = var.tfe_tls_ca_bundle_secret_arn

  # --- TFE config settings --- #
  tfe_fqdn      = var.tfe_fqdn
  tfe_image_tag = var.tfe_image_tag

  # --- Networking --- #
  vpc_id                     = var.vpc_id
  lb_subnet_ids              = var.lb_subnet_ids
  lb_is_internal             = var.lb_is_internal
  ec2_subnet_ids             = var.ec2_subnet_ids
  rds_subnet_ids             = var.rds_subnet_ids
  redis_subnet_ids           = var.redis_subnet_ids
  cidr_allow_ingress_tfe_443 = var.cidr_allow_ingress_tfe_443
  cidr_allow_ingress_ec2_ssh = var.cidr_allow_ingress_ec2_ssh

  http_proxy = var.http_proxy
  https_proxy = var.https_proxy
  additional_no_proxy = var.additional_no_proxy

  # --- DNS (optional) --- #
  create_route53_tfe_dns_record      = var.create_route53_tfe_dns_record
  route53_tfe_hosted_zone_name       = var.route53_tfe_hosted_zone_name
  route53_tfe_hosted_zone_is_private = var.route53_tfe_hosted_zone_is_private

  # --- Compute --- #
  ec2_os_distro      = var.ec2_os_distro
  ec2_ssh_key_pair   = var.ec2_ssh_key_pair
  asg_instance_count = var.asg_instance_count

  # --- Database --- #
  tfe_database_password_secret_arn = var.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = var.rds_skip_final_snapshot

  # --- Redis --- #
  tfe_redis_password_secret_arn = var.tfe_redis_password_secret_arn

  # --- Log forwarding (optional) --- #
  tfe_log_forwarding_enabled = var.tfe_log_forwarding_enabled
  log_fwd_destination_type   = var.log_fwd_destination_type
  s3_log_fwd_bucket_name     = var.s3_log_fwd_bucket_name
}
