# Skill: API Gateway Design

## PURPOSE
Configure AWS API Gateway to expose RESTful APIs with proper integration, authentication, throttling, and deployment patterns.

## WHEN TO USE
- Creating new API endpoints
- Defining resource structures
- Configuring authentication/authorization
- Setting up request/response transformations
- Managing API deployments and stages

## INPUTS
- `endpoints` (required) - List of required endpoints
- `auth_requirements` (optional) - Auth method: `IAM`, `COGNITO`, `LAMBDA`, `API_KEY`
- `integration_type` (optional) - `LAMBDA`, `HTTP`, `MOCK`, `SERVICE`

## API GATEWAY COMPONENTS

### Resources and Methods

```
API Gateway Structure:
/
├── /users
│   ├── GET    (List users)
│   ├── POST   (Create user)
│   └── /{id}
│       ├── GET    (Get user)
│       ├── PUT    (Update user)
│       └── DELETE (Delete user)
└── /orders
    ├── GET
    └── /{orderId}
        └── GET
```

### Integration Types

**Lambda Integration**
```yaml
Type: AWS_PROXY  # or AWS for custom mapping
URI: arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account:function:functionName/invocations
```

**HTTP Integration**
```yaml
Type: HTTP_PROXY  # or HTTP for custom mapping
URI: https://backend.example.com/resource
```

**Mock Integration**
```yaml
Type: MOCK
Used for: Testing, CORS preflight, health checks
```

## AUTHENTICATION METHODS

### 1. IAM Authorization
Best for: Service-to-service, AWS SDK clients

```yaml
AuthorizationType: AWS_IAM
# Clients sign requests with SigV4
```

### 2. Cognito User Pools
Best for: Mobile/web apps with user authentication

```yaml
AuthorizationType: COGNITO_USER_POOLS
AuthorizerId: !Ref CognitoAuthorizer
```

### 3. Lambda Authorizer
Best for: Custom auth logic, existing auth systems

```yaml
AuthorizationType: CUSTOM
AuthorizerId: !Ref LambdaAuthorizer
```

### 4. API Keys
Best for: Rate limiting, usage plans (not security)

```yaml
ApiKeyRequired: true
# Used with Usage Plans for throttling
```

## REQUEST/RESPONSE FLOW

```
Client Request
     │
     ▼
┌──────────────────────────────────────────────────────────┐
│  Method Request                                          │
│  - Request validation                                    │
│  - Authorization                                         │
│  - API Key check                                         │
└──────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────┐
│  Integration Request                                     │
│  - Transform request for backend                         │
│  - Add headers, query params                             │
│  - Mapping templates (if not proxy)                      │
└──────────────────────────────────────────────────────────┘
     │
     ▼
Backend (Lambda/HTTP/Mock)
     │
     ▼
┌──────────────────────────────────────────────────────────┐
│  Integration Response                                    │
│  - Transform backend response                            │
│  - Select response mapping by regex                      │
│  - Handle errors                                         │
└──────────────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────┐
│  Method Response                                         │
│  - Define status codes                                   │
│  - Response models/schemas                               │
│  - Headers                                               │
└──────────────────────────────────────────────────────────┘
     │
     ▼
Client Response
```

## THROTTLING AND RATE LIMITING

### Account-Level Limits
- **Default**: 10,000 requests/second per region
- **Burst**: 5,000 concurrent connections

### Stage-Level Throttling
```yaml
MethodSettings:
  - ResourcePath: /*
    HttpMethod: *
    ThrottlingBurstLimit: 100
    ThrottlingRateLimit: 50
```

### Usage Plans
```yaml
UsagePlan:
  Throttle:
    BurstLimit: 100
    RateLimit: 50
  Quota:
    Limit: 10000
    Period: DAY
```

## CLOUDFORMATION EXAMPLE

```yaml
ApiGateway:
  Type: AWS::ApiGateway::RestApi
  Properties:
    Name: !Sub "${StackName}-Api"
    Description: API for my service
    EndpointConfiguration:
      Types:
        - REGIONAL

# Lambda Integration
GetUserMethod:
  Type: AWS::ApiGateway::Method
  Properties:
    RestApiId: !Ref ApiGateway
    ResourceId: !Ref UserResource
    HttpMethod: GET
    AuthorizationType: COGNITO_USER_POOLS
    AuthorizerId: !Ref CognitoAuthorizer
    Integration:
      Type: AWS_PROXY
      IntegrationHttpMethod: POST
      Uri: !Sub
        - arn:aws:apigateway:${Region}:lambda:path/2015-03-31/functions/${LambdaArn}/invocations
        - Region: !Ref AWS::Region
          LambdaArn: !GetAtt GetUserFunction.Arn
    MethodResponses:
      - StatusCode: 200
      - StatusCode: 404
      - StatusCode: 500

# Deployment
ApiDeployment:
  Type: AWS::ApiGateway::Deployment
  DependsOn:
    - GetUserMethod
    - PostUserMethod
  Properties:
    RestApiId: !Ref ApiGateway
    StageName: !Ref Environment

# Stage with throttling
ApiStage:
  Type: AWS::ApiGateway::Stage
  Properties:
    StageName: !Ref Environment
    RestApiId: !Ref ApiGateway
    DeploymentId: !Ref ApiDeployment
    MethodSettings:
      - ResourcePath: /*
        HttpMethod: *
        ThrottlingBurstLimit: 100
        ThrottlingRateLimit: 50
        LoggingLevel: INFO
        DataTraceEnabled: true
        MetricsEnabled: true
```

## CORS CONFIGURATION

```yaml
GatewayResponse:
  Type: AWS::ApiGateway::GatewayResponse
  Properties:
    RestApiId: !Ref ApiGateway
    ResponseType: DEFAULT_4XX
    ResponseParameters:
      gatewayresponse.header.Access-Control-Allow-Origin: "'*'"
      gatewayresponse.header.Access-Control-Allow-Headers: "'Content-Type,X-Amz-Date,Authorization'"

OptionsMethod:
  Type: AWS::ApiGateway::Method
  Properties:
    RestApiId: !Ref ApiGateway
    ResourceId: !Ref UserResource
    HttpMethod: OPTIONS
    AuthorizationType: NONE
    Integration:
      Type: MOCK
      IntegrationResponses:
        - StatusCode: 200
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: "'Content-Type,X-Amz-Date,Authorization'"
            method.response.header.Access-Control-Allow-Methods: "'GET,POST,PUT,DELETE'"
            method.response.header.Access-Control-Allow-Origin: "'*'"
      RequestTemplates:
        application/json: '{"statusCode": 200}'
    MethodResponses:
      - StatusCode: 200
        ResponseParameters:
          method.response.header.Access-Control-Allow-Headers: true
          method.response.header.Access-Control-Allow-Methods: true
          method.response.header.Access-Control-Allow-Origin: true
```

## CUSTOM DOMAIN NAMES

```yaml
CustomDomain:
  Type: AWS::ApiGateway::DomainName
  Properties:
    DomainName: api.example.com
    CertificateArn: !Ref CertificateArn
    SecurityPolicy: TLS_1_2

BasePathMapping:
  Type: AWS::ApiGateway::BasePathMapping
  Properties:
    DomainName: !Ref CustomDomain
    RestApiId: !Ref ApiGateway
    Stage: !Ref Environment
```

## BEST PRACTICES

1. **Use Proxy Integration**: Simpler, better performance than custom mapping
2. **Enable CloudWatch Logs**: Essential for debugging
3. **Set Up Alarms**: 4xx and 5xx error rates
4. **Use Stages**: dev, staging, prod with different configs
5. **Enable Caching**: For read-heavy endpoints (TTL: 300-3600s)
6. **Request Validation**: Enable to catch bad requests early
7. **WAF Protection**: For public APIs, enable AWS WAF

## OUTPUT

### API Gateway Configuration

```markdown
## API Structure
| Resource | Method | Integration | Auth | Description |
|----------|--------|-------------|------|-------------|
| /users | GET | Lambda | Cognito | List users |

## Authentication
- **Method**: [Cognito/IAM/Lambda/None]
- **Authorizer**: [Name/ARN]

## Throttling
- **Rate Limit**: [req/s]
- **Burst Limit**: [concurrent]
- **Quota**: [reqs/day]

## Deployment
- **Stages**: [dev/staging/prod]
- **Custom Domain**: [api.example.com]

## CloudFormation
[Complete YAML]
```
