# Implementation Plan: Terraform Enterprise Admin Console Configuration Support

**Branch**: `001-admin-console` | **Date**: 2025-12-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-admin-console/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature adds support for the Terraform Enterprise Admin Console configuration to the terraform-aws-terraform-enterprise-hvd module. The Admin Console is a TFE administrative interface that allows operators to configure system settings without modifying deployment infrastructure. The implementation will introduce new Terraform variables for admin console configuration (enabled status, port, CIDR access controls, authentication settings), integrate these settings into the existing user_data template system, configure appropriate AWS security group rules, and ensure backward compatibility with existing deployments.

## Technical Context

**Language/Version**: HCL (Terraform) ~> 1.9, AWS Provider ~> 5.0  
**Primary Dependencies**: 
- AWS Provider (security groups, EC2, load balancers)
- Terraform Enterprise container (TFE_ADMIN_CONSOLE_* environment variables)
- Cloud-init / user_data templating system
- Docker/Podman container runtime

**Storage**: AWS Secrets Manager (optional, for admin console token storage)  
**Testing**: Terraform validate, terraform plan, integration testing via Terratest (existing test framework in tests/)  
**Target Platform**: AWS (Amazon Linux 2023, Ubuntu, RHEL, CentOS)  
**Project Type**: Infrastructure as Code (Terraform Module)  
**Performance Goals**: 
- Admin console must be accessible within 5 minutes of instance launch
- No impact to TFE application performance
- Port configuration validation at plan time

**Constraints**: 
- Must maintain backward compatibility (default disabled)
- Admin console port must not conflict with TFE HTTP (8080), HTTPS (8443), metrics (9090/9091), or admin HTTPS (9443) ports
- Must work with both ALB and NLB load balancer configurations
- Must support both active-active and external operational modes
- Security group rules must restrict access to specified CIDR ranges only

**Scale/Scope**: 
- Single new feature in existing production-grade Terraform module
- ~200 lines of new HCL code (variables, security groups, user_data integration)
- 4-6 new input variables
- 2-3 new output values
- Updates to existing user_data template

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This is an infrastructure module project and the Terraform AI-Assisted Development Constitution applies. Key compliance points:

### ✅ PASSING GATES

1. **Module-First Architecture** (§1.1): ✅ COMPLIANT
   - This IS a module being enhanced, not consuming modules
   - Changes are to an existing production module, not creating raw resources

2. **Specification-Driven Development** (§1.2): ✅ COMPLIANT
   - Detailed specification exists in spec.md with clear requirements
   - All acceptance scenarios are defined and testable
   - Edge cases documented

3. **Security-First Automation** (§1.3): ✅ COMPLIANT
   - Admin console authentication token stored in AWS Secrets Manager (optional)
   - Security groups restrict access by CIDR ranges (least privilege)
   - Default configuration is secure (disabled by default, no public access)
   - Token generation uses secure random values when not provided

4. **Code Generation Standards** (§III): ✅ COMPLIANT
   - Repository structure matches existing module pattern
   - Variables will include descriptions, types, validation rules
   - Naming follows HashiCorp standards
   - Changes are additive, maintaining backward compatibility

5. **Security Best Practices** (§3.2, §3.4): ✅ COMPLIANT
   - Least privilege by default (admin console disabled, no default CIDR access)
   - Security group rules deny by default, explicit allow only
   - Sensitive variables marked appropriately
   - No static credentials in code

6. **Testing Requirements** (§5.3): ✅ COMPLIANT
   - Existing test framework will be extended
   - Plan-time validation for port conflicts
   - Integration tests for access control

### ⚠️ ITEMS REQUIRING ATTENTION

1. **Documentation Requirements** (§5.1): WILL BE ADDRESSED
   - README.md will be updated with new variables documentation
   - Examples will be provided for admin console configuration
   - Terraform-docs will auto-generate variable reference

2. **Backward Compatibility**: CRITICAL SUCCESS FACTOR
   - All new variables must have secure defaults (disabled/null)
   - Existing deployments must work without changes
   - No breaking changes to existing functionality

### 📋 CONSTITUTION COMPLIANCE SUMMARY

- **Module Type**: Infrastructure module (not application consumption)
- **Breaking Changes**: None - all changes are additive
- **Security Impact**: Positive - adds opt-in administrative access controls
- **Compliance Status**: ✅ All applicable gates passing

## Project Structure

### Documentation (this feature)

```text
specs/001-admin-console/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - Admin console TFE docs, port selection, security patterns
├── data-model.md        # Phase 1 output - Admin console configuration data model
├── quickstart.md        # Phase 1 output - Quick start guide for operators
└── contracts/           # Phase 1 output - Variable contracts, security group rules schema
```

### Source Code (repository root)

```text
# Terraform module structure (existing)
/
├── variables.tf         # NEW: Admin console variables (tfe_admin_console_*)
├── compute.tf           # MODIFIED: Security group rules for admin console port
├── load_balancer.tf     # NO CHANGES: Admin console bypasses LB (direct EC2 access)
├── outputs.tf           # NEW: Admin console outputs (port, access pattern)
├── templates/
│   └── tfe_user_data.sh.tpl  # MODIFIED: Add admin console environment variables
├── examples/
│   └── admin-console-enabled/  # NEW: Example configuration
│       ├── main.tf
│       ├── variables.tf
│       └── README.md
├── tests/
│   └── admin_console_test.go   # NEW: Integration tests
└── README.md            # MODIFIED: Document new admin console variables

# Files NOT modified (no admin console impact)
├── data.tf             # No changes needed
├── iam.tf              # No changes needed (existing instance profile sufficient)
├── rds_aurora.tf       # No changes needed
├── redis.tf            # No changes needed
├── route53.tf          # No changes needed
├── s3.tf               # No changes needed
└── versions.tf         # No changes needed
```

**Structure Decision**: Single Terraform module structure (existing pattern maintained). Admin console is a cross-cutting configuration feature that touches variables (new), compute (security groups), templates (user_data), outputs (new), and testing. This follows the existing module organization where features are integrated across multiple files by functional area rather than creating feature-specific modules.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No complexity violations.** This feature introduces no architectural complexity beyond standard Terraform module patterns:

- Variables, security groups, outputs follow existing module conventions
- User data template modification follows established pattern
- No new dependencies or infrastructure components
- No deviation from HashiCorp best practices

All changes are additive and maintain backward compatibility.

## Phase 0: Research & Design Decisions

### Research Topics

1. **TFE Admin Console Documentation Analysis**
   - Review HashiCorp documentation: https://developer.hashicorp.com/terraform/enterprise/deploy/configuration/admin-console
   - Identify required environment variables (TFE_ADMIN_CONSOLE_*)
   - Understand authentication mechanisms and token requirements
   - Document configuration format and validation requirements

2. **Port Selection Strategy**
   - Default port recommendation (avoid conflicts with 8080, 8443, 9090, 9091, 9443)
   - Research common port ranges for administrative interfaces (9000-9999)
   - Document port conflict validation approach
   - Consider Podman vs Docker port requirements

3. **Security Group Best Practices**
   - AWS security group rule patterns for administrative access
   - CIDR-based access control implementation
   - IPv4 and IPv6 support considerations
   - Security group rule ordering and precedence

4. **User Data Template Integration**
   - Existing template variable injection patterns
   - Environment variable naming conventions for TFE
   - Container runtime (Docker/Podman) port mapping syntax
   - Conditional configuration based on feature enablement

5. **Backward Compatibility Strategy**
   - Variable default value patterns ensuring no-op behavior
   - Existing deployment upgrade path validation
   - Testing approach for "no changes" scenario
   - Documentation of migration path

### Key Design Decisions (to be documented in research.md)

- **Default Port**: Recommend 9200 (avoids all existing TFE ports, in common admin range)
- **Authentication**: Support both provided tokens and system-generated tokens
- **Access Control**: CIDR-based, default to null (no access) for security
- **IPv6 Support**: Follow existing `tfe_ipv6_enabled` pattern
- **Token Storage**: Optional AWS Secrets Manager integration
- **Container Runtime**: Support both Docker and Podman port mapping

## Phase 1: Architecture & Implementation Design

### 1. Variables Design (variables.tf)

**New Variables to Add:**

```hcl
variable "tfe_admin_console_enabled" {
  type        = bool
  description = "Boolean to enable the TFE Admin Console feature. When enabled, the admin console provides administrative access to TFE system settings."
  default     = false
}

variable "tfe_admin_console_port" {
  type        = number
  description = "Port the TFE Admin Console listens on for HTTPS traffic. This value is used for both the host and container port. Must not conflict with tfe_http_port, tfe_https_port, tfe_metrics_http_port, tfe_metrics_https_port, or tfe_admin_https_port."
  default     = 9200

  validation {
    condition = var.tfe_admin_console_port != var.tfe_http_port && 
                var.tfe_admin_console_port != var.tfe_https_port && 
                var.tfe_admin_console_port != var.tfe_metrics_http_port && 
                var.tfe_admin_console_port != var.tfe_metrics_https_port &&
                var.tfe_admin_console_port != var.tfe_admin_https_port
    error_message = "`tfe_admin_console_port` must not conflict with tfe_http_port, tfe_https_port, tfe_metrics_http_port, tfe_metrics_https_port, or tfe_admin_https_port."
  }

  validation {
    condition     = var.tfe_admin_console_port >= 1024 && var.tfe_admin_console_port <= 65535
    error_message = "Value must be between 1024 and 65535."
  }
}

variable "cidr_allow_ingress_tfe_admin_console" {
  type        = list(string)
  description = "List of CIDR ranges to allow TCP ingress to the TFE Admin Console port. Leave as null to disable admin console network access (most secure). Use with caution in production."
  default     = null

  validation {
    condition = var.tfe_admin_console_enabled && var.cidr_allow_ingress_tfe_admin_console == null ? false : true
    error_message = "Value must be set when `tfe_admin_console_enabled` is `true`. Set to specific CIDR ranges for access control."
  }
}

variable "tfe_admin_console_token_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret containing the TFE Admin Console authentication token. Leave as null for TFE to generate a random token. Secret type should be plaintext. Token must be a secure random string."
  default     = null
}

variable "tfe_admin_console_token_timeout" {
  type        = number
  description = "Number of minutes before the admin console authentication token expires and requires re-authentication. Default is 60 minutes."
  default     = 60

  validation {
    condition     = var.tfe_admin_console_token_timeout >= 5 && var.tfe_admin_console_token_timeout <= 1440
    error_message = "Value must be between 5 and 1440 (24 hours)."
  }
}
```

### 2. Security Groups Updates (compute.tf)

**New Security Group Rules:**

```hcl
# Add to compute.tf after existing security group rules

resource "aws_security_group_rule" "ec2_allow_ingress_tfe_admin_console" {
  count = var.tfe_admin_console_enabled && var.cidr_allow_ingress_tfe_admin_console != null ? 1 : 0

  type        = "ingress"
  from_port   = var.tfe_admin_console_port
  to_port     = var.tfe_admin_console_port
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_admin_console
  description = "Allow TCP/${var.tfe_admin_console_port} (Admin Console) inbound to TFE EC2 instances from specified CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

# IPv6 support (if enabled)
resource "aws_security_group_rule" "ec2_allow_ingress_tfe_admin_console_ipv6" {
  count = var.tfe_admin_console_enabled && var.cidr_allow_ingress_tfe_admin_console != null && var.tfe_ipv6_enabled ? 1 : 0

  type             = "ingress"
  from_port        = var.tfe_admin_console_port
  to_port          = var.tfe_admin_console_port
  protocol         = "tcp"
  ipv6_cidr_blocks = var.cidr_allow_ingress_tfe_admin_console  # Assumes IPv6 CIDRs provided if ipv6 enabled
  description      = "Allow TCP/${var.tfe_admin_console_port} (Admin Console) inbound to TFE EC2 instances from specified IPv6 CIDR ranges."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}
```

### 3. User Data Template Updates (templates/tfe_user_data.sh.tpl)

**Additions to user_data_args in compute.tf locals:**

```hcl
# Add to local.user_data_args in compute.tf
    # Admin Console settings
    tfe_admin_console_enabled      = var.tfe_admin_console_enabled
    tfe_admin_console_port         = var.tfe_admin_console_port
    tfe_admin_console_token        = var.tfe_admin_console_enabled && var.tfe_admin_console_token_secret_arn != null ? data.aws_secretsmanager_secret_version.tfe_admin_console_token[0].secret_string : ""
    tfe_admin_console_token_timeout = var.tfe_admin_console_token_timeout
```

**Data source for token retrieval:**

```hcl
# Add to compute.tf data sources section
data "aws_secretsmanager_secret" "tfe_admin_console_token" {
  count = var.tfe_admin_console_enabled && var.tfe_admin_console_token_secret_arn != null ? 1 : 0
  arn   = var.tfe_admin_console_token_secret_arn
}

data "aws_secretsmanager_secret_version" "tfe_admin_console_token" {
  count     = var.tfe_admin_console_enabled && var.tfe_admin_console_token_secret_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.tfe_admin_console_token[0].id
}
```

**Template additions (tfe_user_data.sh.tpl):**

The template generates Docker Compose and Podman manifest configuration files, not shell exports.

**For Docker Compose (function generate_tfe_docker_compose_config):**

Add to environment section (location: after TFE_ADMIN_HTTPS_PORT, line ~291):

```yaml
%{ if tfe_admin_console_enabled ~}
      # Admin Console settings
      TFE_ADMIN_CONSOLE_ENABLED: "true"
      TFE_ADMIN_CONSOLE_PORT: ${tfe_admin_console_port}
%{ if tfe_admin_console_token != "" ~}
      TFE_ADMIN_CONSOLE_TOKEN: ${tfe_admin_console_token}
%{ endif ~}
      TFE_ADMIN_CONSOLE_TOKEN_TIMEOUT: ${tfe_admin_console_token_timeout}
%{ endif ~}
```

Add to ports section (location: after metrics ports, line ~314):

```yaml
%{ if tfe_admin_console_enabled ~}
      - ${tfe_admin_console_port}:${tfe_admin_console_port}
%{ endif ~}
```

**For Podman manifest (function generate_tfe_podman_manifest):**

Add to env list (location: after TFE_ADMIN_HTTPS_PORT, line ~500):

```yaml
%{ if tfe_admin_console_enabled ~}
    # Admin Console settings
    - name: "TFE_ADMIN_CONSOLE_ENABLED"
      value: "true"
    - name: "TFE_ADMIN_CONSOLE_PORT"
      value: ${tfe_admin_console_port}
%{ if tfe_admin_console_token != "" ~}
    - name: "TFE_ADMIN_CONSOLE_TOKEN"
      value: ${tfe_admin_console_token}
%{ endif ~}
    - name: "TFE_ADMIN_CONSOLE_TOKEN_TIMEOUT"
      value: ${tfe_admin_console_token_timeout}
%{ endif ~}
```

Add to ports list (location: after metrics ports, line ~520):

```yaml
%{ if tfe_admin_console_enabled ~}
    - containerPort: ${tfe_admin_console_port}
      hostPort: ${tfe_admin_console_port}
%{ endif ~}
```

### 4. Outputs Updates (outputs.tf)

**New Outputs:**

```hcl
output "tfe_admin_console_enabled" {
  value       = var.tfe_admin_console_enabled
  description = "Boolean indicating if TFE Admin Console is enabled."
}

output "tfe_admin_console_port" {
  value       = var.tfe_admin_console_enabled ? var.tfe_admin_console_port : null
  description = "Port the TFE Admin Console listens on, or null if disabled."
}

output "tfe_admin_console_url_pattern" {
  value       = var.tfe_admin_console_enabled ? "https://<TFE_EC2_INSTANCE_IP>:${var.tfe_admin_console_port}" : null
  description = "URL pattern for accessing the TFE Admin Console. Replace <TFE_EC2_INSTANCE_IP> with the actual EC2 instance private IP address."
}
```

### 5. IAM Permissions

**Analysis**: No new IAM permissions required. Existing TFE instance profile has:
- Secrets Manager read access (already used for TFE license, TLS certs, database password)
- This is sufficient for retrieving admin console token from Secrets Manager

**No changes needed to iam.tf**

### 6. Load Balancer Configuration

**Decision**: Admin console does NOT go through the load balancer.
- Admin console is for direct administrative access to specific TFE instances
- Accessed via EC2 instance private IP, not load balancer DNS
- Similar pattern to SSH access and metrics endpoints

**No changes needed to load_balancer.tf**

### 7. Testing Strategy

**Unit Tests (Terraform validate/plan):**
- Port conflict validation at plan time
- Variable validation rules enforce constraints
- CIDR format validation

**Integration Tests (tests/admin_console_test.go):**
```go
// Test scenarios:
// 1. Admin console disabled (default) - verify no security group rules created
// 2. Admin console enabled with CIDR - verify security group rule exists
// 3. Port conflict detection - verify validation error
// 4. Token from Secrets Manager - verify data source created
// 5. IPv6 enabled - verify IPv6 security group rule
```

**Manual Testing Checklist:**
- Deploy with admin console disabled (default) - verify no changes to existing behavior
- Deploy with admin console enabled - verify port accessible from allowed CIDR
- Deploy with admin console enabled - verify port blocked from non-allowed CIDR
- Verify admin console authentication with provided token
- Verify admin console authentication with system-generated token
- Test in both active-active and external operational modes
- Test with both ALB and NLB configurations
- Test upgrade path from existing deployment

### 8. Documentation Updates

**README.md sections to add:**

1. **Admin Console Configuration** (new section)
   - Overview of admin console feature
   - Security considerations
   - Configuration examples

2. **Variables Reference** (auto-generated by terraform-docs)
   - New admin console variables will be automatically documented

3. **Examples** (new directory: examples/admin-console-enabled/)
   - Basic admin console configuration
   - Secure admin console with restricted CIDR
   - Admin console with custom token from Secrets Manager

**docs/ updates:**
- Add admin console configuration guide
- Security best practices for admin console access
- Troubleshooting guide

### 9. Edge Cases & Error Handling

**Port Conflicts:**
- Validation rules prevent conflicts at plan time
- Error messages clearly identify conflicting ports

**Missing CIDR when enabled:**
- Validation requires CIDR when admin console enabled
- Forces explicit security decision

**Secondary Region Deployments:**
- Admin console configuration replicated to secondary region
- Each region has independent admin console access
- No special handling needed (follows TFE instance pattern)

**Operational Mode Changes:**
- Admin console works in both external and active-active modes
- Each TFE instance has its own admin console endpoint
- No dependencies on operational mode

**Proxy Configuration:**
- Admin console does not use HTTP/HTTPS proxy settings
- Direct access only (administrative interface)
- Documented in security considerations

**Container Runtime (Docker vs Podman):**
- Port mapping syntax compatible with both
- No special handling needed
- Existing template patterns support both runtimes

### 10. Migration & Rollback

**Upgrade Path:**
- Existing deployments: No changes required
- New variable defaults ensure no-op behavior
- Can enable admin console via standard Terraform apply
- No instance replacement required

**Rollback:**
- Disable by setting `tfe_admin_console_enabled = false`
- Security group rules automatically removed
- No data loss or TFE disruption
- Container restarts with updated configuration

**Breaking Changes:**
- None - all changes are additive
- Backward compatible with existing configurations

## Phase 2: Implementation Checklist

**Variables (variables.tf):**
- [ ] Add `tfe_admin_console_enabled` variable with validation
- [ ] Add `tfe_admin_console_port` variable with port conflict validation
- [ ] Add `cidr_allow_ingress_tfe_admin_console` variable with CIDR validation
- [ ] Add `tfe_admin_console_token_secret_arn` variable
- [ ] Add `tfe_admin_console_token_timeout` variable with range validation

**Security Groups (compute.tf):**
- [ ] Add security group rule for admin console ingress (IPv4)
- [ ] Add security group rule for admin console ingress (IPv6, conditional)
- [ ] Add data source for admin console token from Secrets Manager
- [ ] Update user_data_args local with admin console variables

**User Data Template (templates/tfe_user_data.sh.tpl):**
- [ ] Add admin console environment variables to Docker Compose config (generate_tfe_docker_compose_config function)
- [ ] Add admin console port mapping to Docker Compose ports section
- [ ] Add admin console environment variables to Podman manifest (generate_tfe_podman_manifest function)
- [ ] Add admin console port mapping to Podman manifest ports section
- [ ] Test template rendering with admin console enabled (both Docker and Podman)
- [ ] Test template rendering with admin console disabled (both Docker and Podman)

**Outputs (outputs.tf):**
- [ ] Add `tfe_admin_console_enabled` output
- [ ] Add `tfe_admin_console_port` output
- [ ] Add `tfe_admin_console_url_pattern` output

**Examples (examples/):**
- [ ] Create `admin-console-enabled` example directory
- [ ] Add main.tf with admin console configuration
- [ ] Add variables.tf with example variable values
- [ ] Add README.md with usage instructions

**Tests (tests/):**
- [ ] Create admin_console_test.go
- [ ] Add test for default (disabled) configuration
- [ ] Add test for enabled configuration with CIDR
- [ ] Add test for port conflict validation
- [ ] Add test for token from Secrets Manager
- [ ] Add test for IPv6 configuration
- [ ] Run full test suite validation

**Documentation:**
- [ ] Update main README.md with admin console section
- [ ] Create admin console configuration guide in docs/
- [ ] Add security best practices documentation
- [ ] Add troubleshooting guide
- [ ] Update CHANGELOG.md
- [ ] Run terraform-docs to update variable reference

**Validation:**
- [ ] Run terraform fmt on all modified files
- [ ] Run terraform validate
- [ ] Test with example configurations
- [ ] Verify backward compatibility (no admin console variables)
- [ ] Test upgrade path from previous version
- [ ] Manual testing of admin console access
- [ ] Review all validation rules trigger correctly

## Success Criteria Validation

Mapping to spec.md success criteria:

- **SC-001**: Operators enable via single boolean + CIDR, accessible <5min ✅
- **SC-002**: Existing deployments upgrade without changes ✅ (default disabled)
- **SC-003**: Access restricted by security groups to specified CIDRs ✅
- **SC-004**: Changes applied via standard terraform apply, no replacement ✅
- **SC-005**: Port conflict validation at plan time ✅ (validation rules)
- **SC-006**: Comprehensive variable documentation via terraform-docs ✅
- **SC-007**: Works in both active-active and external modes ✅ (no mode dependency)
- **SC-008**: IPv6 support via conditional security group rule ✅
- **SC-009**: Token retrieval from Secrets Manager ✅ (data source)
- **SC-010**: All tests pass, no regressions ✅ (test suite extended)

## Risk Assessment

**Low Risk:**
- All changes are additive and optional
- Default behavior unchanged (backward compatible)
- Security groups are declarative (no runtime risk)
- User data template modifications are conditional
- No impact to existing TFE functionality

**Mitigation Strategies:**
- Comprehensive testing before release
- Clear documentation of security implications
- Example configurations for common scenarios
- Validation rules prevent misconfigurations

**Rollback Plan:**
- Disable via variable change, standard apply
- No data loss or permanent changes
- Security group rules automatically cleaned up

