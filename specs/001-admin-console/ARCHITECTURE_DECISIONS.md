# Admin Console Implementation - Architectural Decisions Record (ADR)

**Feature**: TFE Admin Console Access via Load Balancer  
**Date**: 2026-01-09  
**Status**: Implemented  
**Branch**: `001-admin-console`

---

## Context

The TFE Admin Console is a web-based troubleshooting interface that runs on a separate port from the main TFE application. We needed to enable access to this console through AWS infrastructure in a secure, production-ready manner.

---

## Decision 1: Reuse Existing Admin HTTPS Port (9443)

### Status: ✅ ACCEPTED

**Initial Approach**: Create new `tfe_admin_console_port` variable with default 9200.

**Decision**: Reuse existing `tfe_admin_https_port` variable (default 9443) instead of creating a new port variable.

### Rationale
1. **Port 9443 already exists** for TFE Admin API endpoints
2. **Admin Console is part of Admin API** system architecturally
3. **Reduces configuration complexity** - one less variable
4. **Eliminates port conflicts** - no need for complex validation
5. **Existing port mappings** in Docker/Podman already present

### Consequences
- ✅ Simpler configuration (fewer variables)
- ✅ Consistent with TFE architecture
- ✅ Reuses existing security group infrastructure
- ✅ No port conflict validation needed
- ⚠️ Admin Console and Admin API share the same port (intended behavior)

### Implementation
```hcl
# Before (rejected)
variable "tfe_admin_console_port" {
  default = 9200
  # Complex validation rules...
}

# After (accepted)
# Reuses existing var.tfe_admin_https_port = 9443
```

---

## Decision 2: Remove Token Authentication Variables

### Status: ✅ ACCEPTED

**Initial Approach**: Add `tfe_admin_console_token_secret_arn` and `tfe_admin_console_token_timeout` variables with AWS Secrets Manager integration.

**Decision**: Remove all token-related variables and infrastructure.

### Rationale
1. **Token management is application concern**, not infrastructure
2. **TFE handles authentication internally** - no external token needed
3. **Adds unnecessary complexity** to the module
4. **No infrastructure changes needed** for token functionality
5. **Secrets Manager integration not required** for admin console

### Consequences
- ✅ Simpler module interface
- ✅ Clearer separation of concerns
- ✅ Less code to maintain
- ✅ No IAM permissions needed for Secrets Manager
- ✅ Reduced attack surface

### Implementation
```hcl
# Removed entirely
# - variable "tfe_admin_console_token_secret_arn"
# - variable "tfe_admin_console_token_timeout"
# - data "aws_secretsmanager_secret_version" "tfe_admin_console_token"
```

---

## Decision 3: Route Admin Console Through Load Balancer

### Status: ✅ ACCEPTED (Critical Addition)

**Initial Approach**: Only configure EC2 security groups for direct EC2 instance access.

**Discovery**: Admin console was not accessible through load balancer DNS because no load balancer infrastructure existed for port 9443.

**Decision**: Add full load balancer support including listeners, target groups, and security groups.

### Rationale
1. **Production deployments use load balancer DNS** - not EC2 IPs
2. **Consistent access pattern** with main TFE application
3. **Enables high availability** - traffic distributes across instances
4. **Centralized entry point** - single DNS name for all access
5. **Required for public deployments** - EC2 instances often not publicly accessible

### Consequences
- ✅ Admin console accessible via load balancer DNS
- ✅ High availability and failover
- ✅ Consistent with TFE main application access
- ✅ No need to know EC2 instance IPs
- ⚠️ Additional AWS resources created (listeners, target groups)
- ⚠️ Slightly increased complexity

### Implementation
```hcl
# Added for both NLB and ALB
resource "aws_lb_listener" "lb_nlb_admin_console" {
  port = var.tfe_admin_https_port  # 9443
  # Routes to target group
}

resource "aws_lb_target_group" "nlb_admin_console" {
  port = var.tfe_admin_https_port  # 9443
  # Health checks on port 443 (see Decision 4)
}
```

---

## Decision 4: Health Checks on Port 443, Traffic on Port 9443

### Status: ✅ ACCEPTED (Critical Fix)

**Initial Approach**: Configure health checks on port 9443 (traffic port).

**Discovery**: Health checks were failing because `/_health_check` endpoint doesn't exist on port 9443.

**Decision**: Configure health checks to use port 443 while traffic routes to port 9443.

### Rationale
1. **`/_health_check` only exists on port 443** (main application port)
2. **Port 9443 is admin console only** - no health endpoint
3. **Instance health reflects TFE availability** - port 443 is authoritative
4. **Separate health check port is supported** by AWS target groups
5. **Prevents false negatives** - instances marked healthy when TFE running

### Consequences
- ✅ Health checks pass correctly
- ✅ Traffic only sent to healthy instances
- ✅ Accurate health status in AWS Console
- ⚠️ Health check port differs from traffic port (expected)
- ℹ️ Admin console availability tied to main TFE health

### Implementation
```hcl
resource "aws_lb_target_group" "nlb_admin_console" {
  port = var.tfe_admin_https_port  # 9443 - traffic port
  
  health_check {
    port = "443"  # Health check on different port
    path = "/_health_check"
  }
}
```

---

## Decision 5: No Example Directories

### Status: ✅ ACCEPTED

**Initial Approach**: Create `examples/admin-console-enabled/` directory with sample code.

**Decision**: Skip example directory creation per user request.

### Rationale
1. **User explicitly requested** no example folders
2. **Simple configuration** - only 2 variables needed
3. **Main example already exists** in `examples/main/`
4. **Documentation sufficient** for this feature
5. **Reduces repository size**

### Consequences
- ✅ Cleaner repository structure
- ✅ Less maintenance overhead
- ⚠️ Users must add configuration to existing examples
- ℹ️ Documentation provides configuration guidance

---

## Decision 6: Bidirectional Security Group Rules

### Status: ✅ ACCEPTED

**Initial Approach**: Only ingress rules on EC2 instances.

**Discovery**: Instances couldn't respond to admin console requests without egress rules.

**Decision**: Add explicit egress rules for admin console port.

### Rationale
1. **Bidirectional traffic required** for request/response
2. **Explicit egress more secure** than allow-all
3. **Consistent with existing pattern** (443 has ingress+egress)
4. **Required for proxy scenarios**
5. **Prevents mysterious connection failures**

### Consequences
- ✅ Admin console responses allowed
- ✅ Explicit control over egress traffic
- ✅ Proxy scenarios supported
- ⚠️ Additional security group rules created

### Implementation
```hcl
# EC2 ingress (from CIDR to EC2)
resource "aws_security_group_rule" "ec2_allow_ingress_tfe_admin_console" {
  from_port   = var.tfe_admin_https_port
  to_port     = var.tfe_admin_https_port
  cidr_blocks = var.cidr_allow_ingress_tfe_admin_console
}

# EC2 egress (from EC2 to CIDR) - ADDED
resource "aws_security_group_rule" "ec2_allow_egress_tfe_admin_console" {
  from_port   = var.tfe_admin_https_port
  to_port     = var.tfe_admin_https_port
  cidr_blocks = var.cidr_allow_egress_ec2_http
}
```

---

## Decision 7: Pre-commit Hook for Variables Consistency

### Status: ✅ ACCEPTED

**Motivation**: Need to track when root `variables.tf` diverges from example variables.

**Decision**: Create pre-commit hook that shows git diff between root and example variables.

### Rationale
1. **Visibility** of variable drift between root and examples
2. **Non-blocking** - informational only, doesn't prevent commits
3. **Automatic** - runs on every variables.tf change
4. **Actionable** - shows exact differences to review

### Consequences
- ✅ Developers aware of variable inconsistencies
- ✅ Reduces accidental drift
- ✅ Non-intrusive (doesn't block work)
- ⚠️ Requires `GIT_PAGER=cat` to prevent hanging
- ℹ️ Developer decides if changes needed

### Implementation
```bash
# .github/scripts/pre_commit_hooks/check_variables_consistency.sh
export GIT_PAGER=cat  # Critical - prevents hanging
git diff --no-index ./variables.tf examples/*/variables.tf
```

---

## Decision 8: Support Both NLB and ALB

### Status: ✅ ACCEPTED

**Approach**: Implement admin console support for both load balancer types.

**Decision**: Add conditional resources for both NLB and ALB configurations.

### Rationale
1. **Module supports both** load balancer types already
2. **Users may use either** NLB or ALB
3. **Implementation similar** for both types
4. **Conditional creation** - only creates needed resources
5. **Future-proof** - works in both scenarios

### Consequences
- ✅ Works with NLB deployments
- ✅ Works with ALB deployments
- ✅ Consistent user experience
- ⚠️ More code (2x resources)
- ℹ️ Only one set created per deployment

### Implementation
```hcl
# NLB resources
resource "aws_lb_listener" "lb_nlb_admin_console" {
  count = var.lb_type == "nlb" && var.tfe_admin_console_enabled ? 1 : 0
  # ...
}

# ALB resources
resource "aws_lb_listener" "alb_admin_console" {
  count = var.lb_type == "alb" && var.tfe_admin_console_enabled ? 1 : 0
  # ...
}
```

---

## Decision 9: Disabled by Default with Required CIDR

### Status: ✅ ACCEPTED

**Approach**: Security-first configuration model.

**Decision**: Admin console disabled by default, CIDR ranges required when enabled.

### Rationale
1. **Security first** - opt-in model
2. **No default open access** - prevents accidental exposure
3. **Explicit configuration required** - forces conscious decision
4. **Validation enforces security** - can't enable without CIDR
5. **Backward compatible** - existing deployments unchanged

### Consequences
- ✅ Secure by default
- ✅ No accidental exposure
- ✅ Explicit security decision required
- ✅ Backward compatible
- ⚠️ Users must configure CIDRs (intentional friction)

### Implementation
```hcl
variable "tfe_admin_console_enabled" {
  default = false  # Disabled by default
}

variable "cidr_allow_ingress_tfe_admin_console" {
  default = null  # Required when enabled
  
  validation {
    condition     = var.tfe_admin_console_enabled ? var.cidr_allow_ingress_tfe_admin_console != null : true
    error_message = "CIDR ranges required when admin console enabled."
  }
}
```

---

## Summary of Decisions

| Decision | Impact | Status |
|----------|--------|--------|
| Reuse port 9443 | Simplified | ✅ Accepted |
| Remove token auth | Reduced complexity | ✅ Accepted |
| Add LB support | Production ready | ✅ Accepted |
| Health checks on 443 | Critical fix | ✅ Accepted |
| No examples | Cleaner repo | ✅ Accepted |
| Bidirectional rules | Complete networking | ✅ Accepted |
| Pre-commit hook | Better DX | ✅ Accepted |
| Support NLB+ALB | Comprehensive | ✅ Accepted |
| Security first | Safe defaults | ✅ Accepted |

---

## Trade-offs Analysis

### Simplicity vs Features
- **Chose**: Simplicity
- **Removed**: Token auth, custom port, examples
- **Result**: Minimal 2-variable configuration

### Direct Access vs Load Balancer
- **Chose**: Load Balancer (production pattern)
- **Added**: Listeners, target groups, security rules
- **Result**: Production-ready, HA-capable

### Health Check Accuracy vs Simplicity
- **Chose**: Accuracy
- **Added**: Separate health check port configuration
- **Result**: Reliable health checks

### Security vs Convenience
- **Chose**: Security
- **Enforced**: Disabled by default, CIDR required
- **Result**: Safe defaults, explicit configuration

---

## Lessons for Future Features

1. **Start simple** - Add complexity only when needed
2. **Reuse existing infrastructure** before creating new
3. **Load balancer support is critical** for production features
4. **Health check endpoints matter** - verify they exist
5. **Separate infrastructure from application concerns**
6. **Security first** - disabled by default, explicit configuration
7. **Test with actual deployment** - don't assume EC2 access works
8. **Document as you go** - capture decisions and rationale
9. **Egress rules often forgotten** - remember bidirectional traffic
10. **Pre-commit hooks need non-interactive mode**

---

## References

- **Implementation**: `ACTUAL_IMPLEMENTATION.md`
- **Specification**: `spec.md`
- **Plan**: `plan.md`
- **Git History**: `git log 001-admin-console`
- **HashiCorp Docs**: https://developer.hashicorp.com/terraform/enterprise/deploy/configuration/admin-console
