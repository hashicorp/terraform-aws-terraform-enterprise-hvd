# Deployment customizations

This page contains various deployment customizations as it relates to creating your TFE infrastructure, and their corresponding module input variables that you may additionally set to meet your own requirements where the default module values do not suffice. That said, all of the module input variables on this page are optional.

## Load balancing

### Load balancer type

This module supports either creating a network load balancer (NLB) or an application load balancer (ALB) in front of the TFE autoscaling group. ***The default is NLB**, but the following input variable may be set to an ALB if desirable.

```hcl
lb_type = "alb"
```

### Load balancer scheme

This module supports creating a load balancer with either and `internal` or `internet-facing` load balancing scheme. **The default is `internal`**, but the following module boolean input variable may be set to configure the load balancer to be `internet-facing` (public) if desirable.

```hcl
lb_is_internal = false
```

## DNS

This module supports creating an _alias_ record in AWS Route53 for the TFE FQDN to resolve to the load balancer DNS name. To do so, the following module input variables may be set:

```hcl
create_route53_tfe_dns_record      = true
route53_tfe_hosted_zone_name       = "<example.com>"
route53_tfe_hosted_zone_is_private = true
```

>📝 Note: If `lb_is_internal` is `false`, then `route53_tfe_hosted_zone_is_private` should also be `false`. An DNS record resolving to an _internal_ load balancer should be created in a _private_ Route53 Hosted Zone, and a DNS record resolving to an _Internet-facing_ (external) load balancer should be a created in a _public_ Route53 Hosted Zone.

## KMS

If you require the use of a customer-managed key(s) (CMK) to encrypt your AWS resources, the following module input variables may be set:

```hcl
ebs_kms_key_arn   = "<ebs-kms-key-arn>"
rds_kms_key_arn   = "<rds-kms-key-arn>"
s3_kms_key_arn    = "<s3-kms-key-arn>"
redis_kms_key_arn = "<redis-kms-key-arn>"
```

## Custom AMI

By default, this module will use the standard AWS Marketplace image based on the value of the `ec2_os_distro` input (either `ubuntu`, `rhel`, or `al2023`). If you prefer to use your own custom AMI, then you may do so by setting `ec2_ami_id` accordingly.

```hcl
ec2_os_distro = "<rhel>"
ec2_ami_id    = "<custom-rhel-ami-id>"
```

Ensure the value you set for `ec2_os_distro` accurately reflects the OS distribution of your custom AMI.

### Software dependencies

By default, the [tfe_user_data](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/templates/tfe_user_data.sh.tpl) (cloud-init) script will attempt to install the required software dependencies to install TFE:

- `aws-cli` (and `unzip` as a dependency to unpacking and installing this)
- `docker` or `podman` (depending on the value of the `container_runtime` input)

If your TFE EC2 instances will not have egress connectivity to the official Linux package repositories, then you should bake those dependencies into your custom image before deploying TFE.

## Proxy

To configure a proxy for outbound HTTP and HTTPS requests, set the following inputs:

```hcl
http_proxy                  = "http://proxy.example.com:3128"
https_proxy                 = "http://proxy.example.com:3128"
additional_no_proxy         = "10.0.0.0/8,192.168.1.0/24,internal.example.com"
cidr_allow_egress_ec2_proxy = ["<proxy-ip-address/32>"] # IP address(es) of proxy server
```

This configuration applies the proxy settings at both the host level and within the TFE application containers.

### Proxy bypass

If either `http_proxy` or `https_proxy` (or both) are set, the module will automatically generate a base `no_proxy` list that includes:

- `localhost`
- `127.0.0.1`
- `169.254.169.254`
- Value of `var.tfe_fqdn`
- EC2 instance private IP address
- TFE S3 bucket regional domain name (_e.g.,_ `<tfe-s3-bucket-name>.s3.<aws-region>.amazonaws.com`)
- Regional AWS Secrets Manager endpoint (_e.g.,_ `secretsmanager.<aws-region>.amazonaws.com`)

Setting `additional_no_proxy` is optional. If specified, the value will be appended to this automatically generated base `no_proxy` list.
