# Terraform AI-Assisted Development Constitution

**Organization**: Hashicorp
**Version**: 1.0.0
**Effective Date**: October 2025
**Purpose**: Governing principles for AI-assisted Terraform code generation for application teams consuming infrastructure services

---

## I. Foundational Principles

### 1.1 Module-First Architecture

**Principle**: All infrastructure MUST be provisioned through approved modules from the Private Module Registry.

**Rationale**: Direct resource declarations bypass organizational standards, security controls, and governance policies. The platform team has invested significant effort in creating secure, compliant, and tested modules.

**Implementation**:

- You MUST search and prioritize existing modules from `https://registry.terraform.io`
-
- **Module Source Requirement**: The `source` attribute for all modules SHOULD e pubic to guarantee reusability
  - Example:

    ```hcl
    module "example" {
      source  = "modulename/"
      version = "~> 1.0.0"
      # other inputs...
    }
    ```

  - You SHOULD use public registry sources or shortcuts (e.g., `hashicorp/` or `terraform-aws-modules/`) for module consumption.
  - This ensures modules are vetted, compliant, and maintained by the platform team.
- If a required module doesn't exist, you MUST surface this gap to the user and platform team rather than improvising with raw resources
- Module consumption MUST follow semantic versioning constraints (e.g., `version = "~> 2.1.0"`)

### 1.2 Specification-Driven Development

**Principle**: Infrastructure code generation MUST be driven by explicit specifications, not implicit assumptions.

**Rationale**: "Vibe-coding" leads to inconsistent implementations, security gaps, and maintenance nightmares. Specifications create auditable decision trails.

**Implementation**:

- You MUST request clarification on ambiguous requirements before generating code
- Generated code MUST include comments referencing the specification requirements it implements
- Infrastructure specifications MUST define: purpose, compliance requirements, scalability needs, and cost constraints
- You MUST validate specifications against organizational constraints before code generation

### 1.3 Security-First Automation

**Principle**: Generated code MUST assume zero trust and implement security controls by default.

**Rationale**: AI-generated infrastructure code requires secure patterns for handling sensitive data, as AI can inadvertently introduce misconfigurations or overlook security best practices.

**Implementation**:

- You MUST never generate static, long-lived credentials in code or configuration
- All provider authentication MUST use short-lived dynamic credentials (workspace variable sets are pre-configured for this)
- You MUST use ephemeral resources for handling sensitive values instead of data sources or static secrets (see <https://developer.hashicorp.com/terraform/language/manage-sensitive-data/ephemeral>)
- You MUST include security context in code comments (e.g., "Using ephemeral resource to securely handle database password per ORG-SEC-001")

---

## II. HCP Terraform Prerequisites

### 2.1 Required Configuration Details

**Standard**: HCP Terraform configuration details MUST be determined from the current remote git repository or provided by user before any Terraform operations.

**Prerequisites**:

- HCP Terraform Organization Name
- HCP Terraform Project Name
- HCP Terraform Workspace Name for Dev environment

**Rules**:

- You MUST use Terraform MCP server tools to determine organization, project and dev workspace name based on the current remote git repository
- If multiple options exist or details cannot be determined automatically, you MUST prompt user to select/provide these configuration details
- You MUST always validate that these configuration details are available before invoking any tools provided by Terraform MCP server
- The Terraform MCP server MUST use the organization, project and workspace values for calling any tools
- Organization and project context MUST be validated before module registry access

**Implementation**:

- Configuration details MUST be automatically detected from the current git repository using Terraform MCP server tools
- When automatic detection is not possible or returns multiple options, you MUST present choices to the user for selection
- Missing prerequisites MUST be surfaced to the user with clear instructions and options
- All HCP Terraform API calls for ephemeral workspace or workspace variables related operations MUST use the specified organization, project and workspace context
- User-provided configuration details MUST be validated against available HCP Terraform resources before proceeding

---

## III. Code Generation Standards

### 3.1 Repository Structure

**Standard**: One application, one repository, git branch per environment.

**Structure**:

```bash
/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── locals.tf
├── README.md
└── .gitignore
```

**Git Branch Strategy**:

- `feature/*` branches → Development work (branched from `dev`)
- `dev` branch → Development environment
- `staging` branch → Staging environment
- `main` branch → Production environment

**Branch Protection Rules**:

- Direct commits to `dev`, `staging`, and `main` branches are PROHIBITED
- All changes MUST be made via feature branches off `dev`
- When creating a `feature/*` branch, make sure you are on the `dev` branch. If you are not, first switch to the `dev` branch before creating the new `feature/*` branch.
- Pull requests with human review REQUIRED for all merges

**Rules**:

- Each git branch maps to ONE HCP Terraform workspace (pre-configured during application onboarding)
- Environment-specific values MUST be managed through workspace variables, NOT hardcoded in code
- Shared configuration MAY be extracted to local modules if needed for composition

## Initialize TFLint and pre-commit

> always available in devcontainer

```bash

echo "Initializing TFLint..."
if ! tflint --init; then
    echo "WARNING: TFLint initialization failed, but continuing..."
fi

# Enable pre-commit hooks if available (optional step)
if command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit hooks..."
    pre-commit install
else
    echo "Pre-commit not available - skipping (this is optional)"
fi
```

## Verify directory structure

echo "Module directory structure:"
ls -la

### 3.2 File Organization

**Standard**: Terraform files MUST follow organizational conventions.

**Rules**:

- `main.tf`: Module instantiations and core infrastructure logic
- `variables.tf`: Input variable declarations with descriptions, types, and validation
- `outputs.tf`: Output declarations with descriptions for downstream consumption, outputs should pass back common expected values, examples, names and addresses.
- `providers.tf`: provider configuration blocks
- `versions.tf` : terraform block required_version, required_providers
- `locals.tf` : Terraform locals
-

**Prohibitions**:

- You MUST NOT create monolithic single-file configurations exceeding 300 lines
- You MUST NOT intermingle resource types without logical grouping
- You MUST NOT use default values for security-sensitive variables

### 3.3 Naming Conventions

**Standard**: Names MUST be predictable, consistent, and follow HashiCorp naming standards.

**Format**:

- Resources: `<app>-<resource-type>-<purpose>` (e.g., `api-ec2-web`, `database-rds-primary`)
- Variables: `snake_case` with descriptive names
- Modules: `<provider>-<resource>-<purpose>` (e.g., `aws-vpc-standard`)

**Rules**:

- You MUST follow HashiCorp naming standards (<https://developer.hashicorp.com/terraform/plugin/best-practices/naming>)
- You MUST infer naming from specification or request clarification
- Names MUST NOT include sensitive information (account IDs, secrets, PII)
- Names MUST be idempotent and not include timestamps or random values unless functionally required

### 3.4 Variable Management

**Standard**: Variables MUST be explicitly declared with comprehensive metadata.

**Template**:

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

**Rules**:

- ALL variables MUST include `description` explaining purpose and valid values
- Variables MUST include `type` constraints (never use implicit `any`)
- Security-sensitive variables MUST be marked as `sensitive = true`
- Variables SHOULD include `validation` blocks for business logic constraints
- You leverage workspace variable sets (Vault URL, org standards) and NOT redefine them

### 3.5 Module Usage Patterns

**Standard**: Module consumption MUST follow organizational patterns.

**Example**:

```hcl
module "vpc" {
  source  = "app.terraform.io/<org-name>/vpc/aws"
  version = "~> 3.2.0"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  enable_flow_logs    = true  # Required by ORG-SEC-002

  tags = local.common_tags
}
```

**Rules**:

- You MUST use version constraints (`~>`) to allow patch updates while preventing breaking changes
- Module inputs MUST map to declared variables, NOT hardcoded values
- You MUST include comments explaining non-obvious module configurations
- Module source MUST explicitly reference the private registry e.g. `<app.terraform.io/<org-name>`, never generic registry shortcuts

---

## IV. Security and Compliance

### 3.1 Credential Management

**Policy**: No static credentials SHALL be generated or stored in code.

**Implementation**:

- Workspace variable sets are pre-configured for dynamic provider credentials - you MUST NOT override these
- Provider authentication MUST leverage short-lived dynamic credentials:

  ```hcl
  provider "aws" {
    # Short-lived dynamic credentials provided automatically
    # via pre-configured workspace variable sets
  }
  ```

- You MUST NOT generate `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or similar static credential variables
- You MUST reference dynamic credential workflow in documentation

### 3.2 Security Best Practices

**Policy**: Generated code must embed security best practices and follow organizational standards.

**Implementation**:

- Generated infrastructure MUST align with security requirements (e.g., encryption enabled, public access restricted)
- You SHOULD include security rationale comments:

  ```hcl
  # Encryption enabled to meet organizational security standards
  encryption_enabled = true
  ```

- Security patterns MUST be implemented proactively, not reactively
- Non-compliant patterns MUST be avoided even if technically functional

### 3.3 Secrets Management

**Policy**: Secrets MUST never appear in Terraform code or state.

**Rules**:

- You MUST use ephemeral resources for handling sensitive values instead of data sources or static secrets
- Database passwords, API keys, certificates MUST be handled using ephemeral resources:

  ```hcl
  ephemeral "vault_secret" "db_password" {
    path = "secret/data/${var.environment}/database"
  }
  ```

- You MUST mark outputs containing secrets with `sensitive = true`
- Prefer ephemeral resources over data sources for secret retrieval to minimize exposure in state

### 3.4 Least Privilege by Default

**Policy**: Generated infrastructure MUST implement principle of least privilege.

**General Rules**:

- Identity and access management policies MUST be scoped to minimum required permissions
- Network security rules MUST restrict ingress to known sources and specific ports
- Public access MUST be explicitly justified, documented, and reviewed
- You MUST prefer module-defined roles and policies over custom inline configurations
- All data at rest MUST be encrypted using cloud provider managed keys or customer-managed keys
- All data in transit MUST use TLS/SSL encryption with minimum version 1.2
- Logging and monitoring MUST be enabled for all security-sensitive resources
- Resource tagging MUST include security classification and data sensitivity levels
- Default credentials and service accounts MUST NOT be used for application workloads
- Cross-region replication and backup strategies MUST align with data residency requirements

**AWS-Specific Rules**:

- Security Groups MUST deny all traffic by default, only allowing specific required ports and sources
- S3 buckets MUST block public access unless explicitly required for public hosting
- IAM roles MUST use specific resource ARNs instead of wildcards (`*`) when possible
- RDS instances MUST NOT be publicly accessible unless explicitly justified
- EC2 instances MUST use IAM instance profiles instead of embedded credentials
- Lambda functions MUST use least privilege execution roles with specific service permissions

**GCP-Specific Rules**:

- Firewall rules MUST use specific source ranges instead of `0.0.0.0/0` unless justified
- Cloud Storage buckets MUST use uniform bucket-level access with specific IAM bindings
- Service accounts MUST be granted minimal roles, prefer predefined roles over primitive roles
- Compute instances MUST NOT use default service accounts for application workloads
- Cloud SQL instances MUST require SSL and use private IP when possible
- Cloud Functions MUST use least privilege service account with specific API access

**Azure-Specific Rules**:

- Network Security Groups MUST deny all traffic by default with explicit allow rules
- Storage accounts MUST disable public blob access unless required for static websites
- Key Vault access policies MUST grant minimal permissions per service principal
- Virtual machines MUST use managed identities instead of service principal credentials
- SQL databases MUST use private endpoints and disable public network access when possible
- Function apps MUST use managed identity with specific resource access permissions

---

## V. Workspace and Environment Management

### 4.1 HCP Terraform Workspace Management

**Standard**: HCP Terraform workspaces are pre-provisioned and managed according to organizational policies.

**Workspace Creation Rules**:

- You MUST NEVER create or suggest creating new HCP Terraform workspaces for application teams
- All application workspaces (sandbox, dev, staging, prod) are pre-created during the application team onboarding process
- Workspace provisioning is managed exclusively by the platform team through established onboarding workflows
- This code agent will used workspaces starting with sandbox-<name>

**Ephemeral Workspace Rules**:

- You MUST create ephemeral HCP Terraform workspaces ONLY for testing AI-generated Terraform configuration code
- Ephemeral workspaces MUST be connected to the current `feature/*` branch of the remote Git repository and will use Terraform CLI
- Before running terraform init you must configure credentials, TFE_TOKEN is already set as an environment. variable. See example.

```bash
  mkdir -p ~/.terraform.d && cat > ~/.terraform.d/credentials.tfrc.json << EOF
    {
      "credentials": {
        "app.terraform.io": {
          "token": $TFE_TOKEN
        }
      }
    }
    EOF
```

- Run terraform validate to confirm code is syntactically correct
- The current feature branch MUST be committed and pushed to the remote Git repository BEFORE creating the ephemeral workspace
- ensure the terraform variables are validated by the user before proceeding, including regions values and other required inputs.
- You MUST create all necessary workspace variables at the ephemeral workspace level based on required variables defined in `variables.tf` in the `feature/*` branch
- Ephemeral workspaces MUST be used to validate terraform plan and apply operations before promoting changes
- Upon successful testing in the ephemeral workspace, you MUST create corresponding workspace variables for the dev workspace
- You MUST use the following tools to test AI-generated Terraform code:
  - `create_workspace` to create ephemeral workspace
  - `create_workspace_variable` to create workspace level variables
  - `create_run` to create a new Terraform run in the specified ephemeral workspace
- Ephemeral workspaces MUST be deleted after successful testing to avoid unnecessary costs

**Variable Promotion Workflow**:

1. Test variables in ephemeral workspace connected to `feature/*` branch
2. Confirm variable value with user in prompt before proceeding
3. Validate successful terraform run operations (plan and apply)
4. Create identical workspace variables in the dev workspace
5. Document variable requirements and values for staging and production promotion

### 4.2 Variable Sets

**Standard**: Leverage organization-wide variable sets for common configuration.

**Common Variable Sets**:

- `vault-authentication`: Vault URL, namespace, role for dynamic credentials
- `tags-standard`: Organization, cost-center, compliance tags
- `network-config`: Shared network CIDRs, DNS zones
- `monitoring-config`: Logging endpoints, metrics exporters

**Rules**:

- You MUST NOT duplicate variable set values in code
- You SHOULD document expected variable sets in `README.md`
- Application-specific variables MUST be defined at workspace level, not in code

### 4.3 Environment Promotion

**Standard**: Changes MUST flow feature → dev → staging → main branches with mandatory human review at each stage.

**Git Branch Workflow**:

1. **Feature Development**: Create feature branch from `dev` branch (`feature/description`)
2. **Development Merge**: Pull request from feature branch to `dev` branch (requires human review)
3. **Staging Promotion**: Pull request from `dev` to `staging` branch (requires human review after dev validation)
4. **Production Promotion**: Pull request from `staging` to `main` branch (requires human review after staging validation)

**Branch Protection Requirements**:

- Direct commits to `dev`, `staging`, and `main` branches are STRICTLY PROHIBITED
- All changes MUST originate from feature branches
- Human-in-the-loop review REQUIRED for ALL pull requests
- Feature branches MUST be deleted after successful merge to `dev`

**Rules**:

- You MUST generate identical code structure across all branches
- Environment-specific values MUST be externalized to workspace variables (configured during onboarding)
- Production deployments (`main` branch) REQUIRE manual approval (AI-generated code cannot bypass)
- Workspace-level security policies enforce stricter rules for production workspaces

---

## VI. Code Quality and Maintainability

### 5.1 Documentation Requirements

**Standard**: AI-generated code MUST be self-documenting and include external documentation with automated generation.

**Requirements**:

- Every repository MUST include comprehensive `README.md` with:
  - Purpose and scope
  - Prerequisites (workspace setup, variable sets)
  - Module dependencies
  - Deployment instructions (including `terraform init` and `terraform plan` as these are automatically handled by HCP Terraform VCS workflow)
  - Troubleshooting guide
- README.md MUST be automatically generated and updated using `terraform-docs` via Git pre-commit hooks
- Complex logic MUST include inline comments explaining rationale
- Module selections MUST be justified in comments
- All variables and outputs MUST have proper descriptions for `terraform-docs` automatic documentation generation

### 5.2 Code Style

**Standard**: Generated code MUST follow HashiCorp Style Guide.

**Rules**:

- Use `terraform fmt` for formatting
- User `terraform init` then `terraform validate` for syntax validation
- Alphabetize arguments within blocks for consistency
- Use consistent argument ordering: required args first, optional args second, meta-args last
- You MUST run `terraform fmt` on generated code before presenting to users

### 5.3 Testing and Validation

**Standard**: Generated code MUST be validated before commit using automated Git pre-commit hooks.

**Git Pre-commit Hook Configuration**:

- Git pre-commit hook MUST be configured to update README using `terraform-docs` for automatic documentation generation
- Git pre-commit hook MUST be configured to format code using `terraform fmt` for consistent code formatting
- Git pre-commit hook MUST be configured to validate syntax using `terraform validate` for configuration validation
- Git pre-commit hook MUST be configured with `tflint` to perform linting and identify configuration errors
- Git pre-commit hook MUST be configured with `tfsec` to perform static code analysis for security vulnerabilities
- pre-commit should not be bypassed unless the user has authorized

**Validation Steps**:

- You SHOULD recommend configuring pre-commit hooks in the development environment
- run `terraform init` or `terraform plan` using a cloud block to specify the workspace in your specified HCP terraform project
- Reviewing the terraform plan output in the HCP Terraform UI for the dev workspace before promoting to other environments
- Review and resolve any detailed workspace output or warnings from the workspace.

### 5.4 Version Control

**Standard**: Generated code MUST be version controlled with meaningful commits.

**Rules**:

- `.gitignore` MUST exclude:

  ```bash
  .terraform/
  *.tfstate
  *.tfstate.backup
  .terraform.lock.hcl
  *.tfvars  # May contain sensitive data
  ```

- You SHOULD suggest atomic commits per logical change
- You MUST NOT commit secrets, credentials, or sensitive data

---

## VII. Operational Excellence

### 6.1 State Management

**Standard**: All state MUST be managed remotely in HCP Terraform.

**Rules**:

- You MUST NOT generate local backend configurations
- Backend configuration typically empty for HCP Terraform CLI-driven workflow:

  ```hcl
  terraform {
    cloud {
      organization = "<org-name>"
      workspaces {
        name = "<workspace-name>"
      }
    }
  }
  ```

- State MUST never be committed to version control

### 6.2 Dependency Management

**Standard**: Provider and module versions MUST be explicitly constrained.

**Template**:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Rules**:

- Terraform minimum version is managed at the workspace level and MUST NOT be configured in code
- Provider versions MUST use pessimistic constraints (`~>`)
- You MUST NOT use `latest` or unconstrained versions

### 6.3 Cost Optimization

**Standard**: Generated infrastructure MUST consider cost implications.

**Rules**:

- You SHOULD prefer cost-effective resource types for non-production environments
- You MUST implement auto-scaling where applicable to optimize utilization
- You SHOULD include cost estimation reminders in documentation
- Idle resource cleanup SHOULD be considered for non-production environments

### 6.4 Monitoring and Observability

**Standard**: Infrastructure MUST be observable by default.

**Rules**:

- You SHOULD enable CloudWatch/monitoring when using AWS modules
- Tags MUST include monitoring metadata (`Environment`, `Owner`, `Application`)
- You SHOULD output critical resource identifiers for integration with monitoring systems

---

## VIII. AI Agent Behavior and Constraints

### 8.1 Prerequisites Validation

**Constraint**: You MUST validate HCP Terraform prerequisites before any operations.

**Requirements**:

- The `/specify` command MUST always check for required HCP Terraform configuration details
- You MUST NOT proceed with Terraform operations without complete prerequisites
- Missing configuration details MUST be surfaced to the user with clear instructions
- All Terraform MCP server tool calls MUST use the validated configuration values

**Mandatory Prerequisites**:

- HCP Terraform Organization Name
- HCP Terraform Project Name
- HCP Terraform Workspace Name for Dev environment
- HCP Terraform Workspace Name for Staging environment
- HCP Terraform Workspace Name for Prod environment

### 8.2 Scope Boundaries

**Constraint**: You MUST operate within defined consumption patterns.

**In Scope**:

- Searching for and composing infrastructure from approved private modules using `search_private_modules` tool
- Generating environment-specific variable definitions
- Creating documentation and README files
- Suggesting workspace configuration
- Explaining Terraform concepts to less experienced users

**Out of Scope**:

- Creating new Terraform modules (platform team responsibility)
- Modifying or forking existing modules without explicit approval
- Bypassing policy controls or suggesting workarounds
- Direct resource creation without module encapsulation
- Workspace RBAC configuration (security team responsibility)

### 8.3 Error Handling and Transparency

**Standard**: You MUST acknowledge limitations and uncertainties.

**Rules**:

- You MUST use `search_private_modules` tool to find appropriate modules before generating infrastructure code
- When multiple approaches exist, you MUST explain tradeoffs
- When specifications are ambiguous, you MUST request clarification before proceeding
- When required modules don't exist in the private registry (confirmed via `search_private_modules`), you MUST NOT improvise with raw resources
- When policy violations are likely, you MUST warn users proactively

### 8.4 Learning and Adaptation

**Standard**: You MUST learn from organizational patterns and feedback.

**Implementation**:

- You SHOULD reference successful prior implementations as patterns
- You MUST respect organizational customizations to this constitution
- You SHOULD incorporate policy feedback to avoid repeated violations

---

## IX. Governance and Evolution

### 9.1 Constitution Updates

**Process**: This constitution evolves with organizational needs.

**Update Authority**:

- Platform team maintains constitution in version control
- Major changes require review by security and governance teams
- Application teams MAY propose amendments via pull request
- Constitution version MUST be referenced in AI agent prompts

### 9.2 Exception Process

**Policy**: Deviations require explicit approval and documentation.

**Process**:

1. Document specific requirement driving exception
2. Propose alternative approach with risk assessment
3. Obtain platform team approval
4. Document exception in code and centralized exceptions register
5. Review exception during next policy update cycle

### 9.3 Audit and Compliance

**Standard**: AI-generated code is subject to same audits as human-authored code.

**Requirements**:

- All generated code MUST pass through policy enforcement
- Periodic audits verify constitution compliance
- Non-compliant patterns trigger constitution updates or module improvements
- Metrics track module adoption rates and AI-generated code quality

### 9.4 Feedback Loop

**Standard**: Continuous improvement through systematic feedback.

**Mechanisms**:

- Application teams provide feedback on module usability
- Policy violations inform module design improvements
- AI agent error patterns drive documentation enhancements
- Adoption metrics guide platform team priorities

---

## X. Testing and Validation Framework

### 10.1 Ephemeral Workspace Testing

**Standard**: All AI-generated Terraform code MUST be validated in ephemeral testing environments before promotion.

**Rationale**: Ephemeral workspaces provide safe, isolated environments for testing infrastructure changes without impacting existing environments or incurring long-term costs.

**Implementation Requirements**:

- You MUST create ephemeral HCP Terraform workspaces ONLY for testing AI-generated Terraform configuration code
- The current `feature/*` branch MUST be committed and pushed to the remote Git repository BEFORE creating the ephemeral workspace
- Ephemeral workspaces MUST be created within the current HCP Terraform Organization and Project
- Ephemeral workspace MUST be connected to the current `feature/*` branch of the application's GitHub remote repository to ensure code under test matches the current feature development state
- Ephemeral workspace MUST be created with "auto-apply API, UI and VCS runs" setting turned ON to enable automatic apply after successful plan without human confirmation
- Ephemeral workspace MUST be created with "Auto-Destroy" setting ON and configured to automatically delete after 2 hours
- You MUST create all necessary workspace variables at the ephemeral workspace level based on required variables defined in `variables.tf` in the `feature/*` branch
- Testing MUST include both `terraform plan` and `terraform apply` operations
- All testing activities MUST be performed automatically against the ephemeral workspace
- Upon successful testing, you MUST create corresponding workspace variables for the dev workspace
- Ephemeral workspaces will be automatically destroyed after 2 hours via auto-destroy setting

### 10.2 Automated Testing Workflow

**Standard**: Testing workflow MUST be fully automated using available Terraform MCP server tools.

**Testing Process**:

1. **Ephemeral Workspace Creation**:
   - Create ephemeral workspace using Terraform MCP server
   - Workspace name MUST follow pattern: `test-<app-name>-<timestamp>` or similar unique identifier
   - Workspace MUST be created in the specified HCP Terraform Organization and Project
   - Workspace MUST have "auto-apply API, UI and VCS runs" setting enabled (set `auto_apply` to `true`)
   - Workspace MUST have "Auto-Destroy" setting enabled with 2-hour duration (`auto_destroy_at` set to 2 hours from creation)

2. **Variable Configuration**:
   - Analyze `variables.tf` file in the `feature/*` branch to identify all required variables
   - Create workspace variables at the ephemeral workspace level using Terraform MCP server tools
   - Prompt user for variable values when not determinable (DO NOT guess values)
   - EXCLUDE cloud provider credentials (these are pre-configured at workspace level)
   - Include all application-specific and environment-specific variables
   - Document variable configuration for subsequent dev workspace setup

3. **Terraform Execution**:
   - Ensure
   - Run `terraform init`, then  `terraform plan` locally** - HCP Terraform VCS workflow handles these automatically
   - Create a Terraform run against the ephemeral workspace (via `create_run` with auto-apply enabled)
   - HCP Terraform will automatically execute `terraform init` and `terraform plan` as part of the run
   - Analyze plan output for potential issues or unexpected changes
   - Terraform apply will automatically start after successful plan due to auto-apply setting
   - Monitor apply operation for successful completion

4. **Result Analysis**:
   - Verify successful completion of terraform run
   - If errors occur, analyze output and provide specific remediation suggestions
   - Document any issues found and resolution steps taken
   - Upon successful testing, prompt user to validate the created resources
   - After user validation, create identical workspace variables for the dev workspace
   - Delete the ephemeral workspace to minimize costs (auto-destroy will handle cleanup if manual deletion is not performed)
   - Provide clear success/failure status to the user

### 10.3 Variable Management for Testing

**Standard**: Test workspace variables MUST be derived from generated configuration files.

**Variable Source Priority**:

1. **variables.tf**: Primary source for identifying required variables, validation rules and type constraints
2. **User Input**: Values for application-specific variables (when not determinable)
3. **Workspace Variable Sets**: Pre-configured organizational standards (DO NOT duplicate)

**Variable Creation Rules**:

- You MUST create workspace variables for all required variables defined in variables.tf from the `feature/*` branch
- You MUST respect variable types and validation rules defined in variables.tf
- You MUST prompt user for values when they cannot be reasonably determined
- You MUST NOT create variables for cloud provider credentials (AWS keys, GCP service accounts, etc.)
- You SHOULD use sensible defaults for non-sensitive testing values where appropriate
- You MUST mark sensitive variables appropriately in the workspace
- Upon successful testing, you MUST create identical variables in the dev workspace

**Example Variable Handling**:

```hcl
# From variables.tf in feature/* branch
variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# Implementation:
# - environment: Set to "test" for ephemeral workspace
# - vpc_cidr: Prompt user for test CIDR value
# - database_password: Prompt user for test password (marked sensitive)
# - Upon success: Create identical variables in dev workspace
```

### 10.4 Error Analysis and Remediation

**Standard**: Test failures MUST be analyzed systematically with actionable remediation guidance.

**Failure Analysis Process**:

1. **Plan Failures**:
   - Analyze terraform plan errors for configuration issues
   - Check for missing variables or invalid variable values
   - Verify module sources and version constraints
   - Validate provider configuration and authentication

2. **Apply Failures**:
   - Analyze resource creation errors for infrastructure constraints
   - Check for quota limits, permission issues, or resource conflicts
   - Verify network connectivity and security group configurations
   - Examine resource dependencies and ordering issues

3. **Validation Failures**:
   - Check terraform validation errors for syntax or configuration issues
   - Verify required provider versions and constraints
   - Validate variable types and constraint violations

**Remediation Guidance**:

- You MUST provide specific, actionable remediation steps for identified issues
- You SHOULD suggest code changes to resolve configuration problems
- You MUST distinguish between issues requiring code changes vs. workspace configuration
- You SHOULD provide alternative approaches when the original approach has fundamental issues

### 10.5 Testing Documentation Requirements

**Standard**: All testing activities MUST be documented for audit and troubleshooting purposes.

**Documentation Requirements**:

- Testing process MUST be documented in the README.md
- Variable requirements MUST be clearly explained
- Prerequisites for testing MUST be listed
- Common testing issues and resolutions MUST be documented

**README Testing Section Template**:

```markdown
## Testing

This infrastructure code has been validated using ephemeral HCP Terraform workspaces.

### Prerequisites
- HCP Terraform organization and project access
- Required variable values (see terraform.tfvars.example)
- Terraform MCP server configured

### Testing Process
1. Ephemeral workspace created: `<workspace-name>`
2. Variables configured from terraform.tfvars.example
3. Terraform plan executed successfully
4. Terraform apply completed without errors

### Required Variables
- `environment`: Deployment environment
- `vpc_cidr`: VPC CIDR block for networking
- (Additional variables as identified)

### Common Issues
- (Document any issues encountered during testing)
```

### 10.6 Cleanup and Resource Management

**Standard**: Ephemeral testing resources MUST be properly cleaned up to avoid unnecessary costs.

**Cleanup Requirements**:

- Ephemeral workspaces have auto-destroy enabled as a safety mechanism (2 hours after creation)
- You MUST trigger workspace deletion after successful terraform apply AND user validation of resources
- Manual cleanup after validation minimizes costs and prevents unnecessary resource retention
- Auto-destroy serves as a failsafe if manual cleanup is not performed
- You MUST notify users that the ephemeral workspace will auto-destroy in 2 hours if not manually cleaned up
- If testing fails, workspace will still be destroyed after 2 hours but users are notified to review logs before destruction

**Cost Optimization**:

- Use minimal resource sizes for testing when possible
- Prefer regions with lower costs for ephemeral testing
- Document cost implications of extended testing periods
- Suggest cleanup schedules for development workflows

---

## XI. Implementation Checklist

### For Application Teams Using AI Agents

- [ ] Clone validated pattern template repository
- [ ] Review this constitution with your team
- [ ] Create specification for your infrastructure requirements
- [ ] Use `search_private_modules` tool to identify required modules from private registry
- [ ] Configure IDE with AI assistant (Copilot, Claude Code, etc.)
- [ ] Generate Terraform code following this constitution
- [ ] Validate code with `terraform validate` and `terraform fmt` (note: do NOT run `terraform init` or `terraform plan` locally)
- [ ] Commit and push code to trigger HCP Terraform VCS workflow
- [ ] Review plan output in HCP Terraform UI
- [ ] Deploy to dev environment and validate
- [ ] Progress through staging to production with approval gates
- [ ] Keep track of any tool call errors and write the errors out to tool_errors_output.log with the details, provide the solution if the tool call was fixed by a subsequent call

### For Platform Teams

- [ ] Publish this constitution to organization knowledge base
- [ ] Create starter templates embodying these principles
- [ ] Document module catalog with usage examples
- [ ] Configure workspace-level security policies and controls
- [ ] Establish workspace provisioning workflow
- [ ] Create variable sets for common organizational config
- [ ] Monitor module adoption and AI-generated code quality
- [ ] Iterate on modules based on consumption patterns

---

## XI. References and Resources

### Internal Resources

- Private Module Registry: `app.terraform.io/<org-name>/modules`
- Policy Repository: `<policy-repo-url>`
- Platform Team Contact: `<platform-team-contact>`

### External Resources

- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [HashiCorp Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [GitHub Spec-Kit](https://github.com/github/spec-kit)
- [AWS Terraform Provider Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/)
- [Azure Terraform Best Practices](https://docs.microsoft.com/en-us/azure/developer/terraform/best-practices)
- [Google Cloud Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform)

### Change Log

- **v1.0.0** (October 2025): Initial constitution release
