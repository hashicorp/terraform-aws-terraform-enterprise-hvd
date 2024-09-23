# Example Scenario - Podman | RHEL | Internal Network Load Balancer (NLB)

| Configuration               | Value                        |
|-----------------------------|------------------------------|
| Operational mode            | `active-active`              |
| Container runtime           | `podman`                     |
| Operating system            | `rhel` (major version 9)     |
| Load balancer type          | `nlb` (TCP/Layer 4)          |
| Load balancer scheme        | `internal` (private)         |
| Log forwarding destination  | `s3`                         |
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.64 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tfe"></a> [tfe](#module\_tfe) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_no_proxy"></a> [additional\_no\_proxy](#input\_additional\_no\_proxy) | Comma-separated domain names for which outbound requests doesn't have to be routed through any proxy. | `string` | `""` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | The amount of time to wait for a new TFE EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one. | `number` | `900` | no |
| <a name="input_asg_instance_count"></a> [asg\_instance\_count](#input\_asg\_instance\_count) | Desired number of TFE EC2 instances to run in autoscaling group. Must be `1` when `tfe_operational_mode` is `external`. | `number` | `1` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | Max number of TFE EC2 instances to run in autoscaling group. Only valid when `tfe_operational_mode` is `active-active`. Value is hard-coded to `1` when `tfe_operational_mode` is `external`. | `number` | `3` | no |
| <a name="input_cidr_allow_egress_ec2_dns"></a> [cidr\_allow\_egress\_ec2\_dns](#input\_cidr\_allow\_egress\_ec2\_dns) | List of destination CIDR ranges to allow TCP/53 and UDP/53 (DNS) outbound from TFE EC2 instances. Only set if you want to use custom DNS servers instead of the AWS-provided DNS resolver within your VPC. | `list(string)` | `[]` | no |
| <a name="input_cidr_allow_egress_ec2_http"></a> [cidr\_allow\_egress\_ec2\_http](#input\_cidr\_allow\_egress\_ec2\_http) | List of destination CIDR ranges to allow TCP/80 outbound from TFE EC2 instances. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cidr_allow_egress_ec2_https"></a> [cidr\_allow\_egress\_ec2\_https](#input\_cidr\_allow\_egress\_ec2\_https) | List of destination CIDR ranges to allow TCP/443 outbound from TFE EC2 instances. Include the CIDR range of your VCS provider if you are configuring VCS integration with TFE. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cidr_allow_ingress_ec2_ssh"></a> [cidr\_allow\_ingress\_ec2\_ssh](#input\_cidr\_allow\_ingress\_ec2\_ssh) | List of CIDR ranges to allow SSH ingress to TFE EC2 instance (i.e. bastion IP, client/workstation IP, etc.). | `list(string)` | `[]` | no |
| <a name="input_cidr_allow_ingress_tfe_443"></a> [cidr\_allow\_ingress\_tfe\_443](#input\_cidr\_allow\_ingress\_tfe\_443) | List of CIDR ranges to allow ingress traffic on port 443 to TFE server or load balancer. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cidr_allow_ingress_tfe_metrics_http"></a> [cidr\_allow\_ingress\_tfe\_metrics\_http](#input\_cidr\_allow\_ingress\_tfe\_metrics\_http) | List of CIDR ranges to allow TCP/9090 (HTTP) inbound to metrics endpoint on TFE EC2 instances. | `list(string)` | `[]` | no |
| <a name="input_cidr_allow_ingress_tfe_metrics_https"></a> [cidr\_allow\_ingress\_tfe\_metrics\_https](#input\_cidr\_allow\_ingress\_tfe\_metrics\_https) | List of CIDR ranges to allow TCP/9091 (HTTPS) inbound to metrics endpoint on TFE EC2 instances. | `list(string)` | `[]` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Name of CloudWatch Log Group to configure as log forwarding destination. Only valid when `tfe_log_forwarding_enabled` is `true`. | `string` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for all taggable AWS resources. | `map(string)` | `{}` | no |
| <a name="input_container_runtime"></a> [container\_runtime](#input\_container\_runtime) | Container runtime to use for TFE. Supported values are `docker` or `podman`. | `string` | `"docker"` | no |
| <a name="input_create_route53_tfe_dns_record"></a> [create\_route53\_tfe\_dns\_record](#input\_create\_route53\_tfe\_dns\_record) | Boolean to create Route53 Alias Record for `tfe_hostname` resolving to Load Balancer DNS name. If `true`, `route53_tfe_hosted_zone_name` is also required. | `bool` | `false` | no |
| <a name="input_custom_fluent_bit_config"></a> [custom\_fluent\_bit\_config](#input\_custom\_fluent\_bit\_config) | Custom Fluent Bit configuration for log forwarding. Only valid when `tfe_log_forwarding_enabled` is `true` and `log_fwd_destination_type` is `custom`. | `string` | `null` | no |
| <a name="input_docker_version"></a> [docker\_version](#input\_docker\_version) | Version of Docker to install on TFE EC2 instances. Not applicable to Amazon Linux 2023 distribution (when `ec2_os_distro` is `al2023`). | `string` | `"24.0.9"` | no |
| <a name="input_ebs_iops"></a> [ebs\_iops](#input\_ebs\_iops) | Amount of IOPS to configure when EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`. | `number` | `3000` | no |
| <a name="input_ebs_is_encrypted"></a> [ebs\_is\_encrypted](#input\_ebs\_is\_encrypted) | Boolean to encrypt the EBS root block device of the TFE EC2 instance(s). An AWS managed key will be used when `true` unless a value is also specified for `ebs_kms_key_arn`. | `bool` | `true` | no |
| <a name="input_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#input\_ebs\_kms\_key\_arn) | ARN of KMS customer managed key (CMK) to encrypt TFE EC2 EBS volumes. | `string` | `null` | no |
| <a name="input_ebs_throughput"></a> [ebs\_throughput](#input\_ebs\_throughput) | Throughput (MB/s) to configure when EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`. | `number` | `250` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | Size (GB) of the root EBS volume for TFE EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`. | `number` | `50` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | EBS volume type for TFE EC2 instances. | `string` | `"gp3"` | no |
| <a name="input_ec2_allow_all_egress"></a> [ec2\_allow\_all\_egress](#input\_ec2\_allow\_all\_egress) | Boolean to allow all egress traffic from TFE EC2 instances. | `bool` | `false` | no |
| <a name="input_ec2_allow_ssm"></a> [ec2\_allow\_ssm](#input\_ec2\_allow\_ssm) | Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the TFE instance role, allowing the SSM agent (if present) to function. | `bool` | `false` | no |
| <a name="input_ec2_ami_id"></a> [ec2\_ami\_id](#input\_ec2\_ami\_id) | Custom AMI ID for TFE EC2 launch template. If specified, value of `ec2_os_distro` must coincide with this custom AMI OS distro. | `string` | `null` | no |
| <a name="input_ec2_instance_size"></a> [ec2\_instance\_size](#input\_ec2\_instance\_size) | EC2 instance type for TFE EC2 launch template. | `string` | `"m7i.xlarge"` | no |
| <a name="input_ec2_os_distro"></a> [ec2\_os\_distro](#input\_ec2\_os\_distro) | Linux OS distribution type for TFE EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`. | `string` | `"ubuntu"` | no |
| <a name="input_ec2_ssh_key_pair"></a> [ec2\_ssh\_key\_pair](#input\_ec2\_ssh\_key\_pair) | Name of existing SSH key pair to attach to TFE EC2 instance. | `string` | `null` | no |
| <a name="input_ec2_subnet_ids"></a> [ec2\_subnet\_ids](#input\_ec2\_subnet\_ids) | List of subnet IDs to use for the EC2 instance. Private subnets is the best practice here. | `list(string)` | n/a | yes |
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming all AWS resources for this deployment. Most commonly set to either an environment (e.g. 'sandbox', 'prod'), a team name, or a project name. | `string` | n/a | yes |
| <a name="input_http_proxy"></a> [http\_proxy](#input\_http\_proxy) | Outbound HTTP requests will be routed through the proxy at the given URL. | `string` | `""` | no |
| <a name="input_https_proxy"></a> [https\_proxy](#input\_https\_proxy) | Outbound HTTPS requests will be routed through the proxy at the given URL. | `string` | `""` | no |
| <a name="input_is_secondary_region"></a> [is\_secondary\_region](#input\_is\_secondary\_region) | Boolean indicating whether this TFE deployment is in the primary or secondary (replica) region. | `bool` | `false` | no |
| <a name="input_lb_is_internal"></a> [lb\_is\_internal](#input\_lb\_is\_internal) | Boolean to create an internal (private) load balancer. The `lb_subnet_ids` must be private subnets when this is `true`. | `bool` | `true` | no |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | List of subnet IDs to use for the load balancer. If `lb_is_internal` is `false`, then these should be public subnets. Otherwise, these should be private subnets. | `list(string)` | n/a | yes |
| <a name="input_lb_type"></a> [lb\_type](#input\_lb\_type) | Indicates which type of AWS load balancer is created: Application Load Balancer (`alb`) or Network Load Balancer (`nlb`). | `string` | `"nlb"` | no |
| <a name="input_log_fwd_destination_type"></a> [log\_fwd\_destination\_type](#input\_log\_fwd\_destination\_type) | Type of log forwarding destination for Fluent Bit. Supported values are `s3`, `cloudwatch`, or `custom`. | `string` | `"cloudwatch"` | no |
| <a name="input_rds_apply_immediately"></a> [rds\_apply\_immediately](#input\_rds\_apply\_immediately) | Boolean to apply changes immediately to RDS cluster instance. | `bool` | `true` | no |
| <a name="input_rds_aurora_engine_mode"></a> [rds\_aurora\_engine\_mode](#input\_rds\_aurora\_engine\_mode) | RDS Aurora database engine mode. | `string` | `"provisioned"` | no |
| <a name="input_rds_aurora_engine_version"></a> [rds\_aurora\_engine\_version](#input\_rds\_aurora\_engine\_version) | Engine version of RDS Aurora PostgreSQL. | `number` | `16.2` | no |
| <a name="input_rds_aurora_instance_class"></a> [rds\_aurora\_instance\_class](#input\_rds\_aurora\_instance\_class) | Instance class of Aurora PostgreSQL database. | `string` | `"db.r6i.xlarge"` | no |
| <a name="input_rds_aurora_replica_count"></a> [rds\_aurora\_replica\_count](#input\_rds\_aurora\_replica\_count) | Number of replica (reader) cluster instances to create within the RDS Aurora database cluster (within the same region). | `number` | `1` | no |
| <a name="input_rds_availability_zones"></a> [rds\_availability\_zones](#input\_rds\_availability\_zones) | List of AWS availability zones to spread Aurora database cluster instances across. Leave as `null` and RDS will automatically assign 3 availability zones. | `list(string)` | `null` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | The number of days to retain backups for. Must be between 0 and 35. Must be greater than 0 if the database cluster is used as a source of a read replica cluster. | `number` | `35` | no |
| <a name="input_rds_deletion_protection"></a> [rds\_deletion\_protection](#input\_rds\_deletion\_protection) | Boolean to enable deletion protection for RDS global cluster. | `bool` | `false` | no |
| <a name="input_rds_force_destroy"></a> [rds\_force\_destroy](#input\_rds\_force\_destroy) | Boolean to enable the removal of RDS database cluster members from RDS global cluster on destroy. | `bool` | `false` | no |
| <a name="input_rds_global_cluster_id"></a> [rds\_global\_cluster\_id](#input\_rds\_global\_cluster\_id) | ID of RDS global cluster. Only required only when `is_secondary_region` is `true`, otherwise leave as `null`. | `string` | `null` | no |
| <a name="input_rds_kms_key_arn"></a> [rds\_kms\_key\_arn](#input\_rds\_kms\_key\_arn) | ARN of KMS customer managed key (CMK) to encrypt TFE RDS cluster. | `string` | `null` | no |
| <a name="input_rds_parameter_group_family"></a> [rds\_parameter\_group\_family](#input\_rds\_parameter\_group\_family) | Family of Aurora PostgreSQL DB Parameter Group. | `string` | `"aurora-postgresql16"` | no |
| <a name="input_rds_performance_insights_enabled"></a> [rds\_performance\_insights\_enabled](#input\_rds\_performance\_insights\_enabled) | Boolean to enable performance insights for RDS cluster instance(s). | `bool` | `true` | no |
| <a name="input_rds_performance_insights_retention_period"></a> [rds\_performance\_insights\_retention\_period](#input\_rds\_performance\_insights\_retention\_period) | Number of days to retain RDS performance insights data. Must be between 7 and 731. | `number` | `7` | no |
| <a name="input_rds_preferred_backup_window"></a> [rds\_preferred\_backup\_window](#input\_rds\_preferred\_backup\_window) | Daily time range (UTC) for RDS backup to occur. Must not overlap with `rds_preferred_maintenance_window`. | `string` | `"04:00-04:30"` | no |
| <a name="input_rds_preferred_maintenance_window"></a> [rds\_preferred\_maintenance\_window](#input\_rds\_preferred\_maintenance\_window) | Window (UTC) to perform RDS database maintenance. Must not overlap with `rds_preferred_backup_window`. | `string` | `"Sun:08:00-Sun:09:00"` | no |
| <a name="input_rds_replication_source_identifier"></a> [rds\_replication\_source\_identifier](#input\_rds\_replication\_source\_identifier) | ARN of source RDS cluster or cluster instance if this database cluster is to be created as a read replica. Only required when `is_secondary_region` is `true`, otherwise leave as `null`. | `string` | `null` | no |
| <a name="input_rds_skip_final_snapshot"></a> [rds\_skip\_final\_snapshot](#input\_rds\_skip\_final\_snapshot) | Boolean to enable RDS to take a final database snapshot before destroying. | `bool` | `false` | no |
| <a name="input_rds_source_region"></a> [rds\_source\_region](#input\_rds\_source\_region) | Source region for RDS cross-region replication. Only required when `is_secondary_region` is `true`, otherwise leave as `null`. | `string` | `null` | no |
| <a name="input_rds_storage_encrypted"></a> [rds\_storage\_encrypted](#input\_rds\_storage\_encrypted) | Boolean to encrypt RDS storage. An AWS managed key will be used when `true` unless a value is also specified for `rds_kms_key_arn`. | `bool` | `true` | no |
| <a name="input_rds_subnet_ids"></a> [rds\_subnet\_ids](#input\_rds\_subnet\_ids) | List of subnet IDs to use for RDS database subnet group. Private subnets is the best practice here. | `list(string)` | n/a | yes |
| <a name="input_redis_apply_immediately"></a> [redis\_apply\_immediately](#input\_redis\_apply\_immediately) | Boolean to apply changes immediately to Redis cluster. | `bool` | `true` | no |
| <a name="input_redis_at_rest_encryption_enabled"></a> [redis\_at\_rest\_encryption\_enabled](#input\_redis\_at\_rest\_encryption\_enabled) | Boolean to enable encryption at rest on Redis cluster. An AWS managed key will be used when `true` unless a value is also specified for `redis_kms_key_arn`. | `bool` | `true` | no |
| <a name="input_redis_auto_minor_version_upgrade"></a> [redis\_auto\_minor\_version\_upgrade](#input\_redis\_auto\_minor\_version\_upgrade) | Boolean to enable automatic minor version upgrades for Redis cluster. | `bool` | `true` | no |
| <a name="input_redis_automatic_failover_enabled"></a> [redis\_automatic\_failover\_enabled](#input\_redis\_automatic\_failover\_enabled) | Boolean for deploying Redis nodes in multiple availability zones and enabling automatic failover. | `bool` | `true` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | Redis version number. | `string` | `"7.1"` | no |
| <a name="input_redis_kms_key_arn"></a> [redis\_kms\_key\_arn](#input\_redis\_kms\_key\_arn) | ARN of KMS customer managed key (CMK) to encrypt Redis cluster with. | `string` | `null` | no |
| <a name="input_redis_multi_az_enabled"></a> [redis\_multi\_az\_enabled](#input\_redis\_multi\_az\_enabled) | Boolean to create Redis nodes across multiple availability zones. If `true`, `redis_automatic_failover_enabled` must also be `true`, and more than one subnet must be specified within `redis_subnet_ids`. | `bool` | `true` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | Type (size) of Redis node from a compute, memory, and network throughput standpoint. | `string` | `"cache.m5.large"` | no |
| <a name="input_redis_parameter_group_name"></a> [redis\_parameter\_group\_name](#input\_redis\_parameter\_group\_name) | Name of parameter group to associate with Redis cluster. | `string` | `"default.redis7"` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Port number the Redis nodes will accept connections on. | `number` | `6379` | no |
| <a name="input_redis_subnet_ids"></a> [redis\_subnet\_ids](#input\_redis\_subnet\_ids) | List of subnet IDs to use for Redis cluster subnet group. Private subnets is the best practice here. | `list(string)` | `[]` | no |
| <a name="input_redis_transit_encryption_enabled"></a> [redis\_transit\_encryption\_enabled](#input\_redis\_transit\_encryption\_enabled) | Boolean to enable TLS encryption between TFE and the Redis cluster. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where TFE will be deployed. | `string` | n/a | yes |
| <a name="input_route53_tfe_hosted_zone_is_private"></a> [route53\_tfe\_hosted\_zone\_is\_private](#input\_route53\_tfe\_hosted\_zone\_is\_private) | Boolean indicating if `route53_tfe_hosted_zone_name` is a private hosted zone. | `bool` | `false` | no |
| <a name="input_route53_tfe_hosted_zone_name"></a> [route53\_tfe\_hosted\_zone\_name](#input\_route53\_tfe\_hosted\_zone\_name) | Route53 Hosted Zone name to create `tfe_hostname` Alias record in. Required if `create_route53_tfe_dns_record` is `true`. | `string` | `null` | no |
| <a name="input_s3_destination_bucket_arn"></a> [s3\_destination\_bucket\_arn](#input\_s3\_destination\_bucket\_arn) | ARN of destination S3 bucket for cross-region replication configuration. Bucket should already exist in secondary region. Required when `s3_enable_bucket_replication` is `true`. | `string` | `""` | no |
| <a name="input_s3_destination_bucket_kms_key_arn"></a> [s3\_destination\_bucket\_kms\_key\_arn](#input\_s3\_destination\_bucket\_kms\_key\_arn) | ARN of KMS key of destination S3 bucket for cross-region replication configuration if it is encrypted with a customer managed key (CMK). | `string` | `null` | no |
| <a name="input_s3_enable_bucket_replication"></a> [s3\_enable\_bucket\_replication](#input\_s3\_enable\_bucket\_replication) | Boolean to enable cross-region replication for TFE S3 bucket. Do not enable when `is_secondary_region` is `true`. An `s3_destination_bucket_arn` is also required when `true`. | `bool` | `false` | no |
| <a name="input_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#input\_s3\_kms\_key\_arn) | ARN of KMS customer managed key (CMK) to encrypt TFE S3 bucket with. | `string` | `null` | no |
| <a name="input_s3_log_fwd_bucket_name"></a> [s3\_log\_fwd\_bucket\_name](#input\_s3\_log\_fwd\_bucket\_name) | Name of S3 bucket to configure as log forwarding destination. Only valid when `tfe_log_forwarding_enabled` is `true`. | `string` | `null` | no |
| <a name="input_tfe_alb_tls_certificate_arn"></a> [tfe\_alb\_tls\_certificate\_arn](#input\_tfe\_alb\_tls\_certificate\_arn) | ARN of existing TFE TLS certificate imported in ACM to be used for application load balancer (ALB) HTTPS listeners. Required when `lb_type` is `alb`. | `string` | `null` | no |
| <a name="input_tfe_capacity_concurrency"></a> [tfe\_capacity\_concurrency](#input\_tfe\_capacity\_concurrency) | Maximum number of concurrent Terraform runs to allow on a TFE node. | `number` | `10` | no |
| <a name="input_tfe_capacity_cpu"></a> [tfe\_capacity\_cpu](#input\_tfe\_capacity\_cpu) | Maximum number of CPU cores that a Terraform run is allowed to consume in TFE. Set to `0` for no limit. | `number` | `0` | no |
| <a name="input_tfe_capacity_memory"></a> [tfe\_capacity\_memory](#input\_tfe\_capacity\_memory) | Maximum amount of memory (in MiB) that a Terraform run is allowed to consume in TFE. | `number` | `2048` | no |
| <a name="input_tfe_cost_estimation_iam_enabled"></a> [tfe\_cost\_estimation\_iam\_enabled](#input\_tfe\_cost\_estimation\_iam\_enabled) | Boolean to add AWS pricing actions to TFE IAM instance profile for cost estimation feature. | `string` | `true` | no |
| <a name="input_tfe_database_name"></a> [tfe\_database\_name](#input\_tfe\_database\_name) | Name of TFE database to create within RDS global cluster. | `string` | `"tfe"` | no |
| <a name="input_tfe_database_parameters"></a> [tfe\_database\_parameters](#input\_tfe\_database\_parameters) | PostgreSQL server parameters for the connection URI. Used to configure the PostgreSQL connection. | `string` | `"sslmode=require"` | no |
| <a name="input_tfe_database_password_secret_arn"></a> [tfe\_database\_password\_secret\_arn](#input\_tfe\_database\_password\_secret\_arn) | ARN of AWS Secrets Manager secret for the TFE database password used to create RDS Aurora (PostgreSQL) database cluster. Secret type should be plaintext. Value of secret must be from 8 to 128 alphanumeric characters or symbols (excluding `@`, `"`, and `/`). | `string` | n/a | yes |
| <a name="input_tfe_database_user"></a> [tfe\_database\_user](#input\_tfe\_database\_user) | Username for TFE RDS database cluster. | `string` | `"tfe"` | no |
| <a name="input_tfe_encryption_password_secret_arn"></a> [tfe\_encryption\_password\_secret\_arn](#input\_tfe\_encryption\_password\_secret\_arn) | ARN of AWS Secrets Manager secret for TFE encryption password. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_tfe_fqdn"></a> [tfe\_fqdn](#input\_tfe\_fqdn) | Fully qualified domain name (FQDN) of TFE instance. This name should resolve to the DNS name or IP address of the TFE load balancer and will be what clients use to access TFE. | `string` | n/a | yes |
| <a name="input_tfe_hairpin_addressing"></a> [tfe\_hairpin\_addressing](#input\_tfe\_hairpin\_addressing) | Boolean to enable hairpin addressing for layer 4 load balancer with loopback prevention. Must be `true` when `lb_type` is `nlb` and `lb_is_internal` is `true`. | `bool` | `true` | no |
| <a name="input_tfe_image_name"></a> [tfe\_image\_name](#input\_tfe\_image\_name) | Name of the TFE container image. Only set this if you are hosting the TFE container image in your own custom repository. | `string` | `"hashicorp/terraform-enterprise"` | no |
| <a name="input_tfe_image_repository_password"></a> [tfe\_image\_repository\_password](#input\_tfe\_image\_repository\_password) | Password for container registry where TFE container image is hosted. Leave as `null` if using the default TFE registry as the default password is the TFE license. | `string` | `null` | no |
| <a name="input_tfe_image_repository_url"></a> [tfe\_image\_repository\_url](#input\_tfe\_image\_repository\_url) | Repository for the TFE image. Only change this if you are hosting the TFE container image in your own custom repository. | `string` | `"images.releases.hashicorp.com"` | no |
| <a name="input_tfe_image_repository_username"></a> [tfe\_image\_repository\_username](#input\_tfe\_image\_repository\_username) | Username for container registry where TFE container image is hosted. | `string` | `"terraform"` | no |
| <a name="input_tfe_image_tag"></a> [tfe\_image\_tag](#input\_tfe\_image\_tag) | Tag for the TFE image. This represents the version of TFE to deploy. | `string` | `"v202407-1"` | no |
| <a name="input_tfe_license_reporting_opt_out"></a> [tfe\_license\_reporting\_opt\_out](#input\_tfe\_license\_reporting\_opt\_out) | Boolean to opt out of TFE license reporting. | `bool` | `false` | no |
| <a name="input_tfe_license_secret_arn"></a> [tfe\_license\_secret\_arn](#input\_tfe\_license\_secret\_arn) | ARN of AWS Secrets Manager secret for TFE license file. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_tfe_log_forwarding_enabled"></a> [tfe\_log\_forwarding\_enabled](#input\_tfe\_log\_forwarding\_enabled) | Boolean to enable TFE log forwarding feature. | `bool` | `false` | no |
| <a name="input_tfe_metrics_enable"></a> [tfe\_metrics\_enable](#input\_tfe\_metrics\_enable) | Boolean to enable TFE metrics endpoints. | `bool` | `false` | no |
| <a name="input_tfe_metrics_http_port"></a> [tfe\_metrics\_http\_port](#input\_tfe\_metrics\_http\_port) | HTTP port for TFE metrics scrape. | `number` | `9090` | no |
| <a name="input_tfe_metrics_https_port"></a> [tfe\_metrics\_https\_port](#input\_tfe\_metrics\_https\_port) | HTTPS port for TFE metrics scrape. | `number` | `9091` | no |
| <a name="input_tfe_object_storage_s3_access_key_id"></a> [tfe\_object\_storage\_s3\_access\_key\_id](#input\_tfe\_object\_storage\_s3\_access\_key\_id) | Access key ID for S3 bucket. Required when `tfe_object_storage_s3_use_instance_profile` is `false`. | `string` | `null` | no |
| <a name="input_tfe_object_storage_s3_secret_access_key"></a> [tfe\_object\_storage\_s3\_secret\_access\_key](#input\_tfe\_object\_storage\_s3\_secret\_access\_key) | Secret access key for S3 bucket. Required when `tfe_object_storage_s3_use_instance_profile` is `false`. | `string` | `null` | no |
| <a name="input_tfe_object_storage_s3_use_instance_profile"></a> [tfe\_object\_storage\_s3\_use\_instance\_profile](#input\_tfe\_object\_storage\_s3\_use\_instance\_profile) | Boolean to use TFE instance profile for S3 bucket access. If `false`, `tfe_object_storage_s3_access_key_id` and `tfe_object_storage_s3_secret_access_key` are required. | `bool` | `true` | no |
| <a name="input_tfe_operational_mode"></a> [tfe\_operational\_mode](#input\_tfe\_operational\_mode) | [Operational mode](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/operation-modes) for TFE. Valid values are `active-active` or `external`. | `string` | `"active-active"` | no |
| <a name="input_tfe_redis_password_secret_arn"></a> [tfe\_redis\_password\_secret\_arn](#input\_tfe\_redis\_password\_secret\_arn) | ARN of AWS Secrets Manager secret for the TFE Redis password used to create Redis (Elasticache Replication Group) cluster. Secret type should be plaintext. Value of secret must be from 16 to 128 alphanumeric characters or symbols (excluding `@`, `"`, and `/`). | `string` | `null` | no |
| <a name="input_tfe_run_pipeline_docker_network"></a> [tfe\_run\_pipeline\_docker\_network](#input\_tfe\_run\_pipeline\_docker\_network) | Docker network where the containers that execute Terraform runs will be created. The network must already exist, it will not be created automatically. Leave as `null` to use the default network created by TFE. | `string` | `null` | no |
| <a name="input_tfe_run_pipeline_image"></a> [tfe\_run\_pipeline\_image](#input\_tfe\_run\_pipeline\_image) | Name of the Docker image to use for the run pipeline driver. | `string` | `null` | no |
| <a name="input_tfe_run_pipeline_image_ecr_repo_name"></a> [tfe\_run\_pipeline\_image\_ecr\_repo\_name](#input\_tfe\_run\_pipeline\_image\_ecr\_repo\_name) | Name of the AWS ECR repository containing your custom TFE run pipeline image. | `string` | `null` | no |
| <a name="input_tfe_tls_ca_bundle_secret_arn"></a> [tfe\_tls\_ca\_bundle\_secret\_arn](#input\_tfe\_tls\_ca\_bundle\_secret\_arn) | ARN of AWS Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_tfe_tls_cert_secret_arn"></a> [tfe\_tls\_cert\_secret\_arn](#input\_tfe\_tls\_cert\_secret\_arn) | ARN of AWS Secrets Manager secret for TFE TLS certificate in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_tfe_tls_enforce"></a> [tfe\_tls\_enforce](#input\_tfe\_tls\_enforce) | Boolean to enforce TLS. | `bool` | `false` | no |
| <a name="input_tfe_tls_privkey_secret_arn"></a> [tfe\_tls\_privkey\_secret\_arn](#input\_tfe\_tls\_privkey\_secret\_arn) | ARN of AWS Secrets Manager secret for TFE TLS private key in PEM format. Secret must be stored as a base64-encoded string. Secret type should be plaintext. | `string` | n/a | yes |
| <a name="input_tfe_vault_disable_mlock"></a> [tfe\_vault\_disable\_mlock](#input\_tfe\_vault\_disable\_mlock) | Boolean to disable mlock for internal Vault. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of VPC where TFE will be deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rds_aurora_cluster_arn"></a> [rds\_aurora\_cluster\_arn](#output\_rds\_aurora\_cluster\_arn) | n/a |
| <a name="output_rds_aurora_cluster_endpoint"></a> [rds\_aurora\_cluster\_endpoint](#output\_rds\_aurora\_cluster\_endpoint) | n/a |
| <a name="output_rds_aurora_cluster_members"></a> [rds\_aurora\_cluster\_members](#output\_rds\_aurora\_cluster\_members) | n/a |
| <a name="output_rds_aurora_global_cluster_id"></a> [rds\_aurora\_global\_cluster\_id](#output\_rds\_aurora\_global\_cluster\_id) | ------------------------------------------------------------------------------ Database ------------------------------------------------------------------------------ |
| <a name="output_tfe_lb_dns_name"></a> [tfe\_lb\_dns\_name](#output\_tfe\_lb\_dns\_name) | n/a |
| <a name="output_tfe_s3_bucket_name"></a> [tfe\_s3\_bucket\_name](#output\_tfe\_s3\_bucket\_name) | ------------------------------------------------------------------------------ Object storage ------------------------------------------------------------------------------ |
| <a name="output_tfe_url"></a> [tfe\_url](#output\_tfe\_url) | ------------------------------------------------------------------------------ TFE URLs ------------------------------------------------------------------------------ |
<!-- END_TF_DOCS -->