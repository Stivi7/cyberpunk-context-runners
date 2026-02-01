# Skill: Bundling Node.js Services

## PURPOSE
Configure optimal bundling for Node.js applications, serverless deployments, and Lambda handlers. Produce minimal, efficient bundles with correct module handling for Node.js runtimes.

## WHEN TO USE
- Bundling Node.js applications for AWS Lambda
- Configuring esbuild for fast server-side compilation
- Creating single-file bundles for serverless deployments
- Optimizing bundle size for cold start performance

## INPUTS
- target (required) - Build target: `lambda`, `library`
- framework (optional) - Framework type: `express`, `nestjs`
- bundle_strategy (optional) - `single-file` for Lambda, `external-deps` for layers

---

## ESBUILD CONFIGURATION

### Lambda-Optimized Build

```javascript
// build.js
const esbuild = require('esbuild')

await esbuild.build({
  entryPoints: ['src/lambda-handler.ts'],
  outfile: 'dist/index.js',
  
  // Required for Node.js/Lambda
  platform: 'node',
  target: 'node20', // Match your Lambda runtime
  
  // Bundle everything into single file
  bundle: true,
  
  // Format (cjs for Lambda compatibility)
  format: 'cjs',
  
  // Minification
  minify: true,
  
  // Source maps (optional for production)
  sourcemap: false,
  
  // Tree shaking
  treeShaking: true,
  
  // External packages (AWS SDK v3 is included in Lambda runtime)
  external: [
    '@aws-sdk/*',  // AWS SDK v3 is provided by Lambda
    // Or use --packages=external to exclude all node_modules
  ],
  
  // Native module handling
  loader: {
    '.node': 'file',
  },
})
```

### esbuild CLI for Lambda

```bash
# Single-file Lambda bundle
esbuild src/handler.ts \
  --bundle \
  --platform=node \
  --target=node20 \
  --outfile=dist/index.js \
  --minify \
  --external:@aws-sdk/*

# With external dependencies (use Lambda layers or node_modules)
esbuild src/handler.ts \
  --bundle \
  --platform=node \
  --target=node20 \
  --outfile=dist/index.js \
  --packages=external
```

---

## SERVERLESS FRAMEWORK BUNDLING

### Express.js for Lambda

```typescript
// src/lambda.ts
import serverlessExpress from '@vendia/serverless-express'
import { app } from './app'

export const handler = serverlessExpress({ app })
```

```typescript
// vite.config.lambda.ts
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/lambda.ts'),
      formats: ['cjs'],
      fileName: () => 'index.js',
    },
    rollupOptions: {
      external: [
        // AWS SDK provided by Lambda runtime
        '@aws-sdk/client-s3',
        '@aws-sdk/client-dynamodb',
        // Keep these external if using Lambda layers
      ],
    },
    outDir: 'dist',
    emptyOutDir: true,
  },
  resolve: {
    // Ensure proper module resolution
    conditions: ['node'],
  },
})
```

### NestJS for Lambda

```typescript
// src/lambda.ts
import { NestFactory } from '@nestjs/core'
import { ExpressAdapter } from '@nestjs/platform-express'
import serverlessExpress from '@vendia/serverless-express'
import { AppModule } from './app.module'

let cachedServer: any

async function bootstrap(): Promise<any> {
  if (!cachedServer) {
    const expressApp = require('express')()
    const adapter = new ExpressAdapter(expressApp)
    const nestApp = await NestFactory.create(AppModule, adapter)
    nestApp.enableCors()
    await nestApp.init()
    cachedServer = serverlessExpress({ app: expressApp })
  }
  return cachedServer
}

export const handler = async (event: any, context: any) => {
  const server = await bootstrap()
  return server(event, context)
}
```

```typescript
// vite.config.lambda.ts
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/lambda.ts'),
      formats: ['cjs'],
      fileName: () => 'index.js',
    },
    rollupOptions: {
      external: [
        '@nestjs/core',
        '@nestjs/common',
        '@nestjs/platform-express',
        // Externalize large dependencies for Lambda layers
      ],
    },
    outDir: 'dist',
    emptyOutDir: true,
  },
})
```

---

## LAMBDA-SPECIFIC OPTIMIZATIONS

### Bundle Size Targets

| Lambda Component | Target Size | Strategy |
|------------------|-------------|----------|
| Simple handler | < 1 MB | Single file, minified |
| API with deps | 1-10 MB | Externalize heavy libs |
| Full framework | > 10 MB | Lambda layers for deps |

### Cold Start Optimization

```typescript
// Minimize initialization code
const client = new DynamoDBClient({}) // Initialize outside handler

export const handler = async (event) => {
  // Handler logic here
}
```

### External Dependencies Strategy

```typescript
// Option 1: Bundle everything (small deps only)
// vite.config.ts
rollupOptions: {
  external: ['@aws-sdk/*'] // Only externalize AWS SDK
}

// Option 2: Use Lambda layer for heavy deps
// vite.config.ts
rollupOptions: {
  external: [
    '@aws-sdk/*',
    'lodash',
    'moment',
    // List all deps to be provided by layer
  ]
}
```

---

## BEST PRACTICES

### Lambda Builds
- Always set `platform: 'node'` in esbuild
- Match `target` to your Lambda Node.js runtime
- Externalize AWS SDK v3 (included in Lambda)
- Minify production bundles
- Use single-file output for simple handlers
- Consider Lambda layers for heavy dependencies

### General
- Analyze bundle size regularly
- Tree shake unused dependencies
- Generate source maps for production debugging
- Test the bundle in the target environment

## COMMON MISTAKES TO AVOID
- Do NOT bundle AWS SDK v3 (use `external`)
- Do NOT forget to set `platform: 'node'` for Lambda
- Do NOT forget to handle native modules (.node files)

## REFERENCES
- esbuild Documentation: https://esbuild.github.io/
- AWS Lambda Node.js Runtime: https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html
- Vite Library Mode: https://vitejs.dev/guide/build.html#library-mode
