```yaml
image: node:22

options:
  max-time: 10

test-lint: &test-lint
  step:
    name: Run linter
    script:
      - corepack enable
      - pnpm install --frozen-lockfile
      - pnpm audit --audit-level high --prod
      - pnpm run lint
    caches:
      - pnpm

test-unit: &test-unit
  step:
    name: Run unit tests
    script:
      - corepack enable
      - pnpm install --frozen-lockfile
      - pnpm run jest:unit:bitbucket
    caches:
      - pnpm

test-resolver: &test-resolver
  step:
    name: Run resolver unit tests
    script:
      - corepack enable
      - pnpm install --frozen-lockfile
      - pnpm run jest:resolver:bitbucket
    caches:
      - pnpm

test-integration: &test-integration
  step:
    name: Run integration tests
    size: 2x
    caches:
      - docker
      - pnpm
    services:
      - docker
    script:
      - corepack enable
      - pnpm install --frozen-lockfile
      - echo `cat /opt/atlassian/pipelines/agent/ssh/id_rsa` | sed -e 's/KEY-----/KEY-----\n/g; s/-----END/\n-----END/g;' > ~/.ssh/id_rsa
      - eval `ssh-agent -s` && chmod 600 ~/.ssh/id_rsa && ssh-add
      - git submodule update --remote --init
      - NODE_OPTIONS=--max-old-space-size=3072 pnpm run jest:integration:bitbucket

package: &package
  step:
    name: Package
    script:
      - corepack enable
      - pnpm install --frozen-lockfile
      - apt-get update && apt-get install -y zip rsync
      - pnpm run build
      - pnpm prune --prod
      - zip -r code-${BITBUCKET_COMMIT}.zip node_modules dist/src config package.json -x config/test.js -x config/development-server.js
      - du -sh code-${BITBUCKET_COMMIT}.zip
    caches:
      - pnpm
    artifacts:
      - code-*.zip

tag-release: &tagRelease
  step:
    name: Tag release
    script:
      - CURR_TIME=$(date +%Y-%m-%d--%H-%M-%S)
      - git tag -am "Tagging ${BITBUCKET_BRANCH} release ${BITBUCKET_BUILD_NUMBER}" release-$BITBUCKET_BRANCH--$BITBUCKET_BUILD_NUMBER--$CURR_TIME
      - git push origin release-$BITBUCKET_BRANCH--$BITBUCKET_BUILD_NUMBER--$CURR_TIME

run-migrations-demo: &run-migrations-demo
  step:
    name: Run migrations on demo
    image: atlassian/pipelines-awscli:1.19.62
    script:
      - cd ./deploy
      - ENVIRONMENT=demo ./run_migrations.sh

run-migrations-prod: &run-migrations-prod
  step:
    name: Run migrations on production
    image: atlassian/pipelines-awscli:1.19.62
    trigger: manual
    script:
      - cd ./deploy
      - ENVIRONMENT=prod ./run_migrations.sh

deploy-cloudwatch-alerts-demo: &deploy-cloudwatch-alerts-demo
  step:
    name: Deploy CloudWatch alerts to demo
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=demo COMMITHASH=${BITBUCKET_COMMIT} ./deploy-cloudwatch-alerts.sh

deploy-publish-scheduler-demo: &deploy-publish-scheduler-demo
  step:
    name: Deploy PublishScheduler to demo
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=demo COMMITHASH=${BITBUCKET_COMMIT} ./deploy-publish-scheduler.sh

deploy-tracking-event-relay-demo: &deploy-tracking-event-relay-demo
  step:
    name: Deploy TrackingEventRelay to demo
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=demo COMMITHASH=${BITBUCKET_COMMIT} ./deploy-tracking-event-relay.sh

deploy-user-api-demo: &deploy-user-api-demo
  step:
    name: Deploy UserAPI to demo
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=demo COMMITHASH=${BITBUCKET_COMMIT} ./deploy-user-api.sh

deploy-cloudwatch-alerts-prod: &deploy-cloudwatch-alerts-prod
  step:
    name: Deploy CloudWatch alerts to prod
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=prod COMMITHASH=${BITBUCKET_COMMIT} ./deploy-cloudwatch-alerts.sh

deploy-publish-scheduler-prod: &deploy-publish-scheduler-prod
  step:
    name: Deploy PublishScheduler to prod
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=prod COMMITHASH=${BITBUCKET_COMMIT} ./deploy-publish-scheduler.sh

deploy-tracking-event-relay-prod: &deploy-tracking-event-relay-prod
  step:
    name: Deploy TrackingEventRelay to prod
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=prod COMMITHASH=${BITBUCKET_COMMIT} ./deploy-tracking-event-relay.sh

deploy-user-api-prod: &deploy-user-api-prod
  step:
    name: Deploy UserAPI to prod
    image: atlassian/pipelines-awscli:1.18.190
    script:
      - cd ./deploy
      - ENVIRONMENT=prod COMMITHASH=${BITBUCKET_COMMIT} ./deploy-user-api.sh

publish-user-api: &publish-user-api
  step:
    name: Upload UserAPI build artifacts
    image: atlassian/pipelines-awscli:1.16.302
    script:
      - aws s3 cp "code-${BITBUCKET_COMMIT}.zip" "s3://earnest-build-artifacts/ear-user-api/code-${BITBUCKET_COMMIT}.zip"

publish-publish-scheduler: &publish-publish-scheduler
  step:
    name: Upload PublishScheduler build artifacts
    image: atlassian/pipelines-awscli:1.16.302
    script:
      - aws s3 cp "code-${BITBUCKET_COMMIT}.zip" "s3://earnest-build-artifacts/publishScheduler/code-${BITBUCKET_COMMIT}.zip"

publish-tracking-event-relay: &publish-tracking-event-relay
  step:
    name: Upload TrackingEventRelay build artifacts
    image: atlassian/pipelines-awscli:1.16.302
    script:
      - aws s3 cp "code-${BITBUCKET_COMMIT}.zip" "s3://earnest-build-artifacts/trackingEventRelay/code-${BITBUCKET_COMMIT}.zip"

test: &test
  parallel:
    - <<: *test-lint
    - <<: *test-unit
    - <<: *test-resolver
    - <<: *test-integration

publish: &publish
  parallel:
    - <<: *publish-user-api
    - <<: *publish-publish-scheduler
    - <<: *publish-tracking-event-relay

deploy-demo: &deploy-demo
  parallel:
    - <<: *deploy-cloudwatch-alerts-demo
    - <<: *deploy-publish-scheduler-demo
    - <<: *deploy-tracking-event-relay-demo
    - <<: *deploy-user-api-demo

deploy-prod: &deploy-prod
  parallel:
    - <<: *deploy-cloudwatch-alerts-prod
    - <<: *deploy-publish-scheduler-prod
    - <<: *deploy-tracking-event-relay-prod
    - <<: *deploy-user-api-prod

pipelines:
  pull-requests:
    '**':
      - <<: *test
      - <<: *package

  branches:
    master:
      - <<: *test
      - <<: *package
      - <<: *publish
      - <<: *run-migrations-demo
      - <<: *deploy-demo
      - <<: *run-migrations-prod
      - <<: *deploy-prod
      - <<: *tagRelease

definitions:
  caches:
    pnpm: ~/.local/share/pnpm/store
```
