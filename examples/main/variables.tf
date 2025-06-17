# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region where TFE will be deployed."
}

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming all AWS resources for this deployment. Most commonly set to either an environment (e.g. 'sandbox', 'prod'), a team name, or a project name."

  validation {
    condition     = !strcontains(lower(var.friendly_name_prefix), "tfe")
    error_message = "Value must not contain the substring 'tfe' to avoid redundancy in resource naming."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for all taggable AWS resources."
  default     = {}
}

variable "is_secondary_region" {
  type        = bool
  description = "Boolean indicating whether this TFE deployment is in the primary or secondary (replica) region."
  default     = false
}

#------------------------------------------------------------------------------
# Bootstrap
#------------------------------------------------------------------------------
variable "tfe_license_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE license file. Secret type should be plaintext."
}

variable "tfe_tls_cert_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE TLS certificate in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext."
}

variable "tfe_tls_privkey_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE TLS private key in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext."
}

variable "tfe_tls_ca_bundle_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext."
}

variable "tfe_encryption_password_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE encryption password. Secret type should be plaintext."
}

variable "tfe_image_repository_url" {
  type        = string
  description = "Container registry hostname for the TFE application container image. Override this only if you are hosting the image in a custom registry. If you are using Amazon ECR, specify only the registry URI (e.g., '<account-id>.dkr.ecr.<region>.amazonaws.com'), not the full image path."
  default     = "images.releases.hashicorp.com"
}

variable "tfe_image_name" {
  type        = string
  description = "Name of the TFE application container image. Override this only if you are hosting the image in a custom registry. If you are using Amazon ECR, specify only the repository name here (e.g., 'tfe-app'), not the full image path."
  default     = "hashicorp/terraform-enterprise"

  validation {
    condition     = var.tfe_image_repository_url == "images.releases.hashicorp.com" ? var.tfe_image_name == "hashicorp/terraform-enterprise" : true
    error_message = "`tfe_image_name` must be 'hashicorp/terraform-enterprise' when `tfe_image_repository_url` is set to 'images.releases.hashicorp.com'."
  }
}

variable "tfe_image_tag" {
  type        = string
  description = "Tag for the TFE application container image, representing the specific version of Terraform Enterprise to install."
  default     = "v202505-1"
}

variable "tfe_image_repository_username" {
  type        = string
  description = "Username for authenticating to the container registry that hosts the TFE application container image. Override this only if you are hosting the image in a custom registry. If you are using Amazon ECR, specify 'AWS'."
  default     = "terraform"

  validation {
    condition     = var.tfe_image_repository_url == "images.releases.hashicorp.com" ? var.tfe_image_repository_username == "terraform" : true
    error_message = "`tfe_image_repository_username` must be 'terraform' when `tfe_image_repository_url` is set to 'images.releases.hashicorp.com'."
  }

  validation {
    condition     = can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com$", var.tfe_image_repository_url)) ? var.tfe_image_repository_username == "AWS" : true
    error_message = "`tfe_image_repository_username` must be 'AWS' when using Amazon ECR for `tfe_image_repository_url`."
  }
}

variable "tfe_image_repository_password" {
  type        = string
  description = "Password for authenticating to the container registry that hosts the TFE application container image. Leave as `null` if using the default TFE registry, as the TFE license will be used as the password. If you are using Amazon ECR, this should be a valid ECR token or leave as `null` to use the instance profile."
  default     = null

  validation {
    condition     = var.tfe_image_repository_url == "images.releases.hashicorp.com" ? var.tfe_image_repository_password == null : true
    error_message = "`tfe_image_repository_password` must be 'null' when `tfe_image_repository_url` is set to default TFE registry ('images.releases.hashicorp.com')."
  }

  validation {
    condition     = var.tfe_image_repository_url == "images.releases.hashicorp.com" || can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com$", var.tfe_image_repository_url)) || var.tfe_image_repository_password != null
    error_message = "`tfe_image_repository_password` must be specified when using a custom container registry that is not the default TFE registry ('images.releases.hashicorp.com') or Amazon ECR."
  }
}

#------------------------------------------------------------------------------
# TFE configuration settings
#------------------------------------------------------------------------------
variable "tfe_fqdn" {
  type        = string
  description = "Fully qualified domain name (FQDN) of TFE instance. This name should resolve to the DNS name or IP address of the TFE load balancer and will be what clients use to access TFE."
}

variable "tfe_capacity_concurrency" {
  type        = number
  description = "Maximum number of concurrent Terraform runs to allow on a TFE node."
  default     = 10
}

variable "tfe_capacity_cpu" {
  type        = number
  description = "Maximum number of CPU cores that a Terraform run is allowed to consume in TFE. Set to `0` for no limit."
  default     = 0
}

variable "tfe_capacity_memory" {
  type        = number
  description = "Maximum amount of memory (in MiB) that a Terraform run is allowed to consume in TFE."
  default     = 2048
}

variable "tfe_license_reporting_opt_out" {
  type        = bool
  description = "Boolean to opt out of reporting TFE licensing information to HashiCorp."
  default     = false
}

variable "tfe_usage_reporting_opt_out" {
  type        = bool
  description = "Boolean to opt out of reporting TFE usage information to HashiCorp."
  default     = false
}

variable "tfe_operational_mode" {
  type        = string
  description = "[Operational mode](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/operation-modes) for TFE. Valid values are `active-active` or `external`."
  default     = "active-active"

  validation {
    condition     = var.tfe_operational_mode == "active-active" || var.tfe_operational_mode == "external"
    error_message = "Value must be `active-active` or `external`."
  }
}

variable "tfe_run_pipeline_image" {
  type        = string
  description = "Fully qualified container image reference for the Terraform default agent container (e.g., 'internal-registry.example.com/tfe-agent:latest'). This is refered to as the [TFE_RUN_PIPELINE_IMAGE](https://developer.hashicorp.com/terraform/enterprise/deploy/reference/configuration#tfe_run_pipeline_image) and is the image that is used to execute Terraform runs when execution mode is set to remote. The container registry hosting this image must allow anonymous (unauthenticated) pulls."
  default     = null
}

variable "tfe_http_port" {
  type        = number
  description = "Port the TFE application container listens on for HTTP traffic. This is not the host port."
  default     = 8080

  validation {
    condition     = var.container_runtime == "podman" ? var.tfe_http_port != 80 : true
    error_message = "Value must not be `80` when `container_runtime` is `podman` to avoid conflicts."
  }
}

variable "tfe_https_port" {
  type        = number
  description = "Port the TFE application container listens on for HTTPS traffic. This is not the host port."
  default     = 8443

  validation {
    condition     = var.container_runtime == "podman" ? var.tfe_https_port != 443 : true
    error_message = "Value must not be `443` when `container_runtime` is `podman` to avoid conflicts."
  }
}

variable "tfe_metrics_enable" {
  type        = bool
  description = "Boolean to enable TFE metrics endpoints."
  default     = false
}

variable "tfe_metrics_http_port" {
  type        = number
  description = "HTTP port for TFE metrics scrape."
  default     = 9090
}

variable "tfe_metrics_https_port" {
  type        = number
  description = "HTTPS port for TFE metrics scrape."
  default     = 9091
}

variable "tfe_tls_enforce" {
  type        = bool
  description = "Boolean to enforce TLS."
  default     = false
}

variable "tfe_vault_disable_mlock" {
  type        = bool
  description = "Boolean to disable mlock for internal Vault."
  default     = false
}

variable "tfe_hairpin_addressing" {
  type        = bool
  description = "Boolean to enable hairpin addressing for layer 4 load balancer with loopback prevention. Must be `true` when `lb_type` is `nlb` and `lb_is_internal` is `true`."
  default     = true

  validation {
    condition     = var.lb_is_internal && var.lb_type == "nlb" ? var.tfe_hairpin_addressing == true : true
    error_message = "Value must be `true` when `lb_type` is `nlb` and `lb_is_internal` is `true`."
  }
}

variable "tfe_run_pipeline_docker_network" {
  type        = string
  description = "Docker network where the containers that execute Terraform runs will be created. The network must already exist, it will not be created automatically. Leave as `null` to use the default network created by TFE."
  default     = null
}

variable "tfe_iact_token" {
  type        = string
  description = "A pre-populated TFE initial admin creation token (IACT). Leave as `null` for the system to generate a random one."
  default     = null
}

variable "tfe_iact_subnets" {
  type        = string
  description = "Comma-separated list of subnets in CIDR notation (e.g., `10.0.0.0/8,192.168.0.0/24`) that are allowed to retrieve the TFE initial admin creation token (IACT) via the API or web browser. Leave as `null` to disable IACT retrieval via the API from external clients."
  default     = null
}

variable "tfe_iact_time_limit" {
  type        = number
  description = "Number of minutes that the TFE initial admin creation token (IACT) can be retrieved via the API after the application starts."
  default     = 60
}

variable "tfe_iact_trusted_proxies" {
  type        = string
  description = "Comma-separated list of proxy IP addresses that are allowed to retrieve the TFE initial admin creation token (IACT) via the API or web browser. Leave as `null` to disable IACT retrieval via the API from external clients through a proxy."
  default     = null
}

variable "tfe_ipv6_enabled" {
  type        = bool
  description = "Boolean to enable TFE to listen on IPv6 and IPv4 addresses. When `false`, TFE listens on IPv4 addresses only."
  default     = false
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "ID of VPC where TFE will be deployed."
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the load balancer. If `lb_is_internal` is `false`, then these should be public subnets. Otherwise, these should be private subnets."
}

variable "ec2_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the EC2 instance. Private subnets is the best practice here."
}

variable "rds_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for RDS database subnet group. Private subnets is the best practice here."
}

variable "redis_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for Redis cluster subnet group. Private subnets is the best practice here."
  default     = []

  validation {
    condition     = var.tfe_operational_mode == "active-active" ? length(var.redis_subnet_ids) > 0 : true
    error_message = "Value must be set when `tfe_operational_mode` is `active-active`."
  }
}

variable "lb_type" {
  type        = string
  description = "Indicates which type of AWS load balancer is created: Application Load Balancer (`alb`) or Network Load Balancer (`nlb`)."
  default     = "nlb"

  validation {
    condition     = var.lb_type == "alb" || var.lb_type == "nlb"
    error_message = "Supported values are `alb` or `nlb`."
  }
}

variable "lb_is_internal" {
  type        = bool
  description = "Boolean to create an internal (private) load balancer. The `lb_subnet_ids` must be private subnets when this is `true`."
  default     = true
}

variable "lb_stickiness_enabled" {
  type        = bool
  description = "Boolean to enable sticky sessions for the load balancer. When `lb_type` is `nlb`, sticky sessions enabled by client IP Address."
  default     = true
}

variable "tfe_alb_tls_certificate_arn" {
  type        = string
  description = "ARN of existing TFE TLS certificate imported in ACM to be used for application load balancer (ALB) HTTPS listeners. Required when `lb_type` is `alb`."
  default     = null

  validation {
    condition     = var.lb_type == "alb" ? var.tfe_alb_tls_certificate_arn != null : true
    error_message = "Value must be set when `lb_type` is `alb`."
  }

  validation {
    condition     = var.lb_type == "nlb" ? var.tfe_alb_tls_certificate_arn == null : true
    error_message = "Value must be `null` when `lb_type` is `nlb`."
  }
}

variable "cidr_allow_ingress_tfe_443" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 443 to TFE server or load balancer."
  default     = ["0.0.0.0/0"]
}

variable "cidr_allow_ingress_ec2_ssh" {
  type        = list(string)
  description = "List of CIDR ranges to allow SSH ingress to TFE EC2 instance (i.e. bastion IP, client/workstation IP, etc.)."
  default     = null
}

variable "cidr_allow_ingress_tfe_metrics_http" {
  type        = list(string)
  description = "List of CIDR ranges to allow TCP/9090 (HTTP) inbound to metrics endpoint on TFE EC2 instances."
  default     = null
}

variable "cidr_allow_ingress_tfe_metrics_https" {
  type        = list(string)
  description = "List of CIDR ranges to allow TCP/9091 (HTTPS) inbound to metrics endpoint on TFE EC2 instances."
  default     = null
}

variable "cidr_allow_egress_ec2_http" {
  type        = list(string)
  description = "List of destination CIDR ranges to allow TCP/80 outbound from TFE EC2 instances."
  default     = ["0.0.0.0/0"]
}

variable "cidr_allow_egress_ec2_https" {
  type        = list(string)
  description = "List of destination CIDR ranges to allow TCP/443 outbound from TFE EC2 instances. Include the CIDR range of your VCS provider if you are configuring VCS integration with TFE."
  default     = ["0.0.0.0/0"]
}

variable "cidr_allow_egress_ec2_dns" {
  type        = list(string)
  description = "List of destination CIDR ranges to allow TCP/53 and UDP/53 (DNS) outbound from TFE EC2 instances. Only set if you want to use custom DNS servers instead of the AWS-provided DNS resolver within your VPC."
  default     = null
}

variable "cidr_allow_egress_ec2_proxy" {
  type        = list(string)
  description = "List of destination CIDR range(s) where proxy server exists. Required and only valid when `http_proxy` and/or `https_proxy` are set."
  default     = null

  validation {
    condition     = var.http_proxy != null || var.https_proxy != null ? var.cidr_allow_egress_ec2_proxy != null : true # add AND statement for checking length of list
    error_message = "`cidr_allow_egress_ec2_proxy` must be set when `http_proxy` and/or `https_proxy` are set."
  }

  validation {
    condition     = var.http_proxy == null && var.https_proxy == null ? var.cidr_allow_egress_ec2_proxy == null : true
    error_message = "`cidr_allow_egress_ec2_proxy` must be null when `http_proxy` and `https_proxy` are not set."
  }
}

variable "ec2_allow_all_egress" {
  type        = bool
  description = "Boolean to allow all egress traffic from TFE EC2 instances."
  default     = false
}

variable "http_proxy" {
  type        = string
  description = "Proxy address (including port number) for TFE to use for outbound HTTP requests (e.g. `http://proxy.example.com:3128`)."
  default     = null

  validation {
    condition     = var.http_proxy != null ? can(regex("^http://[a-zA-Z0-9.-]+:[0-9]{1,5}$", var.http_proxy)) : true
    error_message = "`http_proxy` value must start with `http://` and be in the format `http://proxy.example.com:3128`, including a colon and port number at the end."
  }
}

variable "https_proxy" {
  type        = string
  description = "Proxy address (including port number) for TFE to use for outbound HTTPS requests (e.g. `http://proxy.example.com:3128`)."
  default     = null

  validation {
    condition     = var.https_proxy != null ? can(regex("^(http|https)://[a-zA-Z0-9.-]+:[0-9]{1,5}$", var.https_proxy)) : true
    error_message = "`https_proxy` value must start with `http://` or `https://` and be in the format `http://proxy.example.com:3128` or `https://proxy.example.com:3128`, including a colon and port number at the end."
  }
}

variable "additional_no_proxy" {
  type        = string
  description = "Comma-separated list of domains, IP addresses, or CIDR ranges that TFE should bypass the proxy when making outbound requests, provided `http_proxy` or `https_proxy` are set. This list is in addition to automatically included addresses like RDS, S3, and Redis, which are dynamically added to `no_proxy` by the user_data script. Do not set if `http_proxy` and/or `https_proxy` are not configured."
  default     = null

  validation {
    condition     = var.http_proxy == null && var.https_proxy == null ? var.additional_no_proxy == null : true
    error_message = "Value must not be set when `http_proxy` and `https_proxy` are not configured."
  }

  validation {
    condition     = var.additional_no_proxy == null || can(regex("^[^,\\s]+(,[^,\\s]+)*$", var.additional_no_proxy))
    error_message = "Value must be single string containing a comma-separated list, with no empty entries or leading/trailing spaces."
  }
}

#------------------------------------------------------------------------------
# DNS
#------------------------------------------------------------------------------
variable "create_route53_tfe_dns_record" {
  type        = bool
  description = "Boolean to create Route53 Alias Record for `tfe_hostname` resolving to Load Balancer DNS name. If `true`, `route53_tfe_hosted_zone_name` is also required."
  default     = false
}

variable "route53_tfe_hosted_zone_name" {
  type        = string
  description = "Route53 Hosted Zone name to create `tfe_hostname` Alias record in. Required if `create_route53_tfe_dns_record` is `true`."
  default     = null

  validation {
    condition     = var.create_route53_tfe_dns_record ? var.route53_tfe_hosted_zone_name != null : true
    error_message = "Value must be set when `create_route53_tfe_dns_record` is `true`."
  }
}

variable "route53_tfe_hosted_zone_is_private" {
  type        = bool
  description = "Boolean indicating if `route53_tfe_hosted_zone_name` is a private hosted zone."
  default     = false
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
variable "container_runtime" {
  type        = string
  description = "Container runtime to use for TFE. Supported values are `docker` or `podman`."
  default     = "docker"

  validation {
    condition     = var.container_runtime == "docker" || var.container_runtime == "podman"
    error_message = "Valid values are `docker` or `podman`."
  }
}

variable "ec2_os_distro" {
  type        = string
  description = "Linux OS distribution type for TFE EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`."
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel", "al2023", "centos"], var.ec2_os_distro)
    error_message = "Valid values are `ubuntu`, `rhel`, `al2023`, or `centos`."
  }

  validation {
    condition     = var.ec2_os_distro == "al2023" ? var.container_runtime != "podman" : true
    error_message = "Value cannot be `podman` when `ec2_os_distro` is `al2023`. Currently, only `docker` is supported for `al2023`."
  }
}

variable "docker_version" {
  type        = string
  description = "Version of Docker to install on TFE EC2 instances. Not applicable to Amazon Linux 2023 distribution (when `ec2_os_distro` is `al2023`)."
  default     = "28.0.1"
}

variable "asg_instance_count" {
  type        = number
  description = "Desired number of TFE EC2 instances to run in autoscaling group. Must be `1` when `tfe_operational_mode` is `external`."
  default     = 1

  validation {
    condition     = var.tfe_operational_mode == "external" ? var.asg_instance_count == 1 : true
    error_message = "Value must be `1` when `tfe_operational_mode` is `external`."
  }
}

variable "asg_max_size" {
  type        = number
  description = "Max number of TFE EC2 instances to run in autoscaling group. Only valid when `tfe_operational_mode` is `active-active`. Value is hard-coded to `1` when `tfe_operational_mode` is `external`."
  default     = 3
}

variable "asg_health_check_grace_period" {
  type        = number
  description = "The amount of time to wait for a new TFE EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one."
  default     = 900
}

variable "ec2_ami_id" {
  type        = string
  description = "Custom AMI ID for TFE EC2 launch template. If specified, value of `ec2_os_distro` must coincide with this custom AMI OS distro."
  default     = null

  validation {
    condition     = try((length(var.ec2_ami_id) > 4 && substr(var.ec2_ami_id, 0, 4) == "ami-"), var.ec2_ami_id == null)
    error_message = "Value must start with \"ami-\"."
  }

  validation {
    condition     = var.ec2_os_distro == "centos" ? var.ec2_ami_id != null : true
    error_message = "Value must be set to a CentOS AMI ID when `ec2_os_distro` is `centos`."
  }
}

variable "ec2_instance_size" {
  type        = string
  description = "EC2 instance type for TFE EC2 launch template."
  default     = "m7i.xlarge"
}

variable "ec2_ssh_key_pair" {
  type        = string
  description = "Name of existing SSH key pair to attach to TFE EC2 instance."
  default     = null
}

variable "ec2_allow_ssm" {
  type        = bool
  description = "Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the TFE instance role, allowing the SSM agent (if present) to function."
  default     = false
}

variable "ebs_is_encrypted" {
  type        = bool
  description = "Boolean to encrypt the EBS root block device of the TFE EC2 instance(s). An AWS managed key will be used when `true` unless a value is also specified for `ebs_kms_key_arn`."
  default     = true
}

variable "ebs_kms_key_arn" {
  type        = string
  description = "ARN of KMS customer managed key (CMK) to encrypt TFE EC2 EBS volumes."
  default     = null

  validation {
    condition     = var.ebs_kms_key_arn != null ? var.ebs_is_encrypted == true : true
    error_message = "`ebs_is_encrypted` must be `true` when specifying a KMS key ARN for EBS volume."
  }
}

variable "ebs_volume_type" {
  type        = string
  description = "EBS volume type for TFE EC2 instances."
  default     = "gp3"

  validation {
    condition     = var.ebs_volume_type == "gp3" || var.ebs_volume_type == "gp2"
    error_message = "Supported values are `gp3` and `gp2`."
  }
}

variable "ebs_volume_size" {
  type        = number
  description = "Size (GB) of the root EBS volume for TFE EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`."
  default     = 50

  validation {
    condition     = var.ebs_volume_size >= 50 && var.ebs_volume_size <= 16000
    error_message = "Value must be greater than or equal to `50` and less than or equal to `16000`."
  }
}

variable "ebs_throughput" {
  type        = number
  description = "Throughput (MB/s) to configure when EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`."
  default     = 250

  validation {
    condition     = var.ebs_throughput >= 125 && var.ebs_throughput <= 1000
    error_message = "Value must be greater than or equal to `125` and less than or equal to `1000`."
  }
}

variable "ebs_iops" {
  type        = number
  description = "Amount of IOPS to configure when EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`."
  default     = 3000

  validation {
    condition     = var.ebs_iops >= 3000 && var.ebs_iops <= 16000
    error_message = "Value must be greater than or equal to `3000` and less than or equal to `16000`."
  }
}

variable "custom_tfe_startup_script_template" {
  type        = string
  description = "Filename of a custom TFE startup script template to use in place of of the built-in user_data script. The file must exist within a directory named './templates' in your current working directory."
  default     = null

  validation {
    condition     = var.custom_tfe_startup_script_template != null ? fileexists("${path.cwd}/templates/${var.custom_tfe_startup_script_template}") : true
    error_message = "File not found. Ensure the file exists within a directory named './templates' relative to your current working directory."
  }
}

#------------------------------------------------------------------------------
# RDS Aurora PostgreSQL
#------------------------------------------------------------------------------
variable "tfe_database_password_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for the TFE database password used to create RDS Aurora (PostgreSQL) database cluster. Secret type should be plaintext. Value of secret must be from 8 to 128 alphanumeric characters or symbols (excluding `@`, `\"`, and `/`)."
}

variable "tfe_database_name" {
  type        = string
  description = "Name of TFE database to create within RDS global cluster."
  default     = "tfe"
}

variable "rds_availability_zones" {
  type        = list(string)
  description = "List of AWS availability zones to spread Aurora database cluster instances across. Leave as `null` and RDS will automatically assign 3 availability zones."
  default     = null

  validation {
    condition     = try(length(var.rds_availability_zones) <= 3, var.rds_availability_zones == null)
    error_message = "A maximum of three availability zones can be specified."
  }
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Boolean to enable deletion protection for RDS Aurora global cluster."
  default     = false
}

variable "rds_aurora_engine_version" {
  type        = number
  description = "Engine version of RDS Aurora PostgreSQL."
  default     = 16.2
}

variable "rds_force_destroy" {
  type        = bool
  description = "Boolean to enable the removal of RDS database cluster members from RDS global cluster on destroy."
  default     = false
}

variable "rds_storage_encrypted" {
  type        = bool
  description = "Boolean to encrypt RDS storage. An AWS managed key will be used when `true` unless a value is also specified for `rds_kms_key_arn`."
  default     = true
}

variable "rds_global_cluster_id" {
  type        = string
  description = "ID of RDS global cluster. Only required only when `is_secondary_region` is `true`, otherwise leave as `null`."
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.rds_global_cluster_id != null : true
    error_message = "Value must be set when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.rds_global_cluster_id == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

variable "rds_aurora_engine_mode" {
  type        = string
  description = "RDS Aurora database engine mode."
  default     = "provisioned"
}

variable "tfe_database_user" {
  type        = string
  description = "Username for TFE RDS database cluster."
  default     = "tfe"
}

variable "tfe_database_parameters" {
  type        = string
  description = "PostgreSQL server parameters for the connection URI. Used to configure the PostgreSQL connection."
  default     = "sslmode=require"
}

variable "rds_kms_key_arn" {
  type        = string
  description = "ARN of KMS customer managed key (CMK) to encrypt TFE RDS cluster."
  default     = null

  validation {
    condition     = var.rds_kms_key_arn != null ? var.rds_storage_encrypted == true : true
    error_message = "`rds_storage_encrypted` must be `true` when specifying a `rds_kms_key_arn`."
  }
}

variable "rds_replication_source_identifier" {
  type        = string
  description = "ARN of source RDS cluster or cluster instance if this database cluster is to be created as a read replica. Only required when `is_secondary_region` is `true`, otherwise leave as `null`."
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.rds_replication_source_identifier != null : true
    error_message = "Value must be set when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.rds_replication_source_identifier == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

variable "rds_source_region" {
  type        = string
  description = "Source region for RDS cross-region replication. Only required when `is_secondary_region` is `true`, otherwise leave as `null`."
  default     = null

  validation {
    condition     = var.is_secondary_region ? var.rds_source_region != null : true
    error_message = "Value must be set when `is_secondary_region` is `true`."
  }

  validation {
    condition     = !var.is_secondary_region ? var.rds_source_region == null : true
    error_message = "Value must be `null` when `is_secondary_region` is `false`."
  }
}

variable "rds_backup_retention_period" {
  type        = number
  description = "The number of days to retain backups for. Must be between 0 and 35. Must be greater than 0 if the database cluster is used as a source of a read replica cluster."
  default     = 35

  validation {
    condition     = var.rds_backup_retention_period >= 0 && var.rds_backup_retention_period <= 35
    error_message = "Value must be between 0 and 35."
  }
}

variable "rds_preferred_backup_window" {
  type        = string
  description = "Daily time range (UTC) for RDS backup to occur. Must not overlap with `rds_preferred_maintenance_window`."
  default     = "04:00-04:30"

  validation {
    condition     = can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]-([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.rds_preferred_backup_window))
    error_message = "Value must be in the format 'HH:MM-HH:MM'."
  }
}

variable "rds_preferred_maintenance_window" {
  type        = string
  description = "Window (UTC) to perform RDS database maintenance. Must not overlap with `rds_preferred_backup_window`."
  default     = "Sun:08:00-Sun:09:00"

  validation {
    condition     = can(regex("^(Mon|Tue|Wed|Thu|Fri|Sat|Sun):([01]?[0-9]|2[0-3]):[0-5][0-9]-(Mon|Tue|Wed|Thu|Fri|Sat|Sun):([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.rds_preferred_maintenance_window))
    error_message = "Value must be in the format 'Day:HH:MM-Day:HH:MM'."
  }
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Boolean to enable RDS to take a final database snapshot before destroying."
  default     = false
}

variable "rds_aurora_instance_class" {
  type        = string
  description = "Instance class of Aurora PostgreSQL database."
  default     = "db.r6i.xlarge"
}

variable "rds_apply_immediately" {
  type        = bool
  description = "Boolean to apply changes immediately to RDS cluster instance."
  default     = true
}

variable "rds_parameter_group_family" {
  type        = string
  description = "Family of RDS Aurora PostgreSQL database parameter group."
  default     = "aurora-postgresql16"
}

variable "rds_aurora_replica_count" {
  type        = number
  description = "Number of replica (reader) cluster instances to create within the RDS Aurora database cluster (within the same region)."
  default     = 1
}

variable "rds_performance_insights_enabled" {
  type        = bool
  description = "Boolean to enable performance insights for RDS cluster instance(s)."
  default     = true
}

variable "rds_performance_insights_retention_period" {
  type        = number
  description = "Number of days to retain RDS performance insights data. Must be between 7 and 731."
  default     = 7
}

#------------------------------------------------------------------------------
# S3
#------------------------------------------------------------------------------
variable "tfe_object_storage_s3_use_instance_profile" {
  type        = bool
  description = "Boolean to use TFE instance profile for S3 bucket access. If `false`, `tfe_object_storage_s3_access_key_id` and `tfe_object_storage_s3_secret_access_key` are required."
  default     = true
}

variable "tfe_object_storage_s3_access_key_id" {
  type        = string
  description = "Access key ID for S3 bucket. Required when `tfe_object_storage_s3_use_instance_profile` is `false`."
  default     = null

  validation {
    condition     = !var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_access_key_id != null : true
    error_message = "Value must be set when `tfe_object_storage_s3_use_instance_profile` is `false`."
  }

  validation {
    condition     = var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_access_key_id == null : true
    error_message = "Value must be `null` when `tfe_object_storage_s3_use_instance_profile` is `true`."
  }
}

variable "tfe_object_storage_s3_secret_access_key" {
  type        = string
  description = "Secret access key for S3 bucket. Required when `tfe_object_storage_s3_use_instance_profile` is `false`."
  default     = null

  validation {
    condition     = !var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_secret_access_key != null : true
    error_message = "Value must be set when `tfe_object_storage_s3_use_instance_profile` is `false`."
  }

  validation {
    condition     = var.tfe_object_storage_s3_use_instance_profile ? var.tfe_object_storage_s3_secret_access_key == null : true
    error_message = "Value must be `null` when `tfe_object_storage_s3_use_instance_profile` is `true`."
  }
}

variable "s3_kms_key_arn" {
  type        = string
  description = "ARN of KMS customer managed key (CMK) to encrypt TFE S3 bucket with."
  default     = null
}

variable "s3_enable_bucket_replication" {
  type        = bool
  description = "Boolean to enable cross-region replication for TFE S3 bucket. Do not enable when `is_secondary_region` is `true`. An `s3_destination_bucket_arn` is also required when `true`."
  default     = false

  validation {
    condition     = var.is_secondary_region ? var.s3_enable_bucket_replication == false : true
    error_message = "Cross-region replication should not be enabled when `is_secondary_region` is `true`."
  }

  validation {
    condition     = var.s3_enable_bucket_replication ? var.s3_destination_bucket_arn != "" : true
    error_message = "When `true`, an `s3_destination_bucket_arn` is also required."
  }
}

variable "s3_destination_bucket_arn" {
  type        = string
  description = "ARN of destination S3 bucket for cross-region replication configuration. Bucket should already exist in secondary region. Required when `s3_enable_bucket_replication` is `true`."
  default     = ""
}

variable "s3_destination_bucket_kms_key_arn" {
  type        = string
  description = "ARN of KMS key of destination S3 bucket for cross-region replication configuration if it is encrypted with a customer managed key (CMK)."
  default     = null
}

#------------------------------------------------------------------------------
# Redis
#------------------------------------------------------------------------------
variable "tfe_redis_password_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for the TFE Redis password used to create Redis (Elasticache Replication Group) cluster. Secret type should be plaintext. Value of secret must be from 16 to 128 alphanumeric characters or symbols (excluding `@`, `\"`, and `/`)."
  default     = null
}

variable "redis_engine_version" {
  type        = string
  description = "Redis version number."
  default     = "7.1"
}

variable "redis_port" {
  type        = number
  description = "Port number the Redis nodes will accept connections on."
  default     = 6379
}

variable "redis_parameter_group_name" {
  type        = string
  description = "Name of parameter group to associate with Redis cluster."
  default     = "default.redis7"
}

variable "redis_node_type" {
  type        = string
  description = "Type (size) of Redis node from a compute, memory, and network throughput standpoint."
  default     = "cache.m5.large"
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Boolean to create Redis nodes across multiple availability zones. If `true`, `redis_automatic_failover_enabled` must also be `true`, and more than one subnet must be specified within `redis_subnet_ids`."
  default     = true

  validation {
    condition     = var.redis_multi_az_enabled ? var.redis_automatic_failover_enabled == true && length(var.redis_subnet_ids) > 1 : true
    error_message = "If `true`, `redis_automatic_failover_enabled` must also be `true`, and more than one subnet must be specified within `redis_subnet_ids`."
  }
}

variable "redis_automatic_failover_enabled" {
  type        = bool
  description = "Boolean for deploying Redis nodes in multiple availability zones and enabling automatic failover."
  default     = true

  validation {
    condition     = var.redis_automatic_failover_enabled ? length(var.redis_subnet_ids) > 1 : true
    error_message = "If `true`, you must specify more than one subnet within `redis_subnet_ids`."
  }
}

variable "redis_at_rest_encryption_enabled" {
  type        = bool
  description = "Boolean to enable encryption at rest on Redis cluster. An AWS managed key will be used when `true` unless a value is also specified for `redis_kms_key_arn`."
  default     = true
}

variable "redis_kms_key_arn" {
  type        = string
  description = "ARN of KMS customer managed key (CMK) to encrypt Redis cluster with."
  default     = null

  validation {
    condition     = var.redis_kms_key_arn != null ? var.redis_at_rest_encryption_enabled == true : true
    error_message = "`redis_at_rest_encryption_enabled` must be set to `true` when specifying a KMS key ARN for Redis."
  }
}

variable "redis_transit_encryption_enabled" {
  type        = bool
  description = "Boolean to enable TLS encryption between TFE and the Redis cluster."
  default     = true
}

variable "redis_apply_immediately" {
  type        = bool
  description = "Boolean to apply changes immediately to Redis cluster."
  default     = true
}

variable "redis_auto_minor_version_upgrade" {
  type        = bool
  description = "Boolean to enable automatic minor version upgrades for Redis cluster."
  default     = true
}

#------------------------------------------------------------------------------
# Log forwarding
#------------------------------------------------------------------------------
variable "tfe_log_forwarding_enabled" {
  type        = bool
  description = "Boolean to enable TFE log forwarding feature."
  default     = false
}

variable "log_fwd_destination_type" {
  type        = string
  description = "Type of log forwarding destination for Fluent Bit. Supported values are `s3`, `cloudwatch`, or `custom`."
  default     = "cloudwatch"

  validation {
    condition     = contains(["s3", "cloudwatch", "custom"], var.log_fwd_destination_type)
    error_message = "Supported values are `s3`, `cloudwatch` or `custom`."
  }
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "Name of CloudWatch Log Group to configure as log forwarding destination. Only valid when `tfe_log_forwarding_enabled` is `true`."
  default     = null

  validation {
    condition     = var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "cloudwatch" ? var.cloudwatch_log_group_name != null : true
    error_message = "Value must be set when `tfe_log_forwarding_enabled` is `true` and `log_fwd_destination_type` is `cloudwatch`."
  }

  validation {
    condition     = var.log_fwd_destination_type != "cloudwatch" ? var.cloudwatch_log_group_name == null : true
    error_message = "Value must be `null` when `log_fwd_destination_type` is not `cloudwatch`."
  }
}

variable "s3_log_fwd_bucket_name" {
  type        = string
  description = "Name of S3 bucket to configure as log forwarding destination. Only valid when `tfe_log_forwarding_enabled` is `true`."
  default     = null

  validation {
    condition     = var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "s3" ? var.s3_log_fwd_bucket_name != null : true
    error_message = "Value must be set when `tfe_log_forwarding_enabled` is `true` and `log_fwd_destination_type` is `s3`."
  }

  validation {
    condition     = var.log_fwd_destination_type != "s3" ? var.s3_log_fwd_bucket_name == null : true
    error_message = "Value must be `null` when `log_fwd_destination_type` is not `s3`."
  }
}

variable "custom_fluent_bit_config" {
  type        = string
  description = "Custom Fluent Bit configuration for log forwarding. Only valid when `tfe_log_forwarding_enabled` is `true` and `log_fwd_destination_type` is `custom`."
  default     = null

  validation {
    condition     = var.tfe_log_forwarding_enabled && var.log_fwd_destination_type == "custom" ? var.custom_fluent_bit_config != null : true
    error_message = "Value must be set when `tfe_log_forwarding_enabled` is `true` and `log_fwd_destination_type` is `custom`."
  }
}

#------------------------------------------------------------------------------
# Cost estimation IAM
#------------------------------------------------------------------------------
variable "tfe_cost_estimation_iam_enabled" {
  type        = string
  description = "Boolean to add AWS pricing actions to TFE IAM instance profile for cost estimation feature."
  default     = true
}
