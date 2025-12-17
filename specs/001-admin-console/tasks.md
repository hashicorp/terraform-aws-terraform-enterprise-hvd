---
description: "Task list for Terraform Enterprise Admin Console Configuration Support"
---

# Tasks: Terraform Enterprise Admin Console Configuration Support

**Input**: Design documents from `/specs/001-admin-console/`
**Prerequisites**: plan.md (complete), spec.md (complete)

**Tests**: Not explicitly requested in specification. Tasks focus on implementation and manual validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Terraform Module**: Root directory contains `.tf` files
- **Templates**: `templates/` directory
- **Examples**: `examples/` directory
- **Tests**: `tests/` directory
- **Documentation**: Root `README.md` and `docs/` directory

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and validation tooling setup

- [ ] T001 Run pre-commit run --all-files to establish baseline (includes terraform fmt, validate, tflint)
- [ ] T002 [P] Review existing security group patterns in compute.tf for consistency

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core variable validation and data source infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Add port validation helper locals in variables.tf for port conflict checking
- [ ] T004 Add data sources for AWS Secrets Manager in compute.tf for admin console token retrieval
- [ ] T005 Update user_data_args local in compute.tf to support admin console template variables

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Enable Admin Console Access (Priority: P1) 🎯 MVP

**Goal**: Allow platform operators to enable the TFE Admin Console by setting configuration variables in their Terraform module

**Independent Test**: Deploy TFE with `tfe_admin_console_enabled = true`, verify the admin console port is accessible, and confirm the admin console authentication endpoint responds correctly

### Implementation for User Story 1

- [ ] T006 [P] [US1] Add tfe_admin_console_enabled variable in variables.tf
- [ ] T007 [P] [US1] Add tfe_admin_console_port variable with validation in variables.tf
- [ ] T008 [US1] Add admin console environment variables to Docker Compose config in templates/tfe_user_data.sh.tpl (generate_tfe_docker_compose_config function)
- [ ] T009 [US1] Add admin console port mapping to Docker Compose ports section in templates/tfe_user_data.sh.tpl
- [ ] T010 [US1] Add admin console environment variables to Podman manifest in templates/tfe_user_data.sh.tpl (generate_tfe_podman_manifest function)
- [ ] T011 [US1] Add admin console port mapping to Podman manifest ports section in templates/tfe_user_data.sh.tpl
- [ ] T012 [P] [US1] Add tfe_admin_console_enabled output in outputs.tf
- [ ] T013 [P] [US1] Add tfe_admin_console_port output in outputs.tf
- [ ] T014 [P] [US1] Add tfe_admin_console_url_pattern output in outputs.tf
- [ ] T015 [US1] Create examples/admin-console-enabled/ directory structure
- [ ] T016 [US1] Create examples/admin-console-enabled/main.tf with basic admin console configuration
- [ ] T017 [P] [US1] Create examples/admin-console-enabled/variables.tf with example variable values
- [ ] T018 [P] [US1] Create examples/admin-console-enabled/README.md with usage instructions
- [ ] T019 [US1] Run pre-commit run --files variables.tf outputs.tf templates/tfe_user_data.sh.tpl

**Checkpoint**: At this point, User Story 1 should be fully functional - admin console can be enabled and will start listening on configured port

---

## Phase 4: User Story 2 - Configure Admin Console Network Access (Priority: P2)

**Goal**: Allow platform operators to control which networks can access the admin console by specifying allowed CIDR ranges and configuring the listening port

**Independent Test**: Deploy with specific CIDR ranges and port configurations, then verify network access is restricted to specified ranges and the custom port is used if configured

### Implementation for User Story 2

- [ ] T020 [US2] Add cidr_allow_ingress_tfe_admin_console variable with CIDR validation in variables.tf
- [ ] T021 [US2] Add validation rule in variables.tf requiring CIDR when admin console enabled
- [ ] T022 [P] [US2] Add aws_security_group_rule.ec2_allow_ingress_tfe_admin_console resource in compute.tf
- [ ] T023 [P] [US2] Add aws_security_group_rule.ec2_allow_ingress_tfe_admin_console_ipv6 resource in compute.tf
- [ ] T024 [US2] Update examples/admin-console-enabled/main.tf to include CIDR configuration examples
- [ ] T025 [US2] Update examples/admin-console-enabled/README.md with network security documentation
- [ ] T026 [US2] Run pre-commit run --files variables.tf compute.tf

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - admin console access is now restricted by security groups to specified CIDRs

---

## Phase 5: User Story 3 - Configure Admin Console Authentication (Priority: P2)

**Goal**: Allow platform operators to configure authentication settings for the admin console, including the authentication token and token expiration

**Independent Test**: Provide a custom authentication token during deployment and verify that only requests with the correct token can access admin console endpoints, and tokens expire as configured

### Implementation for User Story 3

- [ ] T027 [P] [US3] Add tfe_admin_console_token_secret_arn variable in variables.tf
- [ ] T028 [P] [US3] Add tfe_admin_console_token_timeout variable with range validation in variables.tf
- [ ] T029 [US3] Add data.aws_secretsmanager_secret.tfe_admin_console_token data source in compute.tf
- [ ] T030 [US3] Add data.aws_secretsmanager_secret_version.tfe_admin_console_token data source in compute.tf
- [ ] T031 [US3] Update Docker Compose config in templates/tfe_user_data.sh.tpl to include conditional token and timeout environment variables
- [ ] T032 [US3] Update Podman manifest in templates/tfe_user_data.sh.tpl to include conditional token and timeout environment variables
- [ ] T033 [US3] Create examples/admin-console-enabled/secrets.tf example for Secrets Manager token configuration
- [ ] T034 [US3] Update examples/admin-console-enabled/README.md with authentication token documentation
- [ ] T035 [US3] Run pre-commit run --files variables.tf compute.tf templates/tfe_user_data.sh.tpl

**Checkpoint**: All authentication features are now functional - tokens can be provided or system-generated, with configurable expiration

---

## Phase 6: User Story 4 - Maintain Backward Compatibility (Priority: P1)

**Goal**: Ensure existing TFE deployments using this module continue to work without modification when the module is upgraded

**Independent Test**: Deploy TFE with the updated module using existing variable configurations (without any admin console variables set), and verify the deployment succeeds with no changes to running behavior

### Implementation for User Story 4

- [ ] T036 [US4] Verify all admin console variables have secure defaults (false/null) in variables.tf
- [ ] T037 [US4] Test existing module examples to confirm they still work without modifications
- [ ] T038 [US4] Add conditional logic validation in templates/tfe_user_data.sh.tpl to ensure no admin console config when disabled (both Docker and Podman)
- [ ] T039 [US4] Document upgrade path in README.md for existing deployments
- [ ] T040 [US4] Add backward compatibility test scenario to examples/

**Checkpoint**: Backward compatibility verified - existing deployments are not affected by admin console additions

---

## Phase 8: User Story 5 - Optional Load Balancer Integration (Priority: P3 - OPTIONAL)

**Goal**: Allow platform operators to route admin console traffic through the existing load balancer instead of direct EC2 access to consolidate network entry points and leverage load balancer features

**⚠️ IMPORTANT**: This is an OPTIONAL enhancement. Core admin console functionality (US1-US4) works without this feature. Direct EC2 access remains the default and recommended approach for administrative interfaces.

**Dependencies**: Depends on User Story 1 (Enable Admin Console) and User Story 2 (Network Access) completion

**Independent Test**: Enable admin console with LB routing option, deploy with both NLB and ALB configurations separately, and verify admin console is accessible through the load balancer endpoint with proper health checks

### Implementation for User Story 5

- [ ] T056 [P] [US5] Add tfe_admin_console_use_lb variable with validation in variables.tf
- [ ] T057 [P] [US5] Add aws_lb_listener.lb_nlb_admin_console resource in load_balancer.tf (conditional on NLB + LB routing)
- [ ] T058 [P] [US5] Add aws_lb_target_group.nlb_admin_console resource in load_balancer.tf with health checks and stickiness
- [ ] T059 [P] [US5] Add aws_lb_listener.alb_admin_console resource in load_balancer.tf (conditional on ALB + LB routing)
- [ ] T060 [P] [US5] Add aws_lb_target_group.alb_admin_console resource in load_balancer.tf with health checks and stickiness
- [ ] T061 [US5] Add target group attachment resources for admin console target groups in load_balancer.tf (same pattern as 443 TGs)
- [ ] T062 [P] [US5] Add aws_security_group_rule.lb_allow_ingress_admin_console_from_cidr resource in load_balancer.tf
- [ ] T063 [P] [US5] Add aws_security_group_rule.lb_allow_ingress_admin_console_from_ipv6 resource in load_balancer.tf
- [ ] T064 [US5] Update aws_security_group_rule.ec2_allow_ingress_tfe_admin_console to be conditional on !var.tfe_admin_console_use_lb in compute.tf
- [ ] T065 [US5] Add aws_security_group_rule.ec2_allow_ingress_admin_console_from_lb resource in compute.tf for LB-routed access
- [ ] T066 [US5] Update tfe_admin_console_url_pattern output in outputs.tf to return LB DNS when LB routing enabled
- [ ] T067 [US5] Create examples/admin-console-with-lb/ example directory with main.tf for NLB configuration
- [ ] T068 [P] [US5] Create examples/admin-console-with-lb/variables.tf with example variable values
- [ ] T069 [P] [US5] Create examples/admin-console-with-lb/README.md explaining LB routing option
- [ ] T070 [US5] Add LB routing option documentation section to README.md
- [ ] T071 [US5] Create docs/admin-console-lb-routing.md explaining when to use LB routing vs direct access
- [ ] T072 [US5] Run pre-commit run --files variables.tf load_balancer.tf compute.tf outputs.tf
- [ ] T073 [US5] Manual test: Deploy with NLB and tfe_admin_console_use_lb=true, verify access through NLB DNS
- [ ] T074 [US5] Manual test: Deploy with ALB and tfe_admin_console_use_lb=true, verify access through ALB DNS
- [ ] T075 [US5] Manual test: Verify admin console health checks working on both NLB and ALB target groups
- [ ] T076 [US5] Manual test: Verify traffic fails over correctly between EC2 instances through load balancer

**Checkpoint**: User Story 5 (optional LB integration) is complete - admin console can now optionally route through load balancer while maintaining direct EC2 access as default

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and quality improvements that affect multiple user stories

- [ ] T041 [P] Update README.md with Admin Console Configuration section documenting new variables
- [ ] T042 [P] Create docs/admin-console-configuration.md with detailed configuration guide
- [ ] T043 [P] Create docs/admin-console-security.md with security best practices
- [ ] T044 [P] Create docs/admin-console-troubleshooting.md with troubleshooting guidance
- [ ] T045 Update CHANGELOG.md with admin console feature additions
- [ ] T046 Run pre-commit run --all-files to validate all changes (terraform fmt, validate, tflint, terraform-docs)
- [ ] T047 Manual test: Deploy with admin console disabled (default) - verify no changes to existing behavior
- [ ] T048 Manual test: Deploy with admin console enabled - verify port accessible from allowed CIDR
- [ ] T049 Manual test: Deploy with admin console enabled - verify port blocked from non-allowed CIDR
- [ ] T050 Manual test: Verify admin console authentication with provided token from Secrets Manager
- [ ] T051 Manual test: Test upgrade path from existing deployment without admin console variables
- [ ] T052 Manual test: Verify admin console works in active-active operational mode
- [ ] T053 Manual test: Verify admin console works in external operational mode
- [ ] T054 Manual test: Verify admin console with Podman runtime
- [ ] T055 Manual test: Verify admin console with Docker runtime

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order: US1 (P1) → US2 (P2) → US3 (P2) → US4 (P1) → US5 (P3, OPTIONAL)
  - US1 and US4 are P1 (highest priority)
  - US2 and US3 are P2 (can be done after P1 stories)
  - US5 is P3 (optional enhancement - can be skipped entirely)
- **Polish (Phase 9)**: Depends on all required user stories being complete (US1-US4; US5 is optional)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 (needs basic enable functionality) - Extends with security group rules
- **User Story 3 (P2)**: Depends on US1 (needs basic enable functionality) - Extends with authentication features
- **User Story 4 (P1)**: Can be validated after US1-3 complete - Verifies backward compatibility
- **User Story 5 (P3, OPTIONAL)**: Depends on US1 (enable functionality) and US2 (security group patterns) - Adds optional LB routing

### Within Each User Story

#### User Story 1 (Enable Admin Console)
- Variables and outputs can be created in parallel
- Template updates must follow variable creation
- Examples follow template completion

#### User Story 2 (Network Access)
- Variables can be created in parallel with security group rules
- Security group rules (IPv4 and IPv6) can be created in parallel
- Example updates follow security group completion

#### User Story 3 (Authentication)
- Variables can be created in parallel
- Data sources follow variable creation
- Template and example updates can proceed in parallel

#### User Story 4 (Backward Compatibility)
- All validation tasks can proceed in parallel after US1-3 complete

#### User Story 5 (Optional Load Balancer Integration - OPTIONAL)
- Variables can be created in parallel with load balancer resources
- NLB resources (listener, target group) can be created in parallel
- ALB resources (listener, target group) can be created in parallel
- Security group rules (LB and EC2) can be created in parallel
- Documentation and examples can be created in parallel

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks can run in parallel (within Phase 2)
- Within User Story 1: T007, T008 (variables), T011, T012, T013 (outputs), T016, T017 (examples) can run in parallel
- Within User Story 2: T020, T021 (security group rules) can run in parallel
- Within User Story 3: T024, T025 (variables) can run in parallel
- Within User Story 5: T056 (variable), T057, T058 (NLB resources), T059, T060 (ALB resources), T062, T063 (LB security group rules), T068, T069 (examples) can run in parallel
- Within Phase 9: All documentation tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all variables and outputs for User Story 1 together:
Task: "Add tfe_admin_console_enabled variable in variables.tf"
Task: "Add tfe_admin_console_port variable with validation in variables.tf"
Task: "Add tfe_admin_console_enabled output in outputs.tf"
Task: "Add tfe_admin_console_port output in outputs.tf"
Task: "Add tfe_admin_console_url_pattern output in outputs.tf"

# After template updates, launch example documentation in parallel:
Task: "Create examples/admin-console-enabled/variables.tf with example variable values"
Task: "Create examples/admin-console-enabled/README.md with usage instructions"
```

---

## Parallel Example: User Story 2

```bash
# Launch both security group rules together:
Task: "Add aws_security_group_rule.ec2_allow_ingress_tfe_admin_console resource in compute.tf"
Task: "Add aws_security_group_rule.ec2_allow_ingress_tfe_admin_console_ipv6 resource in compute.tf"
```

---

## Parallel Example: User Story 5 (Optional LB Integration)

```bash
# Launch variables, load balancer resources, and security group rules together:
Task: "Add tfe_admin_console_use_lb variable with validation in variables.tf"
Task: "Add aws_lb_listener.lb_nlb_admin_console resource in load_balancer.tf"
Task: "Add aws_lb_target_group.nlb_admin_console resource in load_balancer.tf"
Task: "Add aws_lb_listener.alb_admin_console resource in load_balancer.tf"
Task: "Add aws_lb_target_group.alb_admin_console resource in load_balancer.tf"
Task: "Add aws_security_group_rule.lb_allow_ingress_admin_console_from_cidr resource"
Task: "Add aws_security_group_rule.lb_allow_ingress_admin_console_from_ipv6 resource"

# After EC2 security group updates, launch documentation in parallel:
Task: "Create examples/admin-console-with-lb/variables.tf with example variable values"
Task: "Create examples/admin-console-with-lb/README.md explaining LB routing option"
```

---

## Parallel Example: Phase 9 (Polish)

```bash
# Launch all documentation tasks together:
Task: "Update README.md with Admin Console Configuration section documenting new variables"
Task: "Run terraform-docs to regenerate variables reference documentation"
Task: "Create docs/admin-console-configuration.md with detailed configuration guide"
Task: "Create docs/admin-console-security.md with security best practices"
Task: "Create docs/admin-console-troubleshooting.md with troubleshooting guidance"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Enable Admin Console)
4. Complete Phase 6: User Story 4 (Backward Compatibility)
5. **STOP and VALIDATE**: Test that admin console can be enabled AND existing deployments still work
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Basic admin console working
3. Add User Story 4 → Test independently → Backward compatibility confirmed (MVP!)
4. Add User Story 2 → Test independently → Network access controls working
5. Add User Story 3 → Test independently → Authentication features working
6. (Optional) Add User Story 5 → Test independently → Load balancer routing working
7. Add Polish → Complete documentation and validation
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Enable Admin Console)
   - Developer B: User Story 4 (Backward Compatibility validation scripts)
3. After US1 + US4 complete (MVP checkpoint):
   - Developer A: User Story 2 (Network Access)
   - Developer B: User Story 3 (Authentication)
4. (Optional) After US2 + US3 complete:
   - Developer A or B: User Story 5 (Optional LB Integration)
5. Final: Team completes Polish together

---

## Summary Statistics

- **Total Tasks**: 76
- **User Story 1 (Enable Admin Console)**: 14 tasks (includes Docker + Podman template updates, pre-commit validation)
- **User Story 2 (Network Access)**: 7 tasks (includes pre-commit validation)
- **User Story 3 (Authentication)**: 9 tasks (includes Docker + Podman template updates, pre-commit validation)
- **User Story 4 (Backward Compatibility)**: 5 tasks
- **User Story 5 (Optional LB Integration)**: 21 tasks (OPTIONAL - includes NLB, ALB, security groups, examples, documentation, testing)
- **Setup Phase**: 2 tasks (consolidated with pre-commit)
- **Foundational Phase**: 3 tasks
- **Polish Phase**: 15 tasks (includes comprehensive pre-commit validation, Docker + Podman runtime testing)

**Parallel Opportunities Identified**: 
- Phase 1: 1 parallel task
- User Story 1: 7 parallel tasks
- User Story 2: 2 parallel tasks
- User Story 3: 2 parallel tasks
- User Story 5: 8 parallel tasks
- Phase 9: 4 parallel tasks
- **Total parallelizable**: 24 tasks (32% of all tasks)

**Suggested MVP Scope**: User Story 1 (Enable Admin Console) + User Story 4 (Backward Compatibility) = 19 tasks (includes Docker + Podman support, pre-commit validation)

**Note**: User Story 5 (Optional LB Integration) is P3 priority and completely optional. Core admin console functionality works without it. Include only if load balancer routing is specifically required.

**Format Validation**: ✅ All 76 tasks follow the checklist format with checkbox, Task ID, optional [P] marker, [Story] label (where appropriate), and file paths

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **User Story 5 (P3)**: OPTIONAL enhancement for LB routing. Core admin console works without it. Direct EC2 access is the default and recommended approach.
- **pre-commit integration**: Repository uses pre-commit hooks that run terraform fmt, validate, tflint, and terraform-docs automatically
  - Run `pre-commit run --all-files` at setup to establish baseline
  - Run `pre-commit run --files <files>` after each user story implementation
  - Final validation with `pre-commit run --all-files` ensures all checks pass
- **Container runtime support**: Template supports both Docker Compose and Podman manifest configurations
  - Updates required in both `generate_tfe_docker_compose_config` and `generate_tfe_podman_manifest` functions
  - Manual testing should verify both runtimes
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All changes are additive - no breaking changes to existing module functionality
- Security-first: Admin console disabled by default, no default CIDR access
- Terraform module pattern: Changes span variables.tf, compute.tf, load_balancer.tf, templates/, outputs.tf, examples/, docs/
