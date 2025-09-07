```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: Event rules for Example

Parameters:
  EnvironmentName:
    Description: Environment name (demo or prod)
    Type: String

Resources:
  ServiceAConnectorDQL:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub service-a-connector-${EnvironmentName}-dead-letter
      MessageRetentionPeriod: 1209600

  ServiceAConnectorEvents:
    Type: AWS::Events::Rule
    Properties:
      Description: Routing rule for all Service A events
      EventBusName:
        Fn::ImportValue: !Sub "example-event-bus-${EnvironmentName}-name"
      EventPattern:
        detail-type:
          ["SubscriptionRequested", "PersonUpdated", "MembersActivityRequested"]
      Name: !Sub ServiceAConnectorEvents-${EnvironmentName}
      Targets:
        - Arn:
            Fn::ImportValue: !Sub "service-a-connector-lambda-${EnvironmentName}-lambda-arn"
          Id: !Sub service-a-connector-event-target-${EnvironmentName}
          RetryPolicy:
            MaximumRetryAttempts: 0
          DeadLetterConfig:
            Arn: !GetAtt ServiceAConnectorDQL.Arn

  ServiceAConnectorPermission:
    Type: AWS::Lambda::Permission
    DependsOn:
      - ServiceAConnectorEvents
    Properties:
      Action: lambda:InvokeFunction
      FunctionName:
        Fn::ImportValue: !Sub "service-a-connector-lambda-${EnvironmentName}-lambda-name"
      Principal: events.amazonaws.com
      SourceArn: !GetAtt ServiceAConnectorEvents.Arn

  ServiceBConnectorDQL:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub service-b-connector-${EnvironmentName}-dead-letter
      MessageRetentionPeriod: 1209600

  ServiceBConnectorEvents:
    Type: AWS::Events::Rule
    Properties:
      Description: Routing rule for all Service B events
      EventBusName:
        Fn::ImportValue: !Sub "example-event-bus-${EnvironmentName}-name"
      EventPattern:
        detail-type:
          [
            "SubscriptionAdded",
            "OptedOut",
            "OptedIn",
            "ServiceBDeletePersonData",
            "EmailSent",
          ]
      Name: !Sub ServiceBConnectorEvents-${EnvironmentName}
      Targets:
        - Arn:
            Fn::ImportValue: !Sub "service-b-connector-lambda-${EnvironmentName}-lambda-arn"
          Id: !Sub service-b-connector-event-target-${EnvironmentName}
          RetryPolicy:
            MaximumRetryAttempts: 0
          DeadLetterConfig:
            Arn: !GetAtt ServiceBConnectorDQL.Arn

  ServiceBConnectorPermission:
    Type: AWS::Lambda::Permission
    DependsOn:
      - ServiceBConnectorEvents
    Properties:
      Action: lambda:InvokeFunction
      FunctionName:
        Fn::ImportValue: !Sub "service-b-connector-lambda-${EnvironmentName}-lambda-name"
      Principal: events.amazonaws.com
      SourceArn: !GetAtt ServiceBConnectorEvents.Arn
```
