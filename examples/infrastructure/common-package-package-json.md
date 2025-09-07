```json
{
  "name": "@repo/schemas",
  "version": "0.1.0",
  "private": true,
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "build": "pnpm check-types",
    "check-types": "tsc --noEmit"
  },
  "dependencies": {
    "tslib": "^2.8.1"
  },
  "devDependencies": {
    "typescript": "^5.4.5",
    "@repo/tsconfig": "workspace:*"
  },
  "peerDependencies": {
    "zod": "*"
  }
}
```
