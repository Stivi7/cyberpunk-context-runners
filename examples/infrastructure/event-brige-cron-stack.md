```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: Event trigger for the lambda that sends Example email reminders

Parameters:
  EnvironmentName:
    Description: Environment name
    Type: String

Resources:
  ExampleEmailsEventRule:
    Type: AWS::Events::Rule
    DeletionPolicy: Retain
    Properties:
      Description: 'Trigger example email reminder lambda'
      Name: !Sub 'example-email-notification-scheduler-${EnvironmentName}'
      ScheduleExpression: 'cron(0 0/2 * * ? *)'
      State: 'ENABLED'
      Targets:
        - Arn:
            Fn::ImportValue: !Sub 'example-email-notification-lambda-${EnvironmentName}-lambda-arn'
          Id: !Sub 'example-email-notification-lambda-${EnvironmentName}'
          Input: '{}'
```
