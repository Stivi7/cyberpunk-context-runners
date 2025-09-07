## Publishing in the artifacts folder
```bash
#!/bin/bash

set -Eeuo pipefail

aws s3 cp "example-reporting-api-$VERSION.zip" "s3://example-artifacts/example-reporting-api/"
```

## Deploying the stacks
```bash
#!/bin/bash

set -Eeuox pipefail

./example-reporting-api-ddb.sh
./example-reporting-api-ddb-prompts.sh
./example-reporting-api-strategy-s3.sh
./example-reporting-api-lambda-role.sh
./example-reporting-api-lambda.sh
./example-reporting-api-lambda.sh
./example-reporting-api-key-datateam-role.sh
```

## Stack deployment script
```bash
#!/bin/bash

set -Eeuo pipefail

source ./bash_utils/params.sh
source ./bash_utils/stack.sh

AWS_REGION=eu-central-1

check_environment_var

strategy_cognito=$(stack_output example-ui-cognito-$ENVIRONMENT)
strategy_cognito_userpool_id=$(param_from_stack_output "$strategy_cognito" UserPoolId)
strategy_cognito_client_id=$(param_from_stack_output "$strategy_cognito" UserPoolClientId)

aws cloudformation deploy \
    --region $AWS_REGION \
    --stack-name example-reporting-api-lambda-$ENVIRONMENT \
    --template-file stacks/example-reporting-api-lambda.yaml \
    --no-fail-on-empty-changeset \
    --parameter-overrides Version="$VERSION" \
                          EnvironmentName="$ENVIRONMENT" \
                          StrategyCognitoUserpoolId="$strategy_cognito_userpool_id" \
                          StrategyCognitoClientId="$strategy_cognito_client_id"
```

## Bash utils

params.sh

```bash
function check_environment_var {
    if [[ $ENVIRONMENT != "prod" && $ENVIRONMENT != 'demo' ]]; then
        echo "Environment doesn't have proper value"
        exit 1
    fi
}
```
stack.sh

```bash
function generate_stack_with_ts {
  timestamp=$(date +"%s")
  sed "s/%timestamp%/$timestamp/g" $1 > $2
}

function stack_output {
  aws cloudformation describe-stacks \
    --region $AWS_REGION \
    --stack-name $1 \
    --output text \
    --query 'Stacks[*].Outputs[*].[OutputKey, OutputValue]'
}

function param_from_stack_output {
  echo "$1" | grep "$2" | awk '{print $2}'
}
```
