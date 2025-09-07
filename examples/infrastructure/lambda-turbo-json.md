```json
{
  "extends": ["//"],
  "tasks": {
    "lint": {},
    "prettier": {},
    "test": {
      "dependsOn": ["lint", "prettier"]
    },
    "build": {
      "dependsOn": ["test"]
    },
    "zip": {
      "inputs": ["./build/**"],
      "outputs": ["example-reporting-api-*.zip"],
      "passThroughEnv": ["VERSION"]
    },
    "publish": {
      "dependsOn": ["zip"],
      "inputs": ["./deploy/**", "./example-reporting-api-*.zip"],
      "passThroughEnv": ["VERSION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "deploy:demo": {
      "dependsOn": ["publish"],
      "inputs": ["./deploy/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "deploy:prod": {
      "dependsOn": ["publish"],
      "inputs": ["./deploy/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "run:tasks:demo": {
      "dependsOn": ["deploy:demo"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "run:tasks:prod": {
      "dependsOn": ["deploy:prod"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT"]
    }
  }
}
```
