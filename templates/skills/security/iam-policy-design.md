# Skill: IAM Policy Design

## PURPOSE
Design AWS IAM policies following the principle of least privilege, ensuring secure access control for users, roles, and services.

## WHEN TO USE
- Creating roles for Lambda functions
- Setting up service-to-service permissions
- Defining user access policies
- Configuring cross-account access
- Setting up permission boundaries

## INPUTS
- `principal` (required) - Entity needing access (Lambda, user, role)
- `required_actions` (required) - AWS actions needed
- `resource_scope` (optional) - Specific resources or wildcard

## LEAST PRIVILEGE PRINCIPLES

### 1. Start with No Permissions
Begin with empty policy, add only what's needed.

### 2. Use Specific Actions
Avoid wildcards when possible:

```json
// ❌ Too broad
"Action": "dynamodb:*"

// ✅ Specific actions
"Action": [
  "dynamodb:GetItem",
  "dynamodb:PutItem",
  "dynamodb:Query"
]
```

### 3. Use Specific Resources
Reference exact ARNs:

```json
// ❌ Too broad
"Resource": "*"

// ✅ Specific resource
"Resource": "arn:aws:dynamodb:us-east-1:123456789:table/MyTable"
```

### 4. Use Condition Keys
Add extra security with conditions:

```json
"Condition": {
  "StringEquals": {
    "aws:SourceAccount": "123456789"
  },
  "IpAddress": {
    "aws:SourceIp": ["10.0.0.0/8"]
  }
}
```

## COMMON POLICY PATTERNS

### Lambda Execution Role

```yaml
LambdaExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    RoleName: !Sub "${FunctionName}-execution-role"
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: lambda.amazonaws.com
          Action: sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    Policies:
      - PolicyName: DynamoDBAccess
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - dynamodb:GetItem
                - dynamodb:PutItem
                - dynamodb:UpdateItem
                - dynamodb:DeleteItem
                - dynamodb:Query
              Resource: !GetAtt MyTable.Arn
            - Effect: Allow
              Action:
                - dynamodb:Query
              Resource: !Sub "${MyTable.Arn}/index/*"
```

### Cross-Account Access

```yaml
CrossAccountRole:
  Type: AWS::IAM::Role
  Properties:
    RoleName: CrossAccountAccess
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            AWS: arn:aws:iam::987654321:root
          Action: sts:AssumeRole
          Condition:
            StringEquals:
              sts:ExternalId: !Ref ExternalId
```

### Service-Linked Role

```yaml
ApiGatewayLoggingRole:
  Type: AWS::IAM::Role
  Properties:
    RoleName: ApiGatewayLoggingRole
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: apigateway.amazonaws.com
          Action: sts:AssumeRole
    Policies:
      - PolicyName: CloudWatchLogs
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - logs:CreateLogGroup
                - logs:CreateLogStream
                - logs:DescribeLogGroups
                - logs:DescribeLogStreams
                - logs:PutLogEvents
                - logs:GetLogEvents
                - logs:FilterLogEvents
              Resource: "*"
```

## POLICY DOCUMENT STRUCTURE

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UniqueStatementId",
      "Effect": "Allow|Deny",
      "Action": [
        "service:Action"
      ],
      "Resource": [
        "arn:aws:service:region:account:resource"
      ],
      "Condition": {
        "StringEquals|IpAddress|...": {
          "key": "value"
        }
      }
    }
  ]
}
```

## COMMON CONDITIONS

### Source IP Restrictions
```json
"Condition": {
  "IpAddress": {
    "aws:SourceIp": ["10.0.0.0/8", "192.168.0.0/16"]
  }
}
```

### VPC Endpoint Restrictions
```json
"Condition": {
  "StringEquals": {
    "aws:VpcSourceIp": ["10.0.1.0/24"]
  }
}
```

### Time-Based Restrictions
```json
"Condition": {
  "DateGreaterThan": {
    "aws:CurrentTime": "2024-01-01T00:00:00Z"
  },
  "DateLessThan": {
    "aws:CurrentTime": "2024-12-31T23:59:59Z"
  }
}
```

### MFA Requirement
```json
"Condition": {
  "Bool": {
    "aws:MultiFactorAuthPresent": "true"
  }
}
```

## PERMISSION BOUNDARIES

Set maximum permissions a role can have:

```yaml
PermissionBoundary:
  Type: AWS::IAM::ManagedPolicy
  Properties:
    PolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Action:
            - logs:*
            - dynamodb:*
            - s3:GetObject
            - s3:PutObject
          Resource: "*"
        - Effect: Deny
          Action:
            - iam:*
            - sts:AssumeRole
          Resource: "*"

DeveloperRole:
  Type: AWS::IAM::Role
  Properties:
    PermissionsBoundary: !Ref PermissionBoundary
    # ... other properties
```

## OUTPUT

### IAM Policy Document

```markdown
## Role: [Name]
- **Type**: [Lambda/User/Service]
- **Trust Policy**: [Who can assume]

## Permissions
| Service | Actions | Resource | Condition |
|---------|---------|----------|-----------|
| DynamoDB | GetItem, PutItem | Table ARN | None |

## Permission Boundary
[If applicable]

## CloudFormation
```yaml
[YAML snippet]
```
```
