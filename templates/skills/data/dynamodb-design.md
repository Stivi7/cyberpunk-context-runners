# Skill: DynamoDB Design

## PURPOSE
Design efficient DynamoDB tables using single-table design principles, optimizing for known access patterns while maintaining scalability and cost-effectiveness.

## WHEN TO USE
- Creating new DynamoDB tables
- Modeling data for single-table design
- Defining GSIs and LSIs
- Optimizing for specific access patterns
- Migrating from relational to NoSQL

## INPUTS
- `access_patterns` (required) - List of read/write patterns needed
- `entities` (required) - Entities and relationships to model
- `capacity_requirements` (optional) - Expected read/write throughput

## SINGLE-TABLE DESIGN PRINCIPLES

### Core Concept
Store multiple entity types in one table, using composite keys to enable efficient access patterns.

```
┌────────────────────────────────────────────────────────────────┐
│                    DynamoDB Table                              │
├──────────────┬──────────────┬────────────────┬─────────────────┤
│     PK       │     SK       │   Attributes   │      GSI1       │
├──────────────┼──────────────┼────────────────┼─────────────────┤
│ USER#123     │ PROFILE      │ name, email    │                 │
│ USER#123     │ ORDER#456    │ total, status  │                 │
│ USER#123     │ ORDER#789    │ total, status  │                 │
│ ORDER#456    │ ORDERMETA    │ items, date    │ STATUS#pending  │
│ PRODUCT#001  │ PRODUCTMETA  │ name, price    │ CATEGORY#tech   │
└──────────────┴──────────────┴────────────────┴─────────────────┘
```

### Key Design

**Partition Key (PK)**
- Determines data distribution across partitions
- Format: `ENTITYTYPE#ID`
- Examples: `USER#123`, `ORDER#456`, `PRODUCT#abc`

**Sort Key (SK)**
- Enables range queries within a partition
- Enables hierarchical data organization
- Format: `TYPE#ID` or `METADATA`
- Examples: `PROFILE`, `ORDER#456`, `COMMENT#789`

### Access Pattern Mapping

Before designing, list ALL access patterns:

| Access Pattern | Query Type | Key Condition |
|----------------|------------|---------------|
| Get user by ID | GetItem | PK = USER#id |
| Get user's orders | Query | PK = USER#id, SK begins_with ORDER# |
| Get order details | GetItem | PK = ORDER#id, SK = ORDERMETA |
| Get pending orders | Query GSI1 | GSI1PK = STATUS#pending |

## DESIGN PATTERNS

### Pattern 1: One-to-Many (Hierarchical)
One user has many orders.

```yaml
Table:
  - PK: USER#123, SK: PROFILE
    name: "Alice", email: "alice@example.com"
  - PK: USER#123, SK: ORDER#001
    total: 100, status: "complete"
  - PK: USER#123, SK: ORDER#002
    total: 200, status: "pending"

Query "Get user's orders":
  PK = "USER#123" AND SK begins_with "ORDER#"
```

### Pattern 2: Many-to-Many (Adjacency List)
Users belong to multiple groups, groups have multiple users.

```yaml
Table:
  # User's memberships
  - PK: USER#123, SK: GROUP#A
    role: "admin"
  - PK: USER#123, SK: GROUP#B
    role: "member"

  # Group's members
  - PK: GROUP#A, SK: USER#123
    role: "admin"
  - PK: GROUP#A, SK: USER#456
    role: "member"

Query "Get user's groups": PK = "USER#123", SK begins_with "GROUP#"
Query "Get group's users": PK = "GROUP#A", SK begins_with "USER#"
```

### Pattern 3: Global Secondary Index (GSI) for Alternate Access
Query by status instead of user.

```yaml
Table:
  - PK: ORDER#001, SK: ORDERMETA
    status: "pending"
    GSI1PK: STATUS#pending
    GSI1SK: 2024-01-01

GSI1:
  PK: GSI1PK
  SK: GSI1SK

Query "Get pending orders":
  Index: GSI1
  PK = "STATUS#pending"
```

## KEY DESIGN BEST PRACTICES

### PK Design
- **High cardinality**: Many distinct values for even distribution
- **Uniform access**: Avoid hot partitions
- **Meaningful**: Include entity type prefix
- **Immutable**: Don't use values that change

### SK Design
- **Hierarchical**: Enable range queries
- **Sortable**: Use formats that sort correctly
  - Dates: `2024-01-15` (not `1/15/24`)
  - Versions: `v0001` (not `v1`)
- **Queryable**: Support begins_with operations

### Example Key Structures

```yaml
# E-commerce
PK: USER#123
SK: ORDER#456

PK: ORDER#456
SK: ORDERMETA

PK: PRODUCT#ABC
SK: PRODUCTMETA

# Social Media
PK: USER#123
SK: POST#456

PK: POST#456
SK: COMMENT#789

PK: USER#123
SK: FOLLOWS#456  # Users user 123 follows
```

## CAPACITY PLANNING

### On-Demand vs Provisioned

**On-Demand**
- Pay per request
- No capacity planning needed
- Good for: Unknown/unpredictable workloads, dev environments
- Cost: Higher per-request, but no over-provisioning waste

**Provisioned**
- Set RCU/WCU limits
- Requires monitoring and scaling
- Good for: Predictable workloads, cost optimization at scale
- Cost: Lower per-request with steady usage

### Estimating Capacity

```
Read Capacity Units (RCU):
- Strongly consistent: 4KB = 1 RCU
- Eventually consistent: 4KB = 0.5 RCU
- Transactional: 4KB = 2 RCU

Write Capacity Units (WCU):
- Standard: 1KB = 1 WCU
- Transactional: 1KB = 2 WCU
```

## CLOUDFORMATION EXAMPLE

```yaml
MyTable:
  Type: AWS::DynamoDB::Table
  Properties:
    TableName: !Sub "${StackName}-MyTable"
    BillingMode: PAY_PER_REQUEST  # or PROVISIONED
    AttributeDefinitions:
      - AttributeName: PK
        AttributeType: S
      - AttributeName: SK
        AttributeType: S
      - AttributeName: GSI1PK
        AttributeType: S
      - AttributeName: GSI1SK
        AttributeType: S
    KeySchema:
      - AttributeName: PK
        KeyType: HASH
      - AttributeName: SK
        KeyType: RANGE
    GlobalSecondaryIndexes:
      - IndexName: GSI1
        KeySchema:
          - AttributeName: GSI1PK
            KeyType: HASH
          - AttributeName: GSI1SK
            KeyType: RANGE
        Projection:
          ProjectionType: ALL
    PointInTimeRecoverySpecification:
      PointInTimeRecoveryEnabled: true
    SSESpecification:
      SSEEnabled: true
```

## COMMON ANTI-PATTERNS

### ❌ Hot Partitions
```yaml
# Bad: All orders for today have same PK
PK: DATE#2024-01-01
SK: ORDER#001

# Good: Distribute across partitions
PK: ORDER#001
SK: ORDERMETA
GSI1PK: DATE#2024-01-01
```

### ❌ GSI Over-Projection
```yaml
# Bad: Projecting ALL when only need 2 fields
ProjectionType: ALL

# Good: Project only needed attributes
Projection:
  ProjectionType: INCLUDE
  NonKeyAttributes: [status, total]
```

### ❌ Missing Entity Prefix
```yaml
# Bad: Can't distinguish entity types
PK: 123

# Good: Clear entity type
PK: USER#123
```

## OUTPUT

### DynamoDB Design Document

```markdown
## Access Patterns
| Pattern | Type | Description |
|---------|------|-------------|
| [Name] | GetItem/Query/Scan | [Description] |

## Table Schema
- **Table Name**: [Name]
- **Billing Mode**: [On-Demand/Provisioned]

### Key Schema
| Key | Attribute | Type | Format |
|-----|-----------|------|--------|
| PK | [name] | S | ENTITY#id |
| SK | [name] | S | TYPE#id |

### Global Secondary Indexes
| Index | PK | SK | Purpose |
|-------|----|----|---------|
| GSI1 | [attr] | [attr] | [Access pattern] |

## Entity Mapping
| Entity | PK Format | SK Format | Attributes |
|--------|-----------|-----------|------------|
| [Entity] | [Format] | [Format] | [List] |

## Query Examples
```javascript
// Get user by ID
{ PK: "USER#123", SK: "PROFILE" }

// Get user's orders
{ PK: "USER#123", SK: { begins_with: "ORDER#" } }
```

## CloudFormation Snippet
[YAML snippet]
```
