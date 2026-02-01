# Skill: System Design

## PURPOSE
Design component-based systems with clear interfaces, responsibilities, and data flows that align with functional programming principles and AWS serverless architecture.

## WHEN TO USE
- Creating system architecture from requirements
- Defining component boundaries and responsibilities
- Designing data flow patterns between services
- Establishing interface contracts for APIs and events

## INPUTS
- `requirements` (required) - Functional and non-functional requirements
- `constraints` (optional) - Technical constraints (budget, latency, scale)
- `existing_systems` (optional) - Systems to integrate with

## SYSTEM DESIGN PRINCIPLES

### Component Boundaries
Define clear, single-responsibility components:

```
┌─────────────────────────────────────────────────────────────┐
│                      System Context                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   API Layer  │───▶│  Business    │───▶│  Data Layer  │  │
│  │  (Lambda/    │    │  Logic       │    │  (DynamoDB)  │  │
│  │   API GW)    │◀───│  (Lambda)    │◀───│              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  Event Bus   │    │   External   │    │   Storage    │  │
│  │  (EventBridge│    │   Services   │    │   (S3)       │  │
│  │   /SNS)      │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

Each component should have ONE primary responsibility:

**API Layer**
- Request validation and transformation
- Authentication/authorization checks
- Response formatting
- Error handling and status codes

**Business Logic Layer**
- Pure function implementations
- Business rule enforcement
- Workflow orchestration
- Event publishing

**Data Layer**
- Data persistence operations
- Query optimization
- Transaction management
- Data model enforcement

### Interface Design

**Synchronous APIs (Request/Response)**
```yaml
# REST API Contract
GET /resources/{id}:
  input:
    path_params: { id: string }
    headers: { Authorization: string }
  output:
    success (200):
      body: Resource
    not_found (404):
      body: { error: string }
    unauthorized (401):
      body: { error: string }
```

**Asynchronous Events (Event-Driven)**
```yaml
# Event Contract
Event: ResourceCreated
  producer: BusinessLogicLayer
  consumers: [AnalyticsService, NotificationService]
  payload:
    resourceId: string
    resourceType: string
    timestamp: ISO8601
    metadata: object
```

### Data Flow Patterns

**Pattern 1: Command Flow**
```
Client → API Gateway → Lambda (Command) → DynamoDB → EventBridge → Consumers
```

**Pattern 2: Query Flow**
```
Client → API Gateway → Lambda (Query) → DynamoDB → Response
```

**Pattern 3: Event-Driven Flow**
```
Source Service → EventBridge → Lambda (Handler) → Target Service
```

## AWS SERVERLESS ARCHITECTURE

### Standard Components

**Compute**
- Lambda functions for business logic
- Lambda layers for shared code
- Step Functions for workflows

**API**
- API Gateway for REST endpoints
- AppSync for GraphQL
- Function URLs for simple HTTP

**Data**
- DynamoDB for primary data store
- S3 for object storage
- ElastiCache for caching (if needed)

**Events**
- EventBridge for event routing
- SNS for pub/sub
- SQS for queuing

**Observability**
- CloudWatch Logs
- X-Ray for tracing
- CloudWatch Alarms

## DECISION GUIDELINES

### When to Use Sync vs Async

**Use Synchronous When:**
- Client needs immediate response
- Operation is fast (< 3 seconds)
- Strong consistency is required
- Failure must be known immediately

**Use Asynchronous When:**
- Operation is long-running
- Eventual consistency is acceptable
- Multiple consumers needed
- Decoupling is priority

### Component Size Guidelines

**Too Small (Anti-pattern)**
- Functions < 50 lines
- Excessive network calls between components
- Hard to understand flow

**Too Large (Anti-pattern)**
- Functions > 500 lines
- Multiple responsibilities
- Hard to test and maintain

**Just Right**
- Single responsibility
- 100-300 lines per function
- Clear inputs and outputs
- Testable in isolation

## OUTPUT

### System Architecture Document
```markdown
## Context
[One-paragraph overview of what the system does]

## Components
| Component | Responsibility | Technology |
|-----------|---------------|------------|
| [Name] | [Single sentence] | [AWS Service] |

## Data Flows
1. [Flow name]: [Source] → [Destination]
   - Trigger: [What starts this flow]
   - Data: [What data moves]
   - Latency: [Expected time]

## Interfaces
### API Endpoints
- `METHOD /path`: [Description]

### Events
- `EventName`: [Producer] → [Consumers]

## Technology Choices
- [Service]: [Rationale for selection]
```
