# Skill: AWS Lambda Stack

## PURPOSE
Create minimal, well-configured AWS Lambda stacks with proper IAM roles, environment setup, and CloudFormation patterns.

## WHEN TO USE
- Creating new Lambda functions from scratch
- Setting up serverless infrastructure stacks
- Defining Lambda roles and permissions
- Configuring Lambda triggers and event sources
- Setting up VPC-enabled Lambda functions
- Creating Lambda functions with Function URLs for HTTP access
- Configuring Dead Letter Queues for failed invocations
- Using Lambda Layers for shared dependencies

## INPUTS
- function_name (required) - Base name for the Lambda function
- runtime (required) - Language runtime: nodejs20.x, python3.12, java21, etc.
- handler (required) - Entry point: index.handler, main.lambda_handler, etc.
- memory_mb (optional) - Memory allocation, default: 512
- timeout_sec (optional) - Timeout in seconds, default: 30
- environment_vars (optional) - Key-value map of environment variables
- triggers (optional) - List of event sources: api_gateway, sqs, sns, s3, eventbridge
- vpc_id (optional) - VPC ID for VPC-enabled functions
- subnet_ids (optional) - List of subnet IDs for VPC configuration
- security_group_id (optional) - Security group ID for VPC configuration
- create_function_url (optional) - Create HTTP endpoint URL: `true` or `false`, default: false
- create_dlq (optional) - Create Dead Letter Queue: `true` or `false`, default: false
- layers (optional) - List of Lambda Layer ARNs to attach
- provisioned_concurrency (optional) - Number of provisioned concurrent executions

## LAMBDA CONFIGURATION

### Minimal Required Properties
```yaml
Type: AWS::Lambda::Function
Properties:
  FunctionName: !Sub "${StackName}-${FunctionName}"
  Runtime: nodejs20.x  # or python3.12, java21, etc.
  Handler: index.handler
  Role: !GetAtt LambdaExecutionRole.Arn
  Code:
    ZipFile: |  # For inline, or use S3Bucket/S3Key
      exports.handler = async (event) => {
        return { statusCode: 200, body: 'OK' };
      };
  MemorySize: 512
  Timeout: 30
```

### Environment Variables
```yaml
Environment:
  Variables:
    LOG_LEVEL: INFO
    NODE_ENV: production
    # Add other vars here
```

### Reserved Concurrent Executions (optional)
```yaml
ReservedConcurrentExecutions: 100  # Limit max concurrent invocations
```

### Dead Letter Queue (DLQ)
```yaml
DeadLetterConfig:
  TargetArn: !GetAtt LambdaDLQ.Arn

LambdaDLQ:
  Type: AWS::SQS::Queue
  Properties:
    QueueName: !Sub "${StackName}-${FunctionName}-dlq"
    MessageRetentionPeriod: 1209600  # 14 days
    KmsMasterKeyId: alias/aws/sqs  # Enable SSE
```

### VPC Configuration
```yaml
VpcConfig:
  SubnetIds: !Ref PrivateSubnetIds
  SecurityGroupIds:
    - !Ref LambdaSecurityGroup

LambdaSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for Lambda function
    VpcId: !Ref VpcId
    SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        DestinationSecurityGroupId: !Ref VPCEndpointSecurityGroup
```

### Lambda Layers
```yaml
Layers:
  - !Ref DependenciesLayer
  - arn:aws:lambda:${AWS::Region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:58

DependenciesLayer:
  Type: AWS::Lambda::LayerVersion
  Properties:
    LayerName: !Sub "${StackName}-${FunctionName}-deps"
    Description: Shared dependencies layer
    Content:
      S3Bucket: !Ref LayerArtifactsBucket
      S3Key: !Sub "layers/${FunctionName}/deps.zip"
    CompatibleRuntimes:
      - nodejs20.x
      - python3.12
    LicenseInfo: MIT
```

### Function URL (HTTP Endpoint)
```yaml
FunctionUrlConfig:
  Type: AWS::Lambda::Url
  Properties:
    AuthType: AWS_IAM  # or NONE for public
    TargetFunctionArn: !Ref MyFunction
    Cors:
      AllowOrigins:
        - https://example.com
      AllowMethods:
        - GET
        - POST
      AllowHeaders:
        - content-type
      MaxAge: 86400

FunctionUrlPermission:
  Type: AWS::Lambda::Permission
  Properties:
    FunctionName: !Ref MyFunction
    Action: lambda:InvokeFunctionUrl
    Principal: "*"
    FunctionUrlAuthType: NONE  # Match AuthType above
```

## IAM ROLE PATTERN

### Minimal Execution Role
```yaml
LambdaExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    RoleName: !Sub "${StackName}-${FunctionName}-role"
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: lambda.amazonaws.com
          Action: sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

### Role with Additional Permissions
Add specific permissions based on triggers and resource access:

```yaml
LambdaExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    RoleName: !Sub "${StackName}-${FunctionName}-role"
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
      - PolicyName: FunctionSpecificPolicy
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            # S3 access example
            - Effect: Allow
              Action:
                - s3:GetObject
                - s3:PutObject
              Resource: !Sub "arn:aws:s3:::${BucketName}/*"
            # DynamoDB access example
            - Effect: Allow
              Action:
                - dynamodb:GetItem
                - dynamodb:PutItem
                - dynamodb:Query
              Resource: !GetAtt MyTable.Arn
```

## STACK INPUTS

```yaml
Parameters:
  StackName:
    Type: String
    Description: Name of the stack
    Default: my-service
  
  Environment:
    Type: String
    Description: Deployment environment
    Default: dev
    AllowedValues:
      - dev
      - staging
      - prod
  
  LogLevel:
    Type: String
    Description: Lambda log level
    Default: INFO
    AllowedValues:
      - DEBUG
      - INFO
      - WARN
      - ERROR

  CreateFunctionUrl:
    Type: String
    Description: Create Lambda Function URL
    Default: 'false'
    AllowedValues:
      - 'true'
      - 'false'

  CreateDLQ:
    Type: String
    Description: Create Dead Letter Queue
    Default: 'false'
    AllowedValues:
      - 'true'
      - 'false'

  VpcId:
    Type: String
    Description: VPC ID (optional, for VPC-enabled functions)
    Default: ''

  PrivateSubnetIds:
    Type: CommaDelimitedList
    Description: Private subnet IDs (optional, for VPC-enabled functions)
    Default: ''

  SecurityGroupId:
    Type: String
    Description: Security group ID (optional, for VPC-enabled functions)
    Default: ''

  LayerArns:
    Type: CommaDelimitedList
    Description: Lambda Layer ARNs to attach
    Default: ''

  ProvisionedConcurrency:
    Type: Number
    Description: Provisioned concurrent executions (0 to disable)
    Default: 0
    MinValue: 0
```

### Conditions
```yaml
Conditions:
  CreateFunctionUrl: !Equals [!Ref CreateFunctionUrl, 'true']
  CreateDLQ: !Equals [!Ref CreateDLQ, 'true']
  UseVPC: !Not [!Equals [!Ref VpcId, '']]
  HasLayers: !Not [!Equals [!Join [",", !Ref LayerArns], '']]
  UseProvisionedConcurrency: !Not [!Equals [!Ref ProvisionedConcurrency, 0]]
```

## STACK OUTPUTS

```yaml
Outputs:
  LambdaFunctionArn:
    Description: ARN of the Lambda function
    Value: !GetAtt MyFunction.Arn
    Export:
      Name: !Sub "${StackName}-LambdaArn"
  
  LambdaFunctionName:
    Description: Name of the Lambda function
    Value: !Ref MyFunction
    Export:
      Name: !Sub "${StackName}-LambdaName"
  
  LambdaRoleArn:
    Description: ARN of the Lambda execution role
    Value: !GetAtt LambdaExecutionRole.Arn
    Export:
      Name: !Sub "${StackName}-LambdaRoleArn"

  FunctionUrl:
    Description: Lambda function URL (if configured)
    Condition: CreateFunctionUrl
    Value: !GetAtt FunctionUrlConfig.FunctionUrl
    Export:
      Name: !Sub "${StackName}-LambdaUrl"

  DLQArn:
    Description: Dead Letter Queue ARN (if configured)
    Condition: CreateDLQ
    Value: !GetAtt LambdaDLQ.Arn
    Export:
      Name: !Sub "${StackName}-LambdaDLQArn"
```

## COMMON TRIGGER PATTERNS

### API Gateway Integration
```yaml
ApiGatewayInvokePermission:
  Type: AWS::Lambda::Permission
  Properties:
    FunctionName: !Ref MyFunction
    Action: lambda:InvokeFunction
    Principal: apigateway.amazonaws.com
    SourceArn: !Sub "arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${ApiId}/*/*/*"
```

### SQS Queue Trigger
```yaml
EventSourceMapping:
  Type: AWS::Lambda::EventSourceMapping
  Properties:
    FunctionName: !Ref MyFunction
    EventSourceArn: !GetAtt MyQueue.Arn
    BatchSize: 10
    MaximumBatchingWindowInSeconds: 5
```

### EventBridge Rule
```yaml
EventRule:
  Type: AWS::Events::Rule
  Properties:
    EventBusName: default
    EventPattern:
      source:
        - my.application
    Targets:
      - Arn: !GetAtt MyFunction.Arn
        Id: LambdaTarget

EventBridgeInvokePermission:
  Type: AWS::Lambda::Permission
  Properties:
    FunctionName: !Ref MyFunction
    Action: lambda:InvokeFunction
    Principal: events.amazonaws.com
    SourceArn: !GetAtt EventRule.Arn
```

## BEST PRACTICES

### Memory and Timeout
- Start with 512MB memory, adjust based on CloudWatch metrics
- Set timeout based on worst-case scenario + 20% buffer
- Use provisioned concurrency only for latency-critical functions

### Logging
- Always use structured JSON logging
- Include correlation IDs for request tracing
- Set appropriate log retention (7-30 days for dev, longer for prod)

### Security
- Grant least privilege - only permissions the function needs
- Use environment variables for configuration, not hardcoded values
- Enable X-Ray tracing for production functions
- Encrypt sensitive environment variables with KMS if needed

### Code Organization
- Keep functions focused on a single responsibility
- Separate business logic from Lambda handler boilerplate
- Use Lambda layers for shared dependencies

## COMMON MISTAKES TO AVOID
- Do NOT use wildcard (*) in resource ARNs unless absolutely necessary
- Do NOT hardcode AWS account IDs or region names
- Do NOT forget to add Invoke permissions for triggers
- Do NOT use overly permissive managed policies like AdministratorAccess

## REFERENCES
- AWS Lambda Developer Guide: https://docs.aws.amazon.com/lambda/
- CloudFormation Lambda Resource: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html
