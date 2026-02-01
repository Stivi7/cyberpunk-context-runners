# Agent Skill Extraction Plan

## Overview

This document outlines the extraction of granular, universal skills from the current agent definitions. The goal is to transform specialized agent knowledge into reusable skill modules that follow the Unix philosophy: do one thing and do it well.

**Key Principles:**
- **Granular**: Each skill handles a single, well-defined concern
- **Universal**: Skills are domain-based, not agent-specific
- **Pure Function Style**: Clear inputs, clear outputs, no side effects
- **Composable**: Skills can be combined to solve complex problems

---

## Agent Analysis Summary

### Agents Being Updated

| Agent | Role | Current Responsibilities | Skills to Extract |
|-------|------|-------------------------|-------------------|
| **The Mind** | Planner | Architecture design, AWS service selection, DynamoDB design, API design, Frontend architecture, Risk assessment | 8 skills |
| **The Interrogator** | Plan Reviewer | Plan validation, Feasibility analysis, Risk identification, Critical review | 3 skills |
| **The Fragmenter** | Task Builder | Epic/story creation, Task decomposition, Dependency mapping | 3 skills |
| **The Coder** | Task Executor | Code implementation, Test writing, Edge case handling | 4 skills |
| **The Gatekeeper** | Code Reviewer | Code review, Security scanning, Quality enforcement | 3 skills |
| **The Grid Master** | DevOps Engineer | CloudFormation/Terraform, IAM, CI/CD pipelines, Observability | 6 skills |

### Agent Being Removed

| Agent | Action | Impact |
|-------|--------|--------|
| **The Nexus** | Delete | The Mind will consume requirements directly; no PRP layer needed |

### Agent Being Skipped

| Agent | Reason |
|-------|--------|
| **The Operator** | Meta-agent that generates outputs for others; its functionality is better suited as part of agent initialization rather than skills |

---

## Skill Organization by Domain

Skills will be organized by domain rather than by agent:

```
templates/skills/
├── architecture/           # System design and planning
├── data/                   # Data storage and modeling
├── api/                    # API design and implementation
├── infrastructure/         # AWS/Infrastructure as Code
├── security/               # IAM, security best practices
├── testing/                # Testing strategies and patterns
├── frontend/               # Frontend development (existing)
├── bundling/               # Build/bundling (existing)
└── programming/            # Code patterns (existing)
```

---

## Recommended New Skills

### Architecture Domain

#### 1. `skills/architecture/system-design.md`
**Purpose**: Design component-based systems with clear interfaces and data flows

**When to Use**:
- Creating system architecture from requirements
- Defining component responsibilities and boundaries
- Designing data flow patterns
- Establishing interface contracts

**Inputs**:
- `requirements` (required) - Functional and non-functional requirements
- `constraints` (optional) - Technical constraints (budget, latency, scale)
- `existing_systems` (optional) - Systems to integrate with

**Outputs**:
- Component diagram
- Interface definitions
- Data flow description
- Technology recommendations

---

#### 2. `skills/architecture/risk-assessment.md`
**Purpose**: Systematically identify and assess technical risks

**When to Use**:
- Before committing to technical decisions
- During planning phases
- When evaluating third-party dependencies

**Inputs**:
- `technical_plan` (required) - Plan or design to assess
- `risk_categories` (optional) - Specific areas to focus on

**Outputs**:
- Risk register with severity/impact
- Mitigation strategies
- Contingency plans

---

### Data Domain

#### 3. `skills/data/dynamodb-design.md`
**Purpose**: Design DynamoDB tables with proper key structures and access patterns

**When to Use**:
- Creating new DynamoDB tables
- Modeling data for single-table design
- Defining GSIs and LSIs
- Optimizing for specific access patterns

**Inputs**:
- `access_patterns` (required) - List of read/write patterns needed
- `entities` (required) - Entities and relationships to model
- `capacity_requirements` (optional) - Read/write capacity needs

**Outputs**:
- Table structure with PK/SK design
- GSI definitions
- Access pattern mapping
- CloudFormation/Terraform snippets

---

#### 4. `skills/data/api-gateway-design.md`
**Purpose**: Design REST/HTTP APIs with API Gateway

**When to Use**:
- Creating new API endpoints
- Defining resource structures
- Configuring authentication/authorization
- Setting up request/response transformations

**Inputs**:
- `endpoints` (required) - List of required endpoints
- `auth_requirements` (optional) - Auth method (IAM, Cognito, Lambda, etc.)
- `integration_type` (optional) - Lambda, HTTP, MOCK, etc.

**Outputs**:
- OpenAPI specification
- Resource and method definitions
- Integration configurations
- CloudFormation/Terraform snippets

---

### API Domain

#### 5. `skills/api/rest-api-design.md`
**Purpose**: Design RESTful APIs following best practices

**When to Use**:
- Defining API contracts
- Creating endpoint specifications
- Designing request/response schemas
- Establishing versioning strategies

**Inputs**:
- `resources` (required) - Domain resources to expose
- `operations` (required) - CRUD operations needed
- `versioning_strategy` (optional) - URL, header, or media type versioning

**Outputs**:
- Resource naming conventions
- Endpoint specifications
- HTTP method assignments
- Status code definitions
- Error response format

---

### Infrastructure Domain

#### 6. `skills/infrastructure/cloudformation-stacks.md`
**Purpose**: Organize CloudFormation stacks with proper dependencies and cross-stack references

**When to Use**:
- Setting up new infrastructure projects
- Organizing resources into logical stacks
- Managing stack dependencies
- Creating cross-stack references

**Inputs**:
- `resources` (required) - List of AWS resources needed
- `environment_count` (optional) - Number of environments (dev/staging/prod)
- `shared_resources` (optional) - Resources shared across environments

**Outputs**:
- Stack organization diagram
- Stack definitions with exports/imports
- Parameter configurations
- Deployment order

---

#### 7. `skills/infrastructure/cicd-pipelines.md`
**Purpose**: Design CI/CD pipelines with proper stages, gates, and deployment strategies

**When to Use**:
- Setting up new deployment pipelines
- Configuring multi-environment promotion
- Implementing quality gates
- Setting up rollback procedures

**Inputs**:
- `deployment_targets` (required) - Environments to deploy to
- `quality_gates` (optional) - Required checks (tests, security scans)
- `deployment_strategy` (optional) - Blue/green, canary, rolling, all-at-once

**Outputs**:
- Pipeline stage definitions
- Quality gate configurations
- Environment promotion flow
- Rollback procedures

---

#### 8. `skills/infrastructure/observability-setup.md`
**Purpose**: Configure logging, metrics, alarms, and dashboards

**When to Use**:
- Setting up monitoring for new services
- Defining SLIs/SLOs
- Creating alarm thresholds
- Building operational dashboards

**Inputs**:
- `services` (required) - Services to monitor
- `slos` (optional) - Service level objectives
- `alert_channels` (optional) - SNS topics, email, PagerDuty, etc.

**Outputs**:
- Log group configurations
- Metric definitions
- Alarm configurations
- Dashboard specifications

---

### Security Domain

#### 9. `skills/security/iam-policy-design.md`
**Purpose**: Design IAM policies following least privilege principles

**When to Use**:
- Creating roles for Lambda functions
- Setting up service-to-service permissions
- Defining user access policies
- Configuring cross-account access

**Inputs**:
- `principal` (required) - Entity needing access (Lambda, user, role)
- `required_actions` (required) - AWS actions needed
- `resource_scope` (optional) - Specific resources or wildcard

**Outputs**:
- Policy document with least-privilege permissions
- Trust policy (for roles)
- Permission boundary (if needed)

---

#### 10. `skills/security/code-security-scanning.md`
**Purpose**: Identify common security vulnerabilities in code

**When to Use**:
- During code reviews
- Before merging changes
- As part of CI/CD quality gates

**Inputs**:
- `code_diff` (required) - Code to review
- `language` (required) - Programming language
- `risk_level` (optional) - Minimum severity to report

**Outputs**:
- Security findings
- Risk severity classification
- Remediation recommendations

---

### Testing Domain

#### 11. `skills/testing/unit-testing-patterns.md`
**Purpose**: Write effective unit tests with proper structure and coverage

**When to Use**:
- Writing tests for pure functions
- Testing business logic
- Creating testable code structures

**Inputs**:
- `function_signature` (required) - Function to test
- `test_framework` (optional) - Jest, Vitest, pytest, etc.
- `coverage_target` (optional) - Target coverage percentage

**Outputs**:
- Test cases covering happy paths
- Edge case tests
- Error condition tests
- Mock/stub strategies

---

#### 12. `skills/testing/integration-testing.md`
**Purpose**: Design integration tests for external service interactions

**When to Use**:
- Testing database integrations
- Testing API client interactions
- Testing message queue handlers

**Inputs**:
- `integration_point` (required) - External service to test
- `test_scopes` (optional) - Test boundaries
- `mock_strategy` (optional) - LocalStack, testcontainers, mocks

**Outputs**:
- Integration test structure
- Setup/teardown procedures
- Test data strategies
- Assertion patterns

---

#### 13. `skills/testing/test-coverage-analysis.md`
**Purpose**: Analyze test coverage and identify gaps

**When to Use**:
- Reviewing test suites
- Meeting coverage thresholds (95%)
- Identifying untested code paths

**Inputs**:
- `coverage_report` (required) - Coverage data
- `threshold` (optional) - Minimum acceptable coverage
- `exclusions` (optional) - Patterns to exclude from analysis

**Outputs**:
- Coverage summary
- Gap analysis
- Recommendations for improvement

---

### Planning Domain

#### 14. `skills/planning/feasibility-analysis.md`
**Purpose**: Assess technical feasibility of proposed solutions

**When to Use**:
- Reviewing architecture proposals
- Evaluating new technology adoption
- Estimating implementation complexity

**Inputs**:
- `proposal` (required) - Technical proposal or plan
- `constraints` (optional) - Time, budget, team capacity
- `alternatives` (optional) - Alternative approaches to compare

**Outputs**:
- Feasibility assessment (feasible/at-risk/not-feasible)
- Complexity rating
- Resource requirements
- Risk factors

---

#### 15. `skills/planning/dependency-mapping.md`
**Purpose**: Map dependencies between tasks, components, or phases

**When to Use**:
- Creating project timelines
- Breaking work into phases
- Identifying critical paths

**Inputs**:
- `tasks` (required) - List of work items
- `dependencies` (optional) - Known dependencies
- `resources` (optional) - Available resources

**Outputs**:
- Dependency graph
- Critical path identification
- Parallelization opportunities
- Sequencing recommendations

---

### Task Management Domain

#### 16. `skills/tasks/user-story-writing.md`
**Purpose**: Write clear, actionable user stories with acceptance criteria

**When to Use**:
- Breaking epics into stories
- Defining requirements
- Creating backlog items

**Inputs**:
- `feature_description` (required) - Feature to implement
- `user_type` (required) - Target user persona
- `value_proposition` (required) - Business value

**Outputs**:
- User story in "As a... I want... so that..." format
- Acceptance criteria (Given/When/Then)
- Definition of done

---

#### 17. `skills/tasks/task-decomposition.md`
**Purpose**: Break work into independently executable tasks

**When to Use**:
- Decomposing stories into tasks
- Creating sprint backlog
- Estimating work

**Inputs**:
- `story` (required) - User story to decompose
- `max_task_size` (optional) - Maximum task size (e.g., "2 days")
- `task_types` (optional) - Types to create (dev, test, infra, docs)

**Outputs**:
- Task list with descriptions
- Task type classifications
- Estimated effort
- Dependencies between tasks

---

### Code Quality Domain

#### 18. `skills/quality/code-review-checklist.md`
**Purpose**: Systematic code review following functional programming and quality standards

**When to Use**:
- Reviewing code submissions
- Enforcing standards
- Gatekeeping merges

**Inputs**:
- `code_diff` (required) - Code to review
- `standards` (optional) - Project-specific standards
- `checklist_focus` (optional) - Areas to prioritize

**Outputs**:
- Review findings by category (Functional, Types, Tests, Security, Performance)
- Required actions
- Risk level assessment

---

---

## Agent Definition Improvements

### Current Structure Issues

The current agent definitions use a single **REFERENCES** section that mixes:
- Skill references (executable, domain-specific knowledge)
- Common principles (shared standards)
- Example files (local project references)

This conflation makes it unclear what agents can "execute" (skills) vs what they should "consult" (examples/principles).

### Proposed New Structure

Separate concerns with two distinct sections:

```markdown
## SKILLS
- ./skills/architecture/system-design.md
- ./skills/data/dynamodb-design.md
- ./skills/planning/risk-assessment.md

## REFERENCES
- ./_common-principles.md
- /examples/architecture/sample-system.md
```

#### SKILLS Section
- **Purpose**: Executable capabilities the agent can invoke
- **Content**: Skill files with clear inputs/outputs and actionable guidance
- **Semantics**: "When I need to do X, I use this skill"
- **Format**: Always points to `./skills/` directory

#### REFERENCES Section
- **Purpose**: Contextual examples and shared principles to consult
- **Content**: Example implementations, common principles, project-specific patterns
- **Semantics**: "For reference, look at these examples"
- **Format**: Can point to `./_common-principles.md`, `/examples/`, or project-specific files

### Benefits

1. **Semantic Clarity**: Agents know which resources are actionable skills vs reference material
2. **Tooling Support**: CLI/tools can validate that all SKILLS paths exist and follow skill format
3. **Dynamic Loading**: Agents can dynamically load skills based on task requirements
4. **Versioning**: Skills can be versioned independently of reference examples
5. **Composability**: Clear separation enables skill composition patterns

### Updated Agent Template

```markdown
# Agent Name

## ROLE
...

## INTERACTION
...

## INPUTS
...

## OUTPUT
...

## SKILLS
- ./skills/domain/skill-name.md
- ./skills/domain/another-skill.md

## REFERENCES
- ./_common-principles.md
- /examples/path/to/example.md
```

---

## Agent Updates Required

### 1. Remove The Nexus

**Action**: Delete [`templates/agents/nexus.md`](templates/agents/nexus.md)

**Rationale**: With improved models, the PRP (Product Requirement Prompt) layer is unnecessary. The Mind can work directly with client requirements.

### 2. Update The Mind

**Current INPUTS**:
```markdown
## INPUTS
- prp_document (required)
- existing_architecture (optional)
- constraints (optional)
- team_capabilities (optional)
- timeline_constraints (optional)
```

**New INPUTS**:
```markdown
## INPUTS
- client_requirements (required)
- existing_architecture (optional)
- constraints (optional)
- team_capabilities (optional)
- timeline_constraints (optional)
```

**Update INTERACTION**:
- Remove references to The Nexus
- Change: "Consumes PRP from The Nexus" → "Consumes client requirements directly"

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/architecture/system-design.md
- ./skills/architecture/risk-assessment.md
- ./skills/data/dynamodb-design.md
- ./skills/api/rest-api-design.md
- ./skills/data/api-gateway-design.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

### 3. Update The Interrogator

**Update INTERACTION**:
- Remove references to The Nexus
- Change: "Consumes plan from The Mind and PRP from The Nexus" → "Consumes plan from The Mind and original requirements"

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/planning/feasibility-analysis.md
- ./skills/planning/dependency-mapping.md
- ./skills/architecture/risk-assessment.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

### 4. Update The Fragmenter

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/tasks/user-story-writing.md
- ./skills/tasks/task-decomposition.md
- ./skills/planning/dependency-mapping.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

### 5. Update The Coder

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/testing/unit-testing-patterns.md
- ./skills/testing/integration-testing.md
- ./skills/programming/functional-programming.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

### 6. Update The Gatekeeper

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/quality/code-review-checklist.md
- ./skills/security/code-security-scanning.md
- ./skills/testing/test-coverage-analysis.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

### 7. Update The Grid Master

**Add SKILLS section**:
```markdown
## SKILLS
- ./skills/infrastructure/cloudformation-stacks.md
- ./skills/infrastructure/cicd-pipelines.md
- ./skills/infrastructure/observability-setup.md
- ./skills/security/iam-policy-design.md
- ./skills/lambda.md
```

**Keep REFERENCES section**:
```markdown
## REFERENCES
- ./_common-principles.md
```

---

## Implementation Phases

### Phase 1: Foundation (Agent Restructure)
1. Delete [`templates/agents/nexus.md`](templates/agents/nexus.md)
2. Update The Mind:
   - Change INPUTS from `prp_document` to `client_requirements`
   - Update INTERACTION (remove Nexus references)
   - Add new SKILLS and REFERENCES sections
3. Update The Interrogator:
   - Update INTERACTION (remove Nexus references)
   - Add new SKILLS and REFERENCES sections
4. Update The Fragmenter, The Coder, The Gatekeeper, The Grid Master:
   - Add new SKILLS and REFERENCES sections
   - Keep REFERENCES for `_common-principles.md`

### Phase 2: Core Planning Skills
1. Create `skills/architecture/system-design.md`
2. Create `skills/architecture/risk-assessment.md`
3. Create `skills/planning/feasibility-analysis.md`
4. Create `skills/planning/dependency-mapping.md`
5. Update The Mind and The Interrogator with SKILLS sections

### Phase 3: Data & API Skills
1. Create `skills/data/dynamodb-design.md`
2. Create `skills/data/api-gateway-design.md`
3. Create `skills/api/rest-api-design.md`
4. Update The Mind with SKILLS section

### Phase 4: Infrastructure Skills
1. Create `skills/infrastructure/cloudformation-stacks.md`
2. Create `skills/infrastructure/cicd-pipelines.md`
3. Create `skills/infrastructure/observability-setup.md`
4. Create `skills/security/iam-policy-design.md`
5. Update The Grid Master with SKILLS section

### Phase 5: Testing & Quality Skills
1. Create `skills/testing/unit-testing-patterns.md`
2. Create `skills/testing/integration-testing.md`
3. Create `skills/testing/test-coverage-analysis.md`
4. Create `skills/quality/code-review-checklist.md`
5. Create `skills/security/code-security-scanning.md`
6. Update The Coder and The Gatekeeper with SKILLS sections

### Phase 6: Task Management Skills
1. Create `skills/tasks/user-story-writing.md`
2. Create `skills/tasks/task-decomposition.md`
3. Update The Fragmenter with SKILLS section

---

## Summary

**Total New Skills**: 18
**Agents Updated**: 6 (excluding Operator which is skipped)
**Agents Removed**: 1 (The Nexus)

**Existing Skills to Keep**: 5
- `skills/lambda.md`
- `skills/functional-programming.md`
- `skills/bundling-frontend.md`
- `skills/bundling-node-services.md`
- `skills/frontend-hosting.md`

**Total Skills After Implementation**: 23

---

## Next Steps

1. Review this plan and approve the approach
2. Switch to **Code** mode to implement Phase 1 (agent restructure)
3. Implement skills by phase
4. Update agent definitions with skill references
5. Test the updated agent system
