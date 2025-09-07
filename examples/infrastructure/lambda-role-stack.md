```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: IAM Role for Example reporting API

Parameters:
  EnvironmentName:
    Description: Environment name (demo or prod)
    Type: String
  DataItemsCatalogRoleName:
    Description: Role name for items table from data team
    Type: String
  DocumentGenerationSQSArn:
    Description: ARN of the Document Generation SQS
    Type: String

Conditions:
  CreateProdResources: !Equals [!Sub '${EnvironmentName}', 'prod']

Resources:
  LambdaRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${AWS::StackName}
      Path: '/'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - sts:AssumeRole
      Policies:
        - PolicyName: !Sub ${AWS::StackName}-write-cloudwatch
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: 'arn:aws:logs:*:*:*'
              - Effect: Allow
                Action:
                  - cloudwatch:PutMetricData
                Resource: '*'
        - PolicyName: !Sub ${AWS::StackName}-network-interface
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - ec2:CreateNetworkInterface
                  - ec2:DescribeNetworkInterfaces
                  - ec2:DeleteNetworkInterface
                Resource: '*'
        - PolicyName: !Sub ${AWS::StackName}-artifact-read
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 's3:ListBucket'
                Resource:
                  - !Sub arn:aws:s3:::example-artifacts
              - Effect: 'Allow'
                Action:
                  - 's3:GetObject'
                Resource:
                  - !Sub arn:aws:s3:::example-artifacts/*
        - PolicyName: !Sub ${AWS::StackName}-s3-access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 's3:ListBucket'
                Resource:
                  - Fn::ImportValue: !Sub 'example-webhook-receiver-s3-${EnvironmentName}-bucket-arn'
                  - Fn::ImportValue: !Sub 'example-reporting-api-strategy-s3-${EnvironmentName}-bucket-arn'
              - Effect: Allow
                Action:
                  - 's3:GetObject'
                  - 's3:GetObjectAcl'
                Resource:
                  - !Join [
                      '',
                      [Fn::ImportValue: !Sub 'example-webhook-receiver-s3-${EnvironmentName}-bucket-arn', '/*'],
                    ]
                  - !Join [
                      '',
                      [Fn::ImportValue: !Sub 'example-reporting-api-strategy-s3-${EnvironmentName}-bucket-arn', '/*'],
                    ]
              - Effect: Allow
                Action:
                  - 's3:PutObject'
                  - 's3:PutObjectAcl'
                Resource:
                  - !Join [
                      '',
                      [Fn::ImportValue: !Sub 'example-reporting-api-strategy-s3-${EnvironmentName}-bucket-arn', '/*'],
                    ]
              - Effect: Allow
                Action:
                  - 's3:DeleteObject'
                Resource:
                  - !Join [
                      '',
                      [Fn::ImportValue: !Sub 'example-reporting-api-strategy-s3-${EnvironmentName}-bucket-arn', '/*'],
                    ]

        - PolicyName: !Sub ${AWS::StackName}-ses-access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - ses:SendEmail
                Resource:
                  - !Sub 'arn:aws:ses:eu-central-1:${AWS::AccountId}:identity/example.com'
        - PolicyName: !Sub ${AWS::StackName}-secrets-manager-read
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'secretsmanager:GetSecretValue'
                Resource:
                  - !Sub arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:example*
        - PolicyName: !Sub ${AWS::StackName}-dynamodb-access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'dynamodb:GetShardIterator'
                  - 'dynamodb:Scan'
                  - 'dynamodb:Query'
                  - 'dynamodb:GetRecords'
                Resource:
                  - Fn::ImportValue: !Sub 'example-reporting-api-ddb-${EnvironmentName}-example-shared-definitions-table-arn'
                  - Fn::ImportValue: !Sub 'example-reporting-api-ddb-${EnvironmentName}-generated-document-details-table-arn'
              - Effect: Allow
                Action:
                  - 'dynamodb:BatchGetItem'
                  - 'dynamodb:BatchWriteItem'
                  - 'dynamodb:ConditionCheckItem'
                  - 'dynamodb:PutItem'
                  - 'dynamodb:DescribeTable'
                  - 'dynamodb:DeleteItem'
                  - 'dynamodb:GetItem'
                  - 'dynamodb:Scan'
                  - 'dynamodb:Query'
                  - 'dynamodb:UpdateItem'
                Resource:
                  - Fn::ImportValue: !Sub 'example-reporting-api-ddb-${EnvironmentName}-example-shared-definitions-table-arn'
                  - Fn::ImportValue: !Sub 'example-reporting-api-ddb-${EnvironmentName}-generated-document-details-table-arn'
              - Effect: Allow
                Action:
                  - sts:AssumeRole
                Resource:
                  - !Sub 'arn:aws:iam::123456789012:role/${DataItemsCatalogRoleName}'
        - PolicyName: !Sub ${AWS::StackName}-event-bus
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'events:PutEvents'
                Resource:
                  - Fn::ImportValue: !Sub 'example-event-bus-${EnvironmentName}-arn'
                  - !If [
                      CreateProdResources,
                      'arn:aws:events:eu-central-1:123456789012:event-bus/example-event-bus-prod',
                      'arn:aws:events:eu-central-1:123456789012:event-bus/example-event-bus-dev',
                    ]
        - PolicyName: !Sub ${AWS::StackName}-sqs-access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'sqs:SendMessage'
                Resource:
                  - Fn::ImportValue: !Sub 'sqs-${EnvironmentName}-category-sqs-arn'
                  - !Ref DocumentGenerationSQSArn
                  - Fn::ImportValue: !Sub 'example-items-ai-selection-sqs-${EnvironmentName}-queue-arn'
        - PolicyName: !Sub ${AWS::StackName}-strategy-generator-images
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 's3:PutObject'
                  - 's3:PutObjectAcl'
                Resource:
                  - !Join [
                      '',
                      [
                        Fn::ImportValue: !Sub 'example-reporting-api-strategy-s3-${EnvironmentName}-strategy-generator-images-bucket-arn',
                        '/*',
                      ],
                    ]
        - PolicyName: !Sub ${AWS::StackName}-step-functions
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'states:StartExecution'
                Resource:
                  - Fn::ImportValue: !Sub 'example-overview-step-function-state-machine-${EnvironmentName}-arn'

Outputs:
  LambdaRoleArn:
    Description: Example reporting API lambda role ARN
    Value: !GetAtt LambdaRole.Arn
    Export:
      Name: !Sub '${AWS::StackName}-arn'
```
