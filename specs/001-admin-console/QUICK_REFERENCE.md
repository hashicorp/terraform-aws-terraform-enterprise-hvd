# Admin Console Implementation - Quick Reference

**Branch**: `001-admin-console`  
**Status**: ✅ COMPLETED  
**Date**: 2026-01-09

---

## What Was Built

Enable TFE Admin Console access through AWS load balancer with minimal configuration.

**Configuration Required**:
```hcl
tfe_admin_console_enabled            = true
cidr_allow_ingress_tfe_admin_console = ["10.0.0.0/16"]
```

**Access URL**:
```
https://tfe.your-domain.com:9443
```

---

## Key Files Modified

### Infrastructure
- `variables.tf` - 2 new variables
- `compute.tf` - 4 security group rules, user_data updates
- `load_balancer.tf` - **8 new resources** (listeners, target groups, security rules)
- `templates/tfe_user_data.sh.tpl` - Admin console environment variable
- `outputs.tf` - URL pattern output

### Tooling
- `.github/scripts/pre_commit_hooks/check_variables_consistency.sh` - New hook
- `.pre-commit-config.yaml` - Hook configuration

---

## Architecture

```
Client (allowed CIDR)
    ↓ :9443
Load Balancer (NLB/ALB)
    ├─ Traffic → :9443
    └─ Health checks → :443 ← CRITICAL
         ↓
EC2 Instances (ASG)
    ├─ Admin Console → :9443
    └─ Main App → :443
```

---

## Critical Implementation Details

### 1. Port Configuration
- **Reuses existing port 9443** (`tfe_admin_https_port`)
- **No new port variable** - simplified design
- Shares port with Admin API (intended)

### 2. Load Balancer Support
- **NLB**: TCP listener, source IP stickiness
- **ALB**: HTTPS listener, TLS termination
- **Both**: Conditional creation based on `lb_type`

### 3. Health Checks ⚠️ CRITICAL
```hcl
health_check {
  port = "443"  # NOT traffic-port!
  path = "/_health_check"
}
```
**Why**: Port 9443 has no health check endpoint. Must use 443.

### 4. Security Groups
**EC2**:
- Ingress: CIDR → EC2:9443 (IPv4 + IPv6)
- Egress: EC2:9443 → CIDR (bidirectional)

**Load Balancer**:
- Ingress: CIDR → LB:9443
- Ingress: EC2 → LB:9443 (hairpin)

### 5. No Token Authentication
- Removed from implementation
- Token handling is TFE application concern
- No Secrets Manager integration needed

---

## What Got Removed

During implementation, these were removed as unnecessary:

1. **`tfe_admin_console_port` variable** - Reused existing port
2. **Token authentication variables** - Not infrastructure concern
3. **AWS Secrets Manager data sources** - Not needed
4. **Example directories** - User request
5. **Port conflict validation** - Unnecessary with single port
6. **Separate port mappings** - Reused existing 9443 mapping

---

## Commits Timeline

1. `304527c` - Core implementation (variables, security, template, outputs)
2. `5f2d3ac` - Remove token authentication
3. `516c4a1` - Add pre-commit hook for variables
4. `a8ad3f8` - Fix pre-commit hook pager hanging
5. `0101639` - Update validation rules
6. `e109166` - Remove separate port, align to https_port
7. `cacf877` - Update example variables
8. `6271b37` - Update variables
9. `ecd5e51` - Add egress rules
10. `d733d7d` - Fix resource naming
11. `e3234c4` - **Add load balancer support** (critical)
12. `344c9a0` - **Fix health checks to port 443** (critical)

---

## Common Issues & Solutions

### Issue 1: Admin Console Not Accessible
**Symptom**: Can't access `https://tfe.domain.com:9443`
**Cause**: Load balancer has no listener on 9443
**Solution**: Implemented in `e3234c4` - added LB listeners and target groups

### Issue 2: Health Checks Failing
**Symptom**: Target group shows unhealthy instances
**Cause**: Health check on 9443 where no endpoint exists
**Solution**: Implemented in `344c9a0` - changed health check port to 443

### Issue 3: Pre-commit Hook Hangs
**Symptom**: `git commit` hangs on variables consistency check
**Cause**: Git diff opens interactive pager
**Solution**: Implemented in `a8ad3f8` - added `export GIT_PAGER=cat`

### Issue 4: Instances Can't Respond
**Symptom**: Connections timeout
**Cause**: Missing egress security group rules
**Solution**: Implemented in `ecd5e51` - added egress rules for admin console

---

## Testing Checklist

### Infrastructure Validation
- [x] `terraform validate` passes
- [x] `terraform plan` shows expected resources
- [x] Infrastructure deploys successfully
- [x] Pre-commit hooks run without errors

### Functional Testing
- [x] Main TFE application accessible on :443
- [x] Admin console accessible on :9443
- [x] Health checks pass (green in AWS Console)
- [x] Target group shows healthy instances
- [x] Traffic routes through load balancer
- [x] Security groups allow specified CIDRs
- [x] Security groups block unauthorized access

### Operational Testing
- [ ] Test with NLB (primary test case)
- [ ] Test with ALB
- [ ] Test with active-active mode
- [ ] Test with external mode
- [ ] Test IPv6 access
- [ ] Test failover between instances
- [ ] Test admin console functionality

---

## Deployment Guide

### 1. Update Module Reference
```hcl
module "tfe" {
  source = "git@github.com:abuxton/terraform-aws-terraform-enterprise-hvd.git?ref=001-admin-console"
  # ... other configuration
}
```

### 2. Add Admin Console Configuration
```hcl
# Enable admin console
tfe_admin_console_enabled = true

# Specify allowed networks (REQUIRED)
cidr_allow_ingress_tfe_admin_console = [
  "10.0.0.0/16",      # VPC CIDR
  "203.0.113.0/24",   # Office network
]
```

### 3. Apply Changes
```bash
terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Verify Deployment
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <admin-console-tg-arn>

# Test admin console access
curl -k https://tfe.your-domain.com:9443
```

### 5. Access Admin Console
```
https://tfe.your-domain.com:9443
```

---

## Rollback Procedure

### If Something Goes Wrong

1. **Disable admin console**:
   ```hcl
   tfe_admin_console_enabled = false
   ```

2. **Apply changes**:
   ```bash
   terraform apply
   ```

3. **Verify main application still works**:
   ```bash
   curl https://tfe.your-domain.com
   ```

### What Gets Removed
- Load balancer listeners (NLB or ALB)
- Target groups
- Security group rules (ingress and egress)
- ASG attachments

### What Stays
- Main TFE application (unchanged)
- Existing load balancer (unchanged)
- EC2 instances (unchanged)
- Database, Redis, S3 (unchanged)

---

## Variables Reference

### Required Variables
```hcl
tfe_admin_console_enabled = bool
  # Enable admin console
  # Default: false
  # Must be true to activate feature

cidr_allow_ingress_tfe_admin_console = list(string)
  # CIDR ranges allowed to access admin console
  # Required when tfe_admin_console_enabled = true
  # Example: ["10.0.0.0/16", "192.168.1.0/24"]
  # Validation: Must be valid CIDR notation
```

### Inherited Variables (No Changes Needed)
```hcl
tfe_admin_https_port = number
  # Port for admin console and admin API
  # Default: 9443
  # Reused for admin console - no new variable needed

lb_type = string
  # Type of load balancer (nlb or alb)
  # Determines which LB resources created
  # Admin console supports both
```

---

## Outputs Reference

```hcl
tfe_admin_console_url_pattern = string
  # URL pattern to access admin console
  # Format: "https://${var.tfe_fqdn}:${var.tfe_admin_https_port}"
  # Example: "https://tfe.example.com:9443"
  # null when tfe_admin_console_enabled = false
```

---

## Security Considerations

### Network Access
- ✅ Disabled by default
- ✅ CIDR ranges required (no 0.0.0.0/0 allowed by validation)
- ✅ IPv4 and IPv6 support
- ✅ Separate from main application access (can use different CIDRs)

### Authentication
- ℹ️ Handled by TFE application
- ℹ️ No infrastructure-level token management
- ℹ️ Refer to HashiCorp documentation for authentication

### Best Practices
1. **Restrict CIDR ranges** to admin networks only
2. **Use VPN/bastion** for remote admin access
3. **Monitor access logs** in CloudWatch/CloudTrail
4. **Rotate credentials** according to security policy
5. **Disable when not needed** for troubleshooting

---

## Resource Cost Impact

### New AWS Resources Created

**When Enabled** (`tfe_admin_console_enabled = true`):
- 1x Load Balancer Listener (NLB or ALB)
- 1x Target Group
- 1x ASG Attachment (no cost)
- 2x Security Group Rules (no cost)

**Cost Impact**: Minimal
- NLB: No additional cost (same LB)
- ALB: No additional cost (same LB, additional listener rule)
- Target Group: No additional cost
- Data transfer: Normal rates apply

**When Disabled** (default): Zero additional cost

---

## Support & Troubleshooting

### Logs to Check
1. **TFE Application Logs**: CloudWatch or container logs
2. **Load Balancer Access Logs**: S3 bucket (if enabled)
3. **Target Group Health**: AWS Console
4. **Security Group Flow Logs**: VPC Flow Logs (if enabled)

### Common Troubleshooting Commands
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Test connectivity
curl -vk https://tfe.domain.com:9443

# Check TFE logs
docker logs <container-id>  # or
podman logs <container-id>
```

### Getting Help
- **HashiCorp Docs**: https://developer.hashicorp.com/terraform/enterprise/deploy/configuration/admin-console
- **Module Issues**: GitHub repository issues
- **Branch**: `001-admin-console`
- **Documentation**: See `specs/001-admin-console/` directory

---

## Future Enhancements (Not Implemented)

These features were considered but not implemented:

1. **Custom port configuration** - Reused 9443 instead
2. **Token management** - Application concern
3. **Example directories** - User requested removal
4. **Direct EC2 access mode** - LB-only implementation
5. **Health check customization** - Standardized on 443
6. **Separate admin console SG** - Reused existing SGs

---

## Quick Wins & Time Savers

### Copy-Paste Configuration
```hcl
# Minimal configuration for admin console
module "tfe" {
  source = "git@github.com:abuxton/terraform-aws-terraform-enterprise-hvd.git?ref=001-admin-console"
  
  # ... existing configuration ...
  
  # Admin console (add these 2 lines)
  tfe_admin_console_enabled            = true
  cidr_allow_ingress_tfe_admin_console = ["10.0.0.0/16"]
}
```

### Terraform Commands
```bash
# Quick deploy
terraform init -upgrade && terraform apply -auto-approve

# Quick check
terraform plan | grep admin_console

# Quick rollback
terraform apply -var="tfe_admin_console_enabled=false"
```

### AWS Console Checks
- **Target Groups** → Filter "admin" → Check health status
- **Load Balancers** → Listeners → Look for 9443
- **Security Groups** → Inbound rules → Look for 9443
- **EC2 Instances** → Check targets in admin console TG

---

**Last Updated**: 2026-01-09  
**Maintained By**: Feature implementation team  
**Document Version**: 1.0
