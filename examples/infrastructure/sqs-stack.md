```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: SQS queue for example-items-ai-selection processing

Parameters:
  EnvironmentName:
    Description: Environment name (demo or prod)
    Type: String

Conditions:
  IsProd: !Equals [!Ref EnvironmentName, prod]

Resources:
  ExampleItemsAiSelectionQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub ${AWS::StackName}
      VisibilityTimeout: 600
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt ExampleItemsAiSelectionDeadLetterQueue.Arn
        maxReceiveCount: 3
      Tags:
        - Key: 'Name'
          Value: !Sub ${AWS::StackName}
        - Key: 'Project'
          Value: EXAMPLE
        - Key: 'Environment'
          Value: !Ref EnvironmentName

  ExampleItemsAiSelectionDeadLetterQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub ${AWS::StackName}-dlq
      MessageRetentionPeriod: 1209600 # 14 days
      Tags:
        - Key: 'Name'
          Value: !Sub ${AWS::StackName}-dlq
        - Key: 'Project'
          Value: EXAMPLE
        - Key: 'Environment'
          Value: !Ref EnvironmentName

Outputs:
  QueueArn:
    Description: ARN of the SQS queue
    Value: !GetAtt ExampleItemsAiSelectionQueue.Arn
    Export:
      Name: !Sub '${AWS::StackName}-queue-arn'

  QueueUrl:
    Description: URL of the SQS queue
    Value: !Ref ExampleItemsAiSelectionQueue
    Export:
      Name: !Sub '${AWS::StackName}-queue-url'

  DeadLetterQueueArn:
    Description: ARN of the dead letter queue
    Value: !GetAtt ExampleItemsAiSelectionDeadLetterQueue.Arn
    Export:
      Name: !Sub '${AWS::StackName}-dlq-arn'

  DeadLetterQueueUrl:
    Description: URL of the dead letter queue
    Value: !Ref ExampleItemsAiSelectionDeadLetterQueue
    Export:
      Name: !Sub '${AWS::StackName}-dlq-url'
```
