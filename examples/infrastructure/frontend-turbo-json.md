```json
{
  "extends": ["//"],
  "tasks": {
    "lint": {},
    "check": {},
    "generate:env:demo": {
      "passThroughEnv": ["ENVIRONMENT"],
      "outputs": [".env"]
    },
    "generate:env:prod": {
      "passThroughEnv": ["ENVIRONMENT"],
      "outputs": [".env"]
    },
    "test": {
      "dependsOn": ["lint"]
    },
    "build": {
      "inputs": [".env"],
      "dependsOn": ["test"]
    },
    "build:demo": {
      "inputs": [".env"],
      "dependsOn": ["test", "generate:env:demo", "deploy:demo"],
      "outputs": ["build/**"]
    },
    "build:prod": {
      "inputs": [".env"],
      "dependsOn": ["test", "generate:env:prod", "deploy:prod"],
      "outputs": ["build/**"]
    },
    "publish:demo": {
      "dependsOn": ["build:demo"],
      "inputs": ["./build/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "publish:prod": {
      "dependsOn": ["build:prod"],
      "inputs": ["./build/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "deploy:demo": {
      "inputs": ["./deploy/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "deploy:prod": {
      "inputs": ["./deploy/**"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "run:tasks:demo": {
      "dependsOn": ["publish:demo"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    },
    "run:tasks:prod": {
      "dependsOn": ["publish:prod"],
      "passThroughEnv": ["VERSION", "ENVIRONMENT", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN"]
    }
  }
}
```
