# Feature Specification: Terraform Enterprise Admin Console Configuration Support

**Feature Branch**: `001-admin-console`  
**Created**: 2025-12-16  
**Status**: Draft  
**Input**: User description: "Update the terraform-aws-terraform-enterprise-hvd module to support the new Terraform Enterprise Admin Console configuration feature as documented at https://developer.hashicorp.com/terraform/enterprise/deploy/configuration/admin-console. Analyze the existing module structure and determine what updates are needed to: 1. Support Admin Console configuration parameters 2. Integrate with the existing user_data/cloud-init template system 3. Maintain backwards compatibility with existing deployments 4. Support the admin console settings in the Terraform Enterprise deployment"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable Admin Console Access (Priority: P1)

Platform operators need to enable the TFE Admin Console by setting configuration variables in their Terraform module to allow administrative access to TFE system settings without modifying deployment infrastructure.

**Why this priority**: This is the core capability - without the ability to enable the admin console, operators cannot access any admin console features. This is the foundation all other admin console functionality depends on.

**Independent Test**: Can be fully tested by deploying TFE with admin console enabled, verifying the admin console port is accessible, and confirming the admin console authentication endpoint responds correctly.

**Acceptance Scenarios**:

1. **Given** a TFE deployment using this module, **When** an operator sets the admin console enabled flag to true, **Then** the TFE instance launches with admin console listening on the configured port
2. **Given** admin console is enabled, **When** an administrator navigates to the admin console URL, **Then** they are presented with an authentication interface
3. **Given** a TFE deployment with admin console disabled (default), **When** the deployment completes, **Then** the admin console port is not exposed and admin console is not accessible

---

### User Story 2 - Configure Admin Console Network Access (Priority: P2)

Platform operators need to control which networks can access the admin console by specifying allowed CIDR ranges and configuring the admin console listening port to ensure secure administrative access.

**Why this priority**: Security configuration is critical but builds on the basic enable/disable functionality. Operators need this to safely expose the admin console in production environments.

**Independent Test**: Can be tested by deploying with specific CIDR ranges and port configurations, then verifying network access is restricted to specified ranges and the custom port is used if configured.

**Acceptance Scenarios**:

1. **Given** admin console is enabled with specific allowed CIDR ranges, **When** a connection attempt is made from an allowed IP, **Then** the connection is permitted to the admin console
2. **Given** admin console is enabled with specific allowed CIDR ranges, **When** a connection attempt is made from a non-allowed IP, **Then** the connection is blocked at the security group level
3. **Given** a custom admin console port is specified, **When** TFE is deployed, **Then** the admin console listens on the specified custom port instead of the default
4. **Given** IPv6 is enabled for TFE, **When** admin console is enabled, **Then** admin console accepts connections over both IPv4 and IPv6

---

### User Story 3 - Configure Admin Console Authentication (Priority: P2)

Platform operators need to configure authentication settings for the admin console, including the authentication token and token expiration, to control who can access administrative functions and for how long.

**Why this priority**: Authentication controls are essential for secure admin access but depend on the console being enabled first. This allows fine-grained security policy implementation.

**Independent Test**: Can be tested by providing a custom authentication token during deployment and verifying that only requests with the correct token can access admin console endpoints, and tokens expire as configured.

**Acceptance Scenarios**:

1. **Given** a custom admin authentication token is provided, **When** TFE is deployed, **Then** the admin console accepts authentication using the provided token
2. **Given** no custom token is provided, **When** TFE is deployed, **Then** the system generates a secure random token that can be retrieved from system logs or AWS Secrets Manager
3. **Given** an authentication token timeout is configured, **When** the timeout period elapses, **Then** the token becomes invalid and administrators must re-authenticate
4. **Given** admin console token is stored in AWS Secrets Manager, **When** an operator retrieves the token, **Then** they can use it to authenticate to the admin console

---

### User Story 4 - Maintain Backward Compatibility (Priority: P1)

Existing TFE deployments using this module must continue to work without modification when the module is upgraded, with admin console features being opt-in rather than enabled by default.

**Why this priority**: Breaking existing deployments would prevent adoption and violate infrastructure-as-code principles. This is critical for maintaining user trust and allowing safe upgrades.

**Independent Test**: Can be tested by deploying TFE with the updated module using existing variable configurations (without any admin console variables set), and verifying the deployment succeeds with no changes to running behavior.

**Acceptance Scenarios**:

1. **Given** an existing module configuration without admin console variables, **When** the module is upgraded to include admin console support, **Then** the deployment succeeds with no admin console features enabled
2. **Given** a TFE instance is running without admin console, **When** the infrastructure is updated to enable admin console, **Then** the change can be applied without requiring instance replacement
3. **Given** admin console variables use sensible defaults, **When** an operator enables admin console without specifying all optional parameters, **Then** the deployment succeeds using reasonable default values

---

### User Story 5 - Optional Load Balancer Integration for Admin Console (Priority: P3)

Platform operators may want to route admin console traffic through the existing load balancer instead of direct EC2 access to consolidate network entry points and leverage load balancer features like TLS termination and access logging.

**Why this priority**: This is an optional enhancement that provides architectural flexibility. Direct EC2 access remains the default and recommended approach for administrative interfaces, making this a nice-to-have rather than essential capability.

**Independent Test**: Can be tested by enabling admin console with LB routing option, deploying with both NLB and ALB configurations separately, and verifying admin console is accessible through the load balancer endpoint with proper health checks.

**Acceptance Scenarios**:

1. **Given** admin console is enabled with LB routing, **When** configured for NLB, **Then** a TCP listener on the admin console port forwards to an admin console target group
2. **Given** admin console is enabled with LB routing, **When** configured for ALB, **Then** an HTTPS listener on the admin console port forwards to an admin console target group
3. **Given** admin console LB routing is disabled (default), **When** deployed, **Then** admin console uses direct EC2 access pattern (current behavior)
4. **Given** admin console LB routing is enabled, **When** health checks are performed, **Then** the load balancer validates admin console endpoint availability

---

### Edge Cases

- What happens when admin console port conflicts with other configured ports (TFE HTTP, HTTPS, metrics ports)?
- How does the system handle admin console configuration when using Application Load Balancer vs Network Load Balancer?
- What happens when admin console is enabled but no CIDR ranges are specified for access control?
- How does the module handle admin console configuration in secondary regions for HA/DR deployments?
- What happens when an operator attempts to change the admin console port on an existing deployment?
- How does proxy configuration affect admin console access if HTTP/HTTPS proxy is configured?
- What happens when TFE operational mode changes between 'external' and 'active-active' with admin console enabled?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Module MUST provide a boolean variable to enable/disable the admin console feature with a default value of `false` to maintain backward compatibility
- **FR-002**: Module MUST provide a variable to specify the admin console listening port with a default value that does not conflict with existing TFE ports
- **FR-003**: Module MUST provide a variable to specify allowed CIDR ranges for admin console access with a default value of `null` (no access by default)
- **FR-004**: Module MUST validate that the admin console port does not conflict with TFE HTTP port, HTTPS port, or metrics ports
- **FR-005**: Module MUST integrate admin console configuration variables into the user_data/cloud-init template system
- **FR-006**: Module MUST configure appropriate AWS security group rules to allow admin console traffic from specified CIDR ranges when enabled
- **FR-007**: Module MUST pass admin console configuration to the TFE container through environment variables in the user_data script
- **FR-008**: Module MUST support admin console port mapping in the container runtime configuration (both Docker and Podman)
- **FR-009**: Module MUST provide a variable for admin console authentication token with a default of `null` to allow system-generated tokens
- **FR-010**: Module MUST provide a variable for admin console token timeout/expiration with a sensible default (e.g., 60 minutes)
- **FR-011**: Module MUST allow storing the admin console token in AWS Secrets Manager if provided
- **FR-012**: Module MUST document all new admin console configuration variables with descriptions, types, defaults, and constraints
- **FR-013**: Module MUST support IPv6 for admin console when `tfe_ipv6_enabled` is true
- **FR-014**: Module MUST work with both Application Load Balancer (ALB) and Network Load Balancer (NLB) configurations when admin console is enabled
- **FR-015**: Module MUST support admin console in both `active-active` and `external` operational modes
- **FR-016**: Module MUST handle admin console configuration in secondary region deployments for HA/DR scenarios
- **FR-017**: Module MUST add admin console configuration to outputs to provide necessary information for operators (port, access URL pattern)
- **FR-018**: Module SHOULD optionally support routing admin console traffic through the load balancer as an alternative to direct EC2 access for enhanced security and simplified network architecture (Note: Direct EC2 access remains the default and recommended approach)

### Key Entities

- **Admin Console Configuration**: A set of configuration parameters including enabled status, listening port, allowed CIDR ranges, authentication token, and token expiration that control the TFE Admin Console feature
- **Security Group Rules**: AWS VPC security group rules that control network access to the admin console port from specified CIDR ranges
- **Container Port Mapping**: Configuration that maps the host admin console port to the TFE container's internal admin console port for both Docker and Podman runtimes
- **Admin Console Credentials**: Authentication token and related settings that control access to admin console endpoints, optionally stored in AWS Secrets Manager

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operators can enable admin console by setting a single boolean variable and deploying, with admin console becoming accessible within 5 minutes
- **SC-002**: Existing TFE deployments can upgrade to the new module version without any configuration changes and continue operating without admin console features
- **SC-003**: Admin console access is successfully restricted to specified CIDR ranges with unauthorized access attempts blocked at the network layer
- **SC-004**: Admin console configuration changes can be applied to existing deployments through a standard Terraform apply operation without instance replacement
- **SC-005**: Module validation catches port conflicts at plan time before deployment, preventing invalid configurations
- **SC-006**: All admin console variables have comprehensive documentation with examples that allow operators to configure the feature in under 10 minutes
- **SC-007**: Admin console works correctly in both active-active and external operational modes with no degradation in TFE functionality
- **SC-008**: Admin console is accessible via both IPv4 and IPv6 when IPv6 is enabled for TFE
- **SC-009**: Admin console authentication token can be securely retrieved from AWS Secrets Manager when configured to be stored there
- **SC-010**: Module passes all existing tests plus new admin console-specific tests without introducing regressions

## Assumptions

- The TFE image version specified in the module already includes admin console functionality (available in recent TFE versions)
- The HashiCorp documentation at the provided URL accurately describes the admin console configuration requirements
- Admin console configuration follows standard TFE environment variable patterns similar to other TFE features
- Operators deploying this module have appropriate AWS IAM permissions to create security group rules and manage secrets
- The admin console is primarily accessed by platform operators, not end users of TFE
- Admin console traffic does not need to go through the TFE load balancer (direct access to EC2 instances is acceptable)
- Admin console authentication uses token-based auth rather than integrating with TFE's user authentication system
- Default admin console port can be selected that does not conflict with commonly used ports in the 9000-9999 range
- Admin console configuration can be updated without requiring TFE instance recreation (changes can be applied via user_data script updates)

## Dependencies

- Requires TFE container image that supports admin console feature (specific version TBD based on HashiCorp documentation)
- Depends on existing user_data template system to inject admin console configuration
- Depends on existing security group infrastructure to add admin console ingress rules
- Depends on existing container runtime configuration (Docker/Podman) to add admin console port mapping
- May depend on AWS Secrets Manager for secure token storage (optional dependency)
- Requires understanding of TFE's admin console environment variables and configuration format from HashiCorp documentation

## Out of Scope

- Automatic rotation of admin console authentication tokens
- Integration of admin console authentication with TFE's SAML/OIDC providers
- Custom TLS certificate configuration specifically for admin console (uses TFE's TLS configuration)
- Admin console high availability configuration (follows TFE's HA configuration)
- Admin console-specific monitoring or alerting beyond standard TFE metrics
- Custom admin console UI or API modifications
- Admin console backup and restore functionality
- Multi-region admin console failover automation
