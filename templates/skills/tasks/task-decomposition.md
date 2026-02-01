# Skill: Task Decomposition

## PURPOSE
Break user stories into independently executable tasks that can be assigned, tracked, and completed within a sprint.

## WHEN TO USE
- Decomposing stories into tasks
- Creating sprint backlog
- Estimating work
- Assigning work to team members

## INPUTS
- `story` (required) - User story to decompose
- `max_task_size` (optional) - Maximum task size (default: "2 days")
- `task_types` (optional) - [dev, test, infra, docs]

## TASK TYPES

| Type | Description | Example |
|------|-------------|---------|
| **dev** | Development work | Implement API endpoint |
| **test** | Testing activities | Write unit tests |
| **infra** | Infrastructure | Setup DynamoDB table |
| **docs** | Documentation | Update API docs |

## DECOMPOSITION PATTERNS

### By Layer
```
Story: User login feature
├── [dev] Create login API endpoint
├── [dev] Implement password validation
├── [test] Write unit tests for validation
├── [infra] Setup Cognito user pool
└── [docs] Document login API
```

### By Component
```
Story: Order processing
├── [dev] Order validation logic
├── [dev] Payment integration
├── [dev] Order confirmation email
├── [test] Payment flow tests
└── [infra] SQS queue for async processing
```

## TASK SIZE GUIDELINES

| Size | Duration | Indicators |
|------|----------|------------|
| **Small** | < 4 hours | Single function/method |
| **Medium** | 4 hours - 1 day | Multiple related functions |
| **Large** | 1-2 days | Complex feature slice |
| **Too Big** | > 2 days | Break down further |

## TASK TEMPLATE

```markdown
## Task: [Title]
- **Type**: [dev/test/infra/docs]
- **Estimated**: [X hours/days]
- **Assignee**: [Name or unassigned]

### Description
[What needs to be done]

### Acceptance Criteria
- [ ] [Specific, testable outcome]

### Dependencies
- [ ] [Task that must complete first]

### Notes
- [Implementation notes]
- [Links to designs/specs]
```

## OUTPUT

```markdown
## Story Breakdown: [Story Title]

### Tasks
| # | Task | Type | Estimate | Dependencies |
|---|------|------|----------|--------------|
| 1 | [Task 1] | dev | 1d | - |
| 2 | [Task 2] | test | 4h | #1 |

### Critical Path
[Task sequence that determines duration]

### Total Estimate
[X days]
```
