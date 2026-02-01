# Skill: Observability Setup

## PURPOSE
Configure comprehensive logging, metrics, alarms, and dashboards for monitoring application health, performance, and operational issues.

## WHEN TO USE
- Setting up monitoring for new services
- Defining SLIs/SLOs
- Creating alarm thresholds
- Building operational dashboards
- Setting up distributed tracing

## INPUTS
- `services` (required) - Services to monitor (Lambda, API Gateway, etc.)
- `slos` (optional) - Service level objectives (availability, latency)
- `alert_channels` (optional) - SNS topics, email, PagerDuty endpoints

## OBSERVABILITY PILLARS

### 1. Logs (Events)
Structured records of discrete events.

**CloudWatch Logs Best Practices:**
- Use structured JSON logs
- Include correlation IDs
- Log at appropriate levels (ERROR, WARN, INFO, DEBUG)
- Set retention: dev=7d, staging=30d, prod=90d+

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "message": "Order processed",
  "requestId": "abc-123",
  "userId": "user-456",
  "orderId": "order-789",
  "duration": 150,
  "coldStart": false
}
```

### 2. Metrics (Aggregates)
Numeric data over time for analysis.

**Key Lambda Metrics:**
- Invocations
- Duration (avg, p50, p99)
- Errors
- Throttles
- IteratorAge (stream processing)

**Key API Gateway Metrics:**
- Latency
- IntegrationLatency
- 4XXError
- 5XXError
- Count

### 3. Traces (Flows)
End-to-end request flow through services.

**X-Ray Best Practices:**
- Enable active tracing on Lambda
- Name segments meaningfully
- Add annotations for filtering
- Instrument downstream calls

## CLOUDWATCH ALARMS

### Lambda Alarms

```yaml
HighErrorRate:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${FunctionName}-HighErrorRate"
    MetricName: Errors
    Namespace: AWS/Lambda
    Statistic: Sum
    Period: 300
    EvaluationPeriods: 1
    Threshold: 5
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: FunctionName
        Value: !Ref FunctionName
    AlarmActions:
      - !Ref AlertTopic

HighDuration:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${FunctionName}-HighDuration"
    MetricName: Duration
    Namespace: AWS/Lambda
    ExtendedStatistic: p99
    Period: 300
    EvaluationPeriods: 2
    Threshold: 3000  # 3 seconds
    ComparisonOperator: GreaterThanThreshold
    AlarmActions:
      - !Ref AlertTopic
```

### API Gateway Alarms

```yaml
High5xxRate:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: !Sub "${ApiName}-High5xxRate"
    MetricName: 5XXError
    Namespace: AWS/ApiGateway
    Statistic: Sum
    Period: 60
    EvaluationPeriods: 2
    Threshold: 10
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: ApiName
        Value: !Ref ApiName
    AlarmActions:
      - !Ref AlertTopic
```

### Custom Business Metrics

```yaml
OrderProcessingTime:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: OrderProcessingTimeTooHigh
    MetricName: OrderProcessingDuration
    Namespace: MyService/Orders
    ExtendedStatistic: p99
    Period: 300
    EvaluationPeriods: 3
    Threshold: 5000
    ComparisonOperator: GreaterThanThreshold
```

## DASHBOARDS

### Service Health Dashboard

```yaml
Dashboard:
  Type: AWS::CloudWatch::Dashboard
  Properties:
    DashboardName: !Sub "${ServiceName}-${Environment}"
    DashboardBody: !Sub |
      {
        "widgets": [
          {
            "type": "metric",
            "properties": {
              "title": "Lambda Invocations",
              "metrics": [
                ["AWS/Lambda", "Invocations", "FunctionName", "${FunctionName}"]
              ],
              "period": 300,
              "stat": "Sum"
            }
          },
          {
            "type": "metric",
            "properties": {
              "title": "Error Rate",
              "metrics": [
                ["AWS/Lambda", "Errors", "FunctionName", "${FunctionName}", { "color": "#d62728" }],
                [".", "Invocations", ".", ".", { "color": "#2ca02c" }]
              ],
              "period": 300,
              "stat": "Sum",
              "annotations": {
                "horizontal": [
                  { "value": 5, "label": "Error Threshold", "color": "#ff0000" }
                ]
              }
            }
          }
        ]
      }
```

## LOGGING CONFIGURATION

### Lambda Log Group

```yaml
FunctionLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: !Sub "/aws/lambda/${FunctionName}"
    RetentionInDays: !If [IsProd, 90, 30]
```

### Log Insights Queries

```sql
-- Find errors in last hour
fields @timestamp, @message
| filter level = "ERROR"
| sort @timestamp desc
| limit 100

-- Latency by endpoint
fields @timestamp, @duration, @message
| filter @message like /Request completed/
| parse @message "endpoint: *" as endpoint
| stats avg(@duration) as avg_latency, max(@duration) as max_latency by endpoint

-- Cold start frequency
fields @timestamp, @message
| filter @message like /INIT_START/
| stats count() as cold_starts by bin(5m)
```

## OUTPUT

### Observability Configuration

```markdown
## Metrics Monitored
| Service | Metric | Threshold | Action |
|---------|--------|-----------|--------|
| Lambda | Errors | > 5/5min | Alert |
| API GW | 5XXError | > 10/min | Alert |

## Alarms
| Name | Condition | Severity |
|------|-----------|----------|
| HighErrorRate | Lambda errors > 5 | P1 |

## Dashboards
- **Service Health**: [URL]
- **Business Metrics**: [URL]

## Log Retention
- Dev: 7 days
- Staging: 30 days
- Prod: 90 days
```
