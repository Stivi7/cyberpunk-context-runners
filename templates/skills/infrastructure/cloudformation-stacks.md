# Skill: CloudFormation Stack Design

## PURPOSE
Organize AWS resources into logical CloudFormation stacks with proper dependencies, cross-stack references, and modular architecture for maintainable infrastructure.

## WHEN TO USE
- Setting up new infrastructure projects
- Organizing resources into logical stacks
- Managing stack dependencies
- Creating cross-stack references
- Designing multi-environment deployments

## INPUTS
- `resources` (required) - List of AWS resources needed
- `environment_count` (optional) - Number of environments (dev/staging/prod)
- `shared_resources` (optional) - Resources shared across environments

## STACK ORGANIZATION STRATEGIES

### Strategy 1: Layer-Based Stacks
Separate by infrastructure layer:

```
stacks/
├── network.yaml          # VPC, subnets, routing
├── data.yaml             # DynamoDB, S3, RDS
├── compute.yaml          # Lambda, ECS, EC2
├── api.yaml              # API Gateway, ALB
├── security.yaml         # IAM, WAF, KMS
└── monitoring.yaml       # CloudWatch, alarms
```

**Pros**: Clear boundaries, team ownership, independent updates
**Cons**: Many cross-stack references

### Strategy 2: Service-Based Stacks
Separate by business service:

```
stacks/
├── users-service.yaml
├── orders-service.yaml
├── payments-service.yaml
└── shared-infrastructure.yaml
```

**Pros**: Service autonomy, independent lifecycles
**Cons**: Duplicated infrastructure patterns

### Strategy 3: Environment + Shared
Environment-specific + shared resources:

```
stacks/
├── shared/
│   ├── dns.yaml          # Route53, certificates
│   ├── cicd.yaml         # CodePipeline, CodeBuild
│   └── backup.yaml       # Backup vaults, cross-region
├── dev.yaml              # All dev resources
├── staging.yaml          # All staging resources
└── prod.yaml             # All prod resources
```

**Pros**: Simple environment isolation, shared resources
**Cons**: Large stack files, less granular updates

## RECOMMENDED APPROACH: Hybrid

Combine layer-based with environment separation:

```
stacks/
├── shared/
│   ├── dns.yaml
│   ├── iam-roles.yaml    # Cross-account roles
│   └── cicd.yaml
├── network/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
├── data/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
└── compute/
    ├── dev.yaml
    ├── staging.yaml
    └── prod.yaml
```

## CROSS-STACK REFERENCES

### Export from Stack A
```yaml
Outputs:
  VpcId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub "${StackName}-VpcId"

  DynamoDBTableArn:
    Description: DynamoDB Table ARN
    Value: !GetAtt MyTable.Arn
    Export:
      Name: !Sub "${StackName}-TableArn"
```

### Import into Stack B
```yaml
Parameters:
  NetworkStackName:
    Type: String
    Description: Name of network stack

Resources:
  LambdaFunction:
    Type: AWS::Lambda::Function
    Properties:
      VpcConfig:
        SubnetIds:
          - Fn::ImportValue: !Sub "${NetworkStackName}-PrivateSubnet1"
          - Fn::ImportValue: !Sub "${NetworkStackName}-PrivateSubnet2"
```

## STACK PARAMETERS

Use parameters for environment-specific values:

```yaml
Parameters:
  Environment:
    Type: String
    AllowedValues:
      - dev
      - staging
      - prod
    Description: Deployment environment

  LogRetentionDays:
    Type: Number
    Default: 7
    AllowedValues:
      - 1
      - 3
      - 7
      - 30
      - 90
    Description: CloudWatch log retention

  EnableDetailedMonitoring:
    Type: String
    Default: false
    AllowedValues:
      - true
      - false
    Description: Enable detailed monitoring (prod only)

Conditions:
  IsProd: !Equals [!Ref Environment, prod]
  EnableMonitoring: !Equals [!Ref EnableDetailedMonitoring, true]
```

## STACK DEPLOYMENT ORDER

```
Deployment Sequence:

1. shared/dns.yaml
   └── Exports: HostedZoneId, CertificateArn

2. network/{env}.yaml
   └── Exports: VpcId, SubnetIds, SecurityGroupIds

3. data/{env}.yaml
   └── Exports: TableArns, BucketArns

4. compute/{env}.yaml
   └── Imports: Network, Data resources
   └── Exports: LambdaArns, FunctionNames

5. api/{env}.yaml
   └── Imports: Compute resources
```

## CLOUDFORMATION BEST PRACTICES

### 1. Use Meaningful Resource Names
```yaml
# Good - Includes service and environment
FunctionName: !Sub "${ServiceName}-${Environment}-handler"

# Bad - Generic names
FunctionName: !Ref AWS::StackName
```

### 2. Tag Everything
```yaml
Tags:
  - Key: Environment
    Value: !Ref Environment
  - Key: Service
    Value: !Ref ServiceName
  - Key: ManagedBy
    Value: CloudFormation
  - Key: CostCenter
    Value: !Ref CostCenterTag
```

### 3. Enable Termination Protection (Prod)
```yaml
StackPolicy:
  Statement:
    - Effect: DENY
      Action:
        - Update:Delete
        - Update:Replace
      Principal: "*"
      Resource: "*"
      Condition:
        StringEquals:
          ResourceType:
            - AWS::DynamoDB::Table
            - AWS::RDS::DBInstance
```

### 4. Use Nested Stacks for Reusability
```yaml
NetworkStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: https://s3.amazonaws.com/.../network.yaml
    Parameters:
      Environment: !Ref Environment
      CidrBlock: 10.0.0.0/16
```

### 5. Handle Secrets Properly
```yaml
# Use Secrets Manager or Parameter Store
DatabasePassword:
  Type: AWS::SecretsManager::Secret
  Properties:
    GenerateSecretString:
      SecretStringTemplate: '{"username": "admin"}'
      GenerateStringKey: password
      PasswordLength: 30

# Reference in resources
DbInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    MasterUserPassword: !Sub "{{resolve:secretsmanager:${DatabasePassword}:SecretString:password}}"
```

## STACK OUTPUTS

Export values needed by other stacks:

```yaml
Outputs:
  # Always export identifiers
  ApiGatewayId:
    Value: !Ref ApiGateway
    Export:
      Name: !Sub "${StackName}-ApiGatewayId"

  # Export ARNs for IAM policies
  LambdaExecutionRoleArn:
    Value: !GetAtt LambdaExecutionRole.Arn
    Export:
      Name: !Sub "${StackName}-LambdaRoleArn"

  # Export endpoints for client configuration
  ApiEndpoint:
    Value: !Sub "https://${ApiGateway}.execute-api.${AWS::Region}.amazonaws.com/${Environment}"
    Export:
      Name: !Sub "${StackName}-ApiEndpoint"

  # Don't export secrets!
```

## OUTPUT

### Stack Architecture Document

```markdown
## Stack Organization
| Stack | Purpose | Exports |
|-------|---------|---------|
| network | VPC, subnets | VpcId, SubnetIds |

## Deployment Order
1. [First stack]
2. [Second stack]

## Cross-Stack References
| Importing Stack | Exported Value | From Stack |
|-----------------|----------------|------------|
| compute | VpcId | network |

## Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| Environment | String | dev | Deployment env |
```
