# ContextRunners - Cyberpunk Development System

A structured agent system for software development using functional programming patterns and AWS infrastructure.

## Overview

This system provides 7 specialized agents that work together to transform business requirements into production-ready code:

- **The Nexus** - Creates Product Requirement Prompts (PRPs) from business needs
- **The Mind** - Designs technical architecture and system plans
- **The Interrogator** - Reviews and validates plans for completeness
- **The Fragmenter** - Breaks down plans into executable development tasks
- **The Coder** - Implements code using functional programming patterns
- **The Gatekeeper** - Reviews code quality and validates implementations
- **The Grid Master** - Manages infrastructure and deployment pipelines

## Setup Instructions

### 1. Copy Agent Definitions

Copy the `agents/` directory to your project root or a designated location:

```bash
cp -r agents/ /path/to/your/project/
```

### 2. Configure Language and Framework Settings

Replace the configuration placeholders in all agent files with your project-specific values:

#### Language Configuration
- `{configured_language}` → Your programming language (e.g., `typescript`, `python`, `go`)
- `{configured_frontend_framework}` → Your frontend framework (e.g., `react`, `vue`, `svelte`)
- `{configured_test_framework}` → Your testing framework (e.g., `jest`, `vitest`, `pytest`)

#### Build Tools Configuration
- `{configured_package_manager}` → Your package manager (e.g., `npm`, `pnpm`, `yarn`)
- `{configured_monorepo_runner}` → Your monorepo tool (e.g., `turbo`, `nx`, `lerna`)
- `{configured_lint_command}` → Your linting command (e.g., `lint`, `eslint`)
- `{configured_format_command}` → Your formatting command (e.g., `format`, `prettier`)
- `{configured_test_command}` → Your test command (e.g., `test`, `test:unit`)
- `{configured_build_command}` → Your build command (e.g., `build`, `compile`)
- `{configured_audit_command}` → Your security audit command (e.g., `audit`, `security-check`)

### 3. Project Structure Configuration

Update directory placeholders:
- `{project-name}` → Your actual project name
- `{app_directory}` → Your application directory structure

### 4. Example Configuration Script

Create a setup script to automate the configuration:

```bash
#!/bin/bash
# setup-agents.sh

PROJECT_NAME="your-project-name"
LANGUAGE="typescript"
FRONTEND_FRAMEWORK="react"
TEST_FRAMEWORK="jest"
PACKAGE_MANAGER="npm"

# Replace placeholders in all agent files
find agents/ -name "*.md" -exec sed -i "s/{configured_language}/$LANGUAGE/g" {} \;
find agents/ -name "*.md" -exec sed -i "s/{configured_frontend_framework}/$FRONTEND_FRAMEWORK/g" {} \;
find agents/ -name "*.md" -exec sed -i "s/{configured_test_framework}/$TEST_FRAMEWORK/g" {} \;
find agents/ -name "*.md" -exec sed -i "s/{configured_package_manager}/$PACKAGE_MANAGER/g" {} \;
find agents/ -name "*.md" -exec sed -i "s/{project-name}/$PROJECT_NAME/g" {} \;

echo "Agent configuration completed for $PROJECT_NAME"
```

### 5. Create Project-Specific Examples

Create an `examples/` directory structure for your project:

```
examples/
├── infrastructure/          # AWS CloudFormation templates
│   ├── lambda-api-stack.md
│   ├── dynamodb-stack.md
│   └── deployment-scripts.md
├── PRPs/                   # Product Requirement Prompts
│   └── your-feature.md
└── configuration/          # Project-specific configs
    ├── database-tables/
    ├── common-packages/
    └── apps/
```

### 6. Database Documentation

Document your DynamoDB tables in `examples/database-tables/`:
- Entity relationships and access patterns
- Table schemas and indexes
- Query patterns and performance considerations

### 7. Package Documentation

Document your shared libraries in `examples/common-packages/`:
- Authentication utilities
- AWS integration helpers
- Database access libraries
- Utility functions

## Usage Workflow

### 1. Requirements Gathering
Start with **The Nexus** to create a PRP from business requirements:
```
Input: Raw business requirements
Output: Structured Product Requirement Prompt
```

### 2. Technical Planning
Use **The Mind** to design system architecture:
```
Input: PRP from The Nexus
Output: Technical architecture and implementation plan
```

### 3. Plan Validation
**The Interrogator** reviews and validates the plan:
```
Input: Technical plan from The Mind
Output: Approved plan or revision requests
```

### 4. Task Breakdown
**The Fragmenter** creates actionable development tasks:
```
Input: Approved plan from The Interrogator
Output: Granular development tasks with dependencies
```

### 5. Implementation
**The Coder** implements the actual code:
```
Input: Development tasks from The Fragmenter
Output: Functional code with comprehensive tests
```

### 6. Quality Assurance
**The Gatekeeper** reviews code quality:
```
Input: Code and tests from The Coder
Output: Approval or revision requests
```

### 7. Infrastructure & Deployment
**The Grid Master** handles infrastructure and deployment:
```
Input: Infrastructure requirements
Output: CloudFormation templates and deployment pipelines
```

## Functional Programming Principles

All agents follow these core principles:
- **Pure Functions** - No side effects, predictable outputs
- **Immutability** - Data structures are never modified in place
- **Function Composition** - Complex operations built from simple functions
- **Error Handling** - Result types instead of exceptions
- **Type Safety** - Strong typing where language supports it

## Quality Standards

### Code Quality Gates
- Linting with functional programming rules
- Code formatting validation
- Security vulnerability scanning
- Build verification
- Test coverage ≥95%

### Testing Requirements
- Unit tests for all pure functions (100% coverage)
- Integration tests for AWS services
- Component tests for UI elements
- Property-based testing where applicable

## AWS Integration

The system is designed for AWS-first development:
- Lambda functions for serverless compute
- DynamoDB for data persistence
- API Gateway for REST endpoints
- CloudFormation for infrastructure as code
- CloudWatch for monitoring and logging

## Contributing

When adding new agents or modifying existing ones:
1. Maintain the cyberpunk naming convention
2. Follow the structured input/output format
3. Include validation criteria and interaction patterns
4. Provide configuration examples
5. Keep functional programming principles central

## Support

For issues or questions about the agent system, refer to your project's specific configuration and examples directory.
