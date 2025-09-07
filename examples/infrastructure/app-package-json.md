```json
{
  "name": "example-reporting-api",
  "version": "1.0.0",
  "description": "API for the example reporting",
  "main": "build/handler.js",
  "author": "Example Team",
  "license": "UNLICENSED",
  "private": true,
  "homepage": "https://www.example.com/",
  "engines": {
    "node": ">=22"
  },
  "scripts": {
    "lint": "eslint --ext .ts src/",
    "prettier": "../../packages/scripts/prettier.sh --check .",
    "prettier:fix": "../../packages/scripts/prettier.sh --write .",
    "test": "jest src/",
    "build": "npm run build:checkSyntax && npm run build:esBuild",
    "build:esBuild": "../../packages/scripts/esbuild.sh --outfile=./build/handler.js src/handler.ts",
    "build:checkSyntax": "tsc -noEmit",
    "zip": "cd build && zip -qq \"../example-reporting-api-${VERSION}.zip\" handler.js handler.js.map",
    "publish": "VERSION=${VERSION} ./deploy/publish.sh",
    "deploy:demo": "cd ./deploy && ENVIRONMENT=demo VERSION=${VERSION} ./deploy.sh",
    "deploy:prod": "cd ./deploy && ENVIRONMENT=prod VERSION=${VERSION} ./deploy.sh"
  },
  "dependencies": {
    "@aws-sdk/client-cloudwatch": "^3.554.0",
    "@aws-sdk/client-eventbridge": "^3.621.0",
    "@aws-sdk/client-s3": "^3.670.0",
    "@aws-sdk/client-secrets-manager": "^3.441.0",
    "@aws-sdk/client-sfn": "^3.812.0",
    "@aws-sdk/client-sqs": "^3.658.1",
    "@aws-sdk/client-sts": "^3.577.0",
    "@aws-sdk/lib-dynamodb": "^3.587.0",
    "@aws-sdk/s3-request-presigner": "^3.670.0",
    "@repo/jestconfig": "workspace:*",
    "@repo/schemas": "workspace:*",
    "@repo/strategy-locks": "workspace:*",
    "aws-jwt-verify": "^4.0.1",
    "dayjs": "^1.11.10",
    "effect": "^3.3.5",
    "lambda-multipart-parser-v2": "^1.0.3",
    "lodash.chunk": "^4.2.0",
    "lodash.uniq": "^4.5.0",
    "example-aws-lambda-rest-router": "bitbucket:example/example-aws-lambda-rest-router#semver:^0.0.2",
    "example-ddb-helper": "bitbucket:example/example-ddb-helper#semver:^0.0.3",
    "example-secret-manager": "bitbucket:example/example-secret-manager#semver:^0.0.2",
    "example-send-email": "bitbucket:example/example-send-email#semver:^0.0.1",
    "uuid": "^9.0.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@repo/eslint-config": "workspace:*",
    "@repo/tsconfig": "workspace:*",
    "@types/aws-lambda": "^8.10.125",
    "@types/lodash.chunk": "^4.2.9",
    "@types/lodash.uniq": "^4.5.9",
    "@types/node": "^22.3.0",
    "@types/uuid": "^9.0.8",
    "csv-parser": "^3.2.0"
  }
}
```
