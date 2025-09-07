```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: Stack contains DynamoDB tables used by the Example Reporting API

Parameters:
  EnvironmentName:
    Description: Environment name
    Type: String

Resources:
  ExampleEmailsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub example-emails-${EnvironmentName}
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
        - AttributeName: email
          AttributeType: S
        - AttributeName: createdAt
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      GlobalSecondaryIndexes:
        - IndexName: emailCreatedAt-index
          Projection:
            ProjectionType: ALL
          KeySchema:
            - AttributeName: email
              KeyType: HASH
            - AttributeName: createdAt
              KeyType: RANGE
          ProvisionedThroughput:
            ReadCapacityUnits: 0
            WriteCapacityUnits: 0
        - IndexName: createdAt-index
          Projection:
            ProjectionType: ALL
          KeySchema:
            - AttributeName: createdAt
              KeyType: HASH
          ProvisionedThroughput:
            ReadCapacityUnits: 0
            WriteCapacityUnits: 0
      BillingMode: PAY_PER_REQUEST
      TableClass: STANDARD
      DeletionProtectionEnabled: true

  ExampleSharedDefinitionsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub example-shared-definitions-${EnvironmentName}
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      TableClass: STANDARD
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
        RecoveryPeriodInDays: 14
      DeletionProtectionEnabled: true

  ExampleCustomerSettingsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub example-customer-settings-${EnvironmentName}
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      TableClass: STANDARD
      DeletionProtectionEnabled: true

  GeneratedDocumentDetailsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub generated-document-details-${EnvironmentName}
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
        - AttributeName: reportId
          AttributeType: S
      KeySchema:
        - AttributeName: reportId
          KeyType: HASH
        - AttributeName: id
          KeyType: RANGE
      BillingMode: PAY_PER_REQUEST
      TableClass: STANDARD
      DeletionProtectionEnabled: true

Outputs:
  ExampleEmailsTableArn:
    Description: Example emails table arn
    Value: !GetAtt ExampleEmailsTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-emails-table-arn'

  ExampleCustomerSettingsTableArn:
    Description: Example customer settings table ARN
    Value: !GetAtt ExampleCustomerSettingsTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-customer-settings-table-arn'

  ExampleSharedDefinitionsTableArn:
    Description: Example Shared Definitions table ARN
    Value: !GetAtt ExampleSharedDefinitionsTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-example-shared-definitions-table-arn'

  GeneratedDocumentDetailsTableArn:
    Description: Generated document details table arn
    Value: !GetAtt GeneratedDocumentDetailsTable.Arn
    Export:
      Name: !Sub '${AWS::StackName}-generated-document-details-table-arn'
```
