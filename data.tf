# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# AWS environment
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

#------------------------------------------------------------------------------
# EC2 AMI data sources
#------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  count = var.ec2_os_distro == "ubuntu" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["099720109477", "513442679011"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "rhel" {
  count = var.ec2_os_distro == "rhel" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["309956199498"]
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP3"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "al2023" {
  count = var.ec2_os_distro == "al2023" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#------------------------------------------------------------------------------
# Log forwarding destinations
#------------------------------------------------------------------------------
data "aws_s3_bucket" "log_fwd" {
  count = var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "s3" && var.s3_log_fwd_bucket_name != null ? 1 : 0

  bucket = var.s3_log_fwd_bucket_name
}

data "aws_cloudwatch_log_group" "log_fwd" {
  count = var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "cloudwatch" && var.cloudwatch_log_group_name != null ? 1 : 0

  name = var.cloudwatch_log_group_name
}

#------------------------------------------------------------------------------
# Elastic container registry (ECR)
#------------------------------------------------------------------------------
data "aws_ecr_repository" "tfe_run_pipeline_image" {
  count = var.tfe_run_pipeline_image_ecr_repo_name != null ? 1 : 0

  name = var.tfe_run_pipeline_image_ecr_repo_name
}