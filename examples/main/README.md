# Main Example

This directory contains a ready-made Terraform configuration and an [example terraform.tfvars file](./terraform.tfvars.example) for deploying this module.
Refer to the **Architectural decisions** section below for details on some of the key settings and their corresponding input variables to deploy your TFE instance.

## Architectural decisions

### Operational mode

**Input variable:** `tfe_operational_mode`

Supported values:
 - `active-active` (recommended)
 - `standalone`

### Operating system

**Input variable:** `ec2_os_distro`

Supported values:
- `ubuntu` - recommended if your preferred container runtime is `docker`
- `rhel` - recommended if your preferred container runtime is `podman`
- `al2023`
- `centos`

We recommend choosing either `ubuntu` or `rhel` for your `ec2_os_distro`.

### Container runtime

**Input variable:** `container_runtime`

Supported values:
 - `docker` - recommended if your `ec2_os_distro` is `ubuntu`
 - `podman` - recommended if your `ec2_os_distro` is `rhel`

### Load balancing

#### Load balancer scheme (exposure)

**Input variable:** `lb_is_internal` (bool)

Supported values:
- `true` - deploy an _internal_ load balancer; `lb_subnet_ids` must be _private_ subnets
- `false` - deploy an _Internet-facing_ load balancer; `lb_subnet_ids` must be _public_ subnets

We recommend deploying an internal load balancer unless you have a specific use case where your TFE users/clients or VCS need to be able to reach your TFE instance from the Internet.

### Log forwarding

**Input variable:** `tfe_log_forwarding_enabled` (bool)

Supported values:
- `true` - enabled log forwarding for TFE
- `false` - disables log forwarding for TFE

**Input variable:** `log_fwd_destination_type`

Supported values:
- `s3` - sets AWS S3 as the logging destination; specify an existing S3 bucket via `s3_log_fwd_bucket_name`
- `cloudwatch` - sets AWS CloudWatch as the logging destination; specify an existing CloudWatch log group via `cloudwatch_log_group_name`
- `custom` - sets a custom logging destination; specify your own custom FluentBit config via `custom_fluent_bit_config`