# Skill: CI/CD Pipeline Design

## PURPOSE
Design continuous integration and deployment pipelines with automated testing, quality gates, and safe promotion strategies across environments.

## WHEN TO USE
- Setting up new deployment pipelines
- Configuring multi-environment promotion
- Implementing quality gates
- Setting up rollback procedures

## INPUTS
- `deployment_targets` (required) - Environments to deploy to: [dev, staging, prod]
- `quality_gates` (optional) - Required checks: [tests, security_scan, lint]
- `deployment_strategy` (optional) - `all-at-once`, `blue-green`, `canary`

## PIPELINE STAGES

### Standard Pipeline Flow

```
Source → Build → Test → Security → Deploy Dev → Approval → Deploy Staging → Approval → Deploy Prod
```

### Stage Details

**1. Source**
- Trigger: Code push, PR merge, or schedule
- Actions: Checkout code, detect changes

**2. Build**
- Compile/transpile code
- Run linting and formatting checks
- Build deployment artifacts (ZIP, Docker image)
- Store artifacts

**3. Test**
- Unit tests (fast, parallel)
- Integration tests (slower, sequential)
- Coverage reporting (gate: ≥95%)
- Test result publishing

**4. Security Scan**
- Dependency vulnerability scan (npm audit, Snyk)
- Static analysis (SonarQube, CodeQL)
- Secrets detection (git-secrets, truffleHog)
- Container scanning (if applicable)

**5. Deploy to Dev**
- Automatic deployment
- Smoke tests
- Integration test execution

**6. Approval Gate (Staging)**
- Manual approval required
- Notify team (Slack, email)
- Timeout: 24-48 hours

**7. Deploy to Staging**
- Pre-production validation
- Load testing (if applicable)
- Final integration tests

**8. Approval Gate (Production)**
- Requires specific approvers
- Change log review
- Rollback plan confirmation

**9. Deploy to Production**
- Use deployment strategy
- Monitor metrics
- Automated rollback triggers

## DEPLOYMENT STRATEGIES

### All-At-Once
```
Replace entire stack simultaneously
```
- **Fastest**: Single operation
- **Riskiest**: Instant blast radius
- **Use for**: Dev environments, low-risk changes

### Blue-Green
```
┌─────────┐     ┌─────────┐
│  Blue   │────▶│  Green  │
│ (live)  │     │ (new)   │
└─────────┘     └─────────┘
      │              │
      │     Flip     │
      │◀─────────────┘
```
- **Safe**: Instant rollback
- **Costly**: Double resources
- **Use for**: Critical services, zero-downtime required

### Canary
```
┌─────────────┐
│   Current   │ 100%
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Canary    │ 5%
│   Current   │ 95%
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Current   │ 100%
└─────────────┘
```
- **Gradual**: Risk mitigation
- **Complex**: Traffic splitting logic
- **Use for**: User-facing services, A/B testing

## CODEPIPELINE EXAMPLE

```yaml
Pipeline:
  Type: AWS::CodePipeline::Pipeline
  Properties:
    RoleArn: !GetAtt PipelineRole.Arn
    ArtifactStore:
      Type: S3
      Location: !Ref ArtifactBucket
    Stages:
      # Source Stage
      - Name: Source
        Actions:
          - Name: GitHubSource
            ActionTypeId:
              Category: Source
              Owner: ThirdParty
              Provider: GitHub
              Version: 1
            Configuration:
              Owner: myorg
              Repo: myrepo
              Branch: main
              OAuthToken: '{{resolve:secretsmanager:github-token:SecretString:token}}'
            OutputArtifacts:
              - Name: SourceCode

      # Build Stage
      - Name: Build
        Actions:
          - Name: BuildAndTest
            ActionTypeId:
              Category: Build
              Owner: AWS
              Provider: CodeBuild
              Version: 1
            Configuration:
              ProjectName: !Ref BuildProject
            InputArtifacts:
              - Name: SourceCode
            OutputArtifacts:
              - Name: BuildArtifact

      # Deploy to Dev
      - Name: DeployDev
        Actions:
          - Name: Deploy
            ActionTypeId:
              Category: Deploy
              Owner: AWS
              Provider: CloudFormation
              Version: 1
            Configuration:
              ActionMode: CREATE_UPDATE
              StackName: my-service-dev
              TemplatePath: BuildArtifact::template.yaml
              Capabilities: CAPABILITY_IAM
            InputArtifacts:
              - Name: BuildArtifact

      # Approval for Staging
      - Name: ApproveStaging
        Actions:
          - Name: ManualApproval
            ActionTypeId:
              Category: Approval
              Owner: AWS
              Provider: Manual
              Version: 1
            Configuration:
              CustomData: Review changes before staging deployment

      # Deploy to Staging
      - Name: DeployStaging
        Actions:
          - Name: Deploy
            ActionTypeId:
              Category: Deploy
              Owner: AWS
              Provider: CloudFormation
              Version: 1
            Configuration:
              ActionMode: CREATE_UPDATE
              StackName: my-service-staging
              TemplatePath: BuildArtifact::template.yaml
```

## CODEBUILD SPECIFICATION

```yaml
# buildspec.yml
version: 0.2

env:
  variables:
    NODE_VERSION: "20"

phases:
  install:
    runtime-versions:
      nodejs: 20
    commands:
      - npm ci

  pre_build:
    commands:
      - npm run lint
      - npm run type-check

  build:
    commands:
      - npm run test:unit -- --coverage
      - npm run build
      - npm run security:audit

  post_build:
    commands:
      - npm run package

artifacts:
  files:
    - template.yaml
    - dist/**/*
    - node_modules/**/*
  discard-paths: no

cache:
  paths:
    - node_modules/**/*
```

## QUALITY GATES

### Test Coverage Gate
```yaml
# Fail if coverage < 95%
- npm run test:unit -- --coverage --coverageReporters=text-summary
- COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
- if (( $(echo "$COVERAGE < 95" | bc -l) )); then exit 1; fi
```

### Security Gate
```yaml
# Fail on critical/high vulnerabilities
- npm audit --audit-level=high
- snyk test --severity-threshold=high
```

### Lint Gate
```yaml
- npm run lint -- --max-warnings=0
```

## ROLLBACK PROCEDURES

### Automatic Rollback Triggers
- Error rate > 1% for 5 minutes
- P99 latency > 2x baseline
- Failed health checks
- CloudWatch alarms

### Manual Rollback
```bash
# Rollback to previous version
aws cloudformation rollback-stack --stack-name my-service-prod

# Or deploy specific version
aws cloudformation deploy \
  --template-file template-v1.2.3.yaml \
  --stack-name my-service-prod
```

## OUTPUT

### Pipeline Configuration

```markdown
## Pipeline Stages
| Stage | Actions | Gates |
|-------|---------|-------|
| Source | Git checkout | - |
| Build | Lint, test, build | Coverage ≥95% |

## Deployment Strategy
- **Method**: [All-at-once/Blue-green/Canary]
- **Auto-rollback**: [Enabled/Disabled]

## Environments
| Environment | Auto-deploy | Approvers |
|-------------|-------------|-----------|
| Dev | Yes | - |
| Staging | No | Team Lead |
| Prod | No | Tech Lead + PM |
```
