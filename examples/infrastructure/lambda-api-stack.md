```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: Example reporting API lambda

Parameters:
  Version:
    Description: Version of the code file on S3
    Type: String
  EnvironmentName:
    Description: Environment name (demo or prod)
    Type: String
  StrategyCognitoUserpoolId:
    Description: Userpool id of strategy Ui
    Type: String
  StrategyCognitoClientId:
    Description: Client id of strategy Ui
    Type: String

Conditions:
  IsProd: !Equals [!Ref EnvironmentName, prod]

Resources:
  Lambda:
    Type: AWS::Lambda::Function
    Properties:
      Code:
        S3Bucket: example-artifacts
        S3Key: !Sub 'example-reporting-api/example-reporting-api-${Version}.zip'
      Description: 'Example reporting API'
      FunctionName: !Sub ${AWS::StackName}
      Handler: handler.handle
      MemorySize: 256
      Role:
        Fn::ImportValue: !Sub 'example-reporting-api-lambda-role-${EnvironmentName}-arn'
      Runtime: nodejs22.x
      Timeout: 30
      Environment:
        Variables:
          BUCKET_NAME:
            Fn::ImportValue: !Sub 'example-webhook-receiver-s3-${EnvironmentName}-bucket-name'
          REPORT_LINK: !If [IsProd, 'https://app.example.com/app', 'https://demo.app.example.com/app']
          ENVIRONMENT_NAME: !Ref EnvironmentName
          EVENT_BUS_NAME:
            Fn::ImportValue: !Sub 'example-event-bus-${EnvironmentName}-name'
          STRATEGY_EVENT_BUS_NAME:
            !If [
              IsProd,
              'arn:aws:events:eu-central-1:123456789012:event-bus/example-event-bus-prod',
              'arn:aws:events:eu-central-1:123456789012:event-bus/example-event-bus-dev',
            ]
          INDUSTRY_QUEUE_URL:
            Fn::ImportValue: !Sub 'sqs-${EnvironmentName}-category-sqs-url'
          AI_MEASURE_SELECTION_QUEUE_URL:
            Fn::ImportValue: !Sub 'example-items-ai-selection-sqs-${EnvironmentName}-queue-url'
          STRATEGY_COGNITO_USERPOOL_ID: !Ref StrategyCognitoUserpoolId
          STRATEGY_COGNITO_CLIENT_ID: !Ref StrategyCognitoClientId
          SHARED_DEFINITIONS_SECRET: '{{resolve:secretsmanager:example-shared-definitions-services-secret:SecretString:secretKey}}'
          STEP_FUNCTION_ARN:
            Fn::ImportValue: !Sub 'example-overview-step-function-state-machine-${EnvironmentName}-arn'
      Tags:
        - Key: 'Name'
          Value: !Sub ${AWS::StackName}
        - Key: 'Project'
          Value: example
        - Key: 'Environment'
          Value: !Ref EnvironmentName

  LambdaLogGroup:
    Type: AWS::Logs::LogGroup
    DependsOn: Lambda
    Properties:
      LogGroupName: !Sub '/aws/lambda/${AWS::StackName}'
      RetentionInDays: 14

  ErrorsAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmActions:
        - Fn::ImportValue: !Sub 'example-sns-alert-topic-${EnvironmentName}'
      AlarmDescription: !Sub Alarm if error in ${AWS::StackName} lambda happens
      AlarmName: !Sub ${AWS::StackName}-ErrorsAlarm
      Dimensions:
        - Name: FunctionName
          Value: !Ref Lambda
      Namespace: AWS/Lambda
      MetricName: Errors
      ComparisonOperator: GreaterThanThreshold
      Statistic: Sum
      Threshold: 0
      Period: 60
      EvaluationPeriods: 1

  Error5xxAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmActions:
        - Fn::ImportValue: !Sub 'example-sns-alert-topic-${EnvironmentName}'
      AlarmDescription: !Sub Alarm if 5xx error in ${AWS::StackName} lambda happens
      AlarmName: !Sub ${AWS::StackName}-Error5xxAlarm
      Dimensions:
        - Name: FunctionName
          Value: !Ref Lambda
      Namespace: example
      MetricName: Error5xx
      ComparisonOperator: GreaterThanThreshold
      Statistic: Sum
      Threshold: 0
      Period: 60
      EvaluationPeriods: 1

  LambdaInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref Lambda
      FunctionUrlAuthType: 'NONE'
      Action: lambda:InvokeFunctionUrl
      Principal: '*'

  LambdaUrl:
    Type: AWS::Lambda::Url
    Properties:
      AuthType: NONE
      TargetFunctionArn: !Ref Lambda
      Cors:
        AllowOrigins:
          !If [
            IsProd,
            ['https://app.example.com', 'https://strategy.example.com', 'https://www.example.com'],
            [
              'https://demo.app.example.com',
              'https://demo.strategy.example.com',
              'http://localhost:5173',
              'https://www.example.com',
            ],
          ]
        AllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
        AllowHeaders:
          - Authorization

Outputs:
  LambdaURL:
    Description: URL of the lambda function
    Value: !GetAtt LambdaUrl.FunctionUrl
    Export:
      Name: !Sub '${AWS::StackName}-lambda-url'
```
