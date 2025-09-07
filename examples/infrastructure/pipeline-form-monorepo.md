```yaml
image: sleavely/node-awscli:22.x

options:
  size: 2x

definitions:
  caches:
    turbo:
      key:
        files:
          - turbo.json
      path: .turbo
    node: node_modules

buildAllDemo: &buildAllDemo
  step:
    name: Build All Apps Demo
    script:
      - corepack enable
      - pnpm install
      - git fetch origin master
      - export ENVIRONMENT=demo
      - set -o pipefail
      - pnpm exec turbo build
      - pnpm exec turbo build --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt
      - apps/**/build/**

buildAllProd: &buildAllProd
  step:
    name: Build All Apps Prod
    script:
      - corepack enable
      - pnpm install
      - git fetch origin master
      - export ENVIRONMENT=prod
      - set -o pipefail
      - pnpm exec turbo build
      - pnpm exec turbo build --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt
      - apps/**/build/**

buildAffectedDemo: &buildAffectedDemo
  step:
    name: Build Affected Apps Demo
    script:
      - corepack enable
      - pnpm install
      - git fetch origin master
      - export ENVIRONMENT=demo
      - export PREV_MASTER_COMMIT=$(git rev-parse origin/master^)
      - set -o pipefail
      - pnpm exec turbo build --filter=...[$PREV_MASTER_COMMIT...HEAD]
      - pnpm exec turbo build --filter=...[$PREV_MASTER_COMMIT...HEAD] --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt
      - apps/**/build/**
runDeployTasksDemo: &runDeployTasksDemo
  step:
    name: Run turbo deployment tasks Demo
    script:
      - ls
      - corepack enable
      - pnpm install
      - cat builds.txt
      - export ENVIRONMENT=demo
      - export VERSION=$BITBUCKET_BUILD_NUMBER
      - |
        while IFS= read -r item; do
          echo "Running turbo for: $item"
          set -o pipefail
          pnpm exec turbo run run:tasks:demo --filter="$item"
        done < builds.txt
    caches:
      - turbo
      - node

buildAffectedProd: &buildAffectedProd
  step:
    name: Build Affected Apps Prod
    artifacts:
      download: false
    script:
      - corepack enable
      - pnpm install
      - git fetch origin master
      - export ENVIRONMENT=prod
      - export PREV_MASTER_COMMIT=$(git rev-parse origin/master^)
      - set -o pipefail
      - pnpm exec turbo build --filter=...[$PREV_MASTER_COMMIT...HEAD]
      - pnpm exec turbo build --filter=...[$PREV_MASTER_COMMIT...HEAD] --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
      - ls
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt
      - apps/**/build/**

runDeployTasksProd: &runDeployTasksProd
  step:
    name: Run turbo deployment tasks Prod
    trigger: manual
    script:
      - corepack enable
      - pnpm install
      - cat builds.txt
      - export ENVIRONMENT=prod
      - export VERSION=$BITBUCKET_BUILD_NUMBER
      - |
        while IFS= read -r item; do
          echo "Running turbo for: $item"
          set -o pipefail
          pnpm exec turbo run run:tasks:prod --filter="$item"
        done < builds.txt
    caches:
      - turbo
      - node

buildPullRequestChanges: &buildPullRequestChanges
  step:
    name: Build PR Affected Apps
    script:
      - corepack enable
      - pnpm install
      - git fetch origin $BITBUCKET_PR_DESTINATION_BRANCH
      - echo "Building apps affected by PR changes"
      - export ENVIRONMENT=demo
      - set -o pipefail
      - pnpm exec turbo build --filter=...[origin/$BITBUCKET_PR_DESTINATION_BRANCH...HEAD]
      - pnpm exec turbo build --filter=...[origin/$BITBUCKET_PR_DESTINATION_BRANCH...HEAD] --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt

buildCurrentBranchDemo: &buildCurrentBranchDemo
  step:
    name: Build Current Branch Apps for Demo
    script:
      - corepack enable
      - pnpm install
      - git fetch origin master:master
      - echo "Building apps affected by current branch vs master"
      - export ENVIRONMENT=demo
      - export CURRENT_MASTER_COMMIT=$(git rev-parse master)
      - set -o pipefail
      - pnpm exec turbo build --filter=...[$CURRENT_MASTER_COMMIT...HEAD]
      - pnpm exec turbo build --filter=...[$CURRENT_MASTER_COMMIT...HEAD] --dry=json | tee turbo.log
      - ./packages/scripts/detect-built-apps.sh turbo.log
      - ls
    caches:
      - turbo
      - node
    artifacts:
      - builds.txt
      - apps/**/build/**

pipelines:
  branches:
    master:
      - <<: *buildAffectedDemo
      - <<: *runDeployTasksDemo
      - <<: *buildAffectedProd
      - <<: *runDeployTasksProd

  pull-requests:
    '**':
      - <<: *buildPullRequestChanges

  custom:
    run-pr-demo-deployment:
      - <<: *buildCurrentBranchDemo
      - <<: *runDeployTasksDemo
    build-all:
      - <<: *buildAllDemo
      - <<: *runDeployTasksDemo
      - <<: *buildAllProd
      - <<: *runDeployTasksProd

```
