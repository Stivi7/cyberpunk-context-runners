# Skill: Bundling & Build Configuration

## PURPOSE
Configure optimal bundling for frontend applications, libraries, and serverless deployments. Produce minimal, efficient bundles with correct asset handling.

## WHEN TO USE
- Setting up Vite for frontend SPA or library builds
- Bundling Node.js applications for AWS Lambda
- Configuring esbuild for fast compilation
- Handling special asset types (images, fonts, workers)
- Optimizing bundle size and build performance

## INPUTS
- target (required) - Build target: `frontend`, `lambda`, `library`
- framework (optional) - Framework type: `react`, `vue`, `svelte`, `express`, `nestjs`
- assets (optional) - Special assets to handle: `images`, `fonts`, `webworkers`, `wasm`
- bundle_strategy (optional) - `single-file` for Lambda, `code-split` for web apps

---

## VITE CONFIGURATION

### Frontend SPA Build

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react' // or @vitejs/plugin-vue, etc.

export default defineConfig({
  plugins: [react()],
  
  build: {
    // Target modern browsers (default: 'baseline-widely-available')
    target: 'es2020',
    
    // Output directory
    outDir: 'dist',
    
    // Enable source maps for production debugging
    sourcemap: true,
    
    // Minification (esbuild by default, or 'terser' for smaller bundles)
    minify: 'esbuild',
    
    // CSS handling
    cssCodeSplit: true,
    cssMinify: true,
    
    // Asset handling
    assetsInlineLimit: 4096, // Inline assets < 4KB as base64
    
    // Rollup-specific options
    rollupOptions: {
      output: {
        // Manual chunk splitting for vendor code
        manualChunks: {
          vendor: ['react', 'react-dom'],
          // Add other large dependencies here
        },
        // Entry file naming
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash][extname]',
      },
    },
  },
  
  // Asset handling
  assetsInclude: ['**/*.gltf', '**/*.glb'], // Add custom asset types
})
```

### Library Mode (for npm packages or Lambda handlers)

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    // Library mode configuration
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'MyLibrary',
      formats: ['es', 'cjs'], // or ['cjs'] for Lambda compatibility
      fileName: (format) => `my-lib.${format}.js`,
    },
    
    // Rollup options for library builds
    rollupOptions: {
      // External dependencies - don't bundle these
      external: [
        'react',
        'react-dom',
        // Add other peer dependencies
      ],
      output: {
        // Preserve exports for libraries
        preserveModules: false,
        // Interop for CJS builds
        interop: 'esModule',
      },
    },
    
    // Disable CSS code splitting for libraries
    cssCodeSplit: false,
  },
})
```

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

## ASSET HANDLING

### Vite Asset Configuration

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    // Inline small assets as base64
    assetsInlineLimit: 4096,
    
    // Custom asset file naming
    rollupOptions: {
      output: {
        assetFileNames: (assetInfo) => {
          const info = assetInfo.name.split('.')
          const ext = info[info.length - 1]
          if (/\.(png|jpe?g|gif|svg|webp|avif)$/.test(assetInfo.name)) {
            return 'images/[name]-[hash][extname]'
          }
          if (/\.(woff2?|ttf|otf|eot)$/.test(assetInfo.name)) {
            return 'fonts/[name]-[hash][extname]'
          }
          return 'assets/[name]-[hash][extname]'
        },
      },
    },
  },
  
  // Handle special file types
  assetsInclude: [
    '**/*.gltf',
    '**/*.glb',
    '**/*.mp3',
    '**/*.mp4',
  ],
})
```

### Web Workers

```typescript
// vite.config.ts
export default defineConfig({
  worker: {
    format: 'es',
    plugins: [],
  },
  build: {
    // Code splitting for workers
    rollupOptions: {
      output: {
        manualChunks: {
          'worker-vendor': ['heavy-library'],
        },
      },
    },
  },
})
```

```typescript
// Usage
const worker = new Worker(new URL('./worker.ts', import.meta.url), {
  type: 'module',
})
```

---

## OPTIMIZATION STRATEGIES

### Bundle Analysis

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig({
  build: {
    rollupOptions: {
      plugins: [
        visualizer({
          filename: 'dist/stats.html',
          open: true,
          gzipSize: true,
          brotliSize: true,
        }),
      ],
    },
  },
})
```

### Code Splitting Patterns

```typescript
// Lazy load routes
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Settings = lazy(() => import('./pages/Settings'))

// Dynamic imports with prefetch
const heavyModule = await import(/* webpackPrefetch: true */ './heavy-module')
```

### Tree Shaking Optimization

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    // Enable aggressive tree shaking
    rollupOptions: {
      treeshake: {
        moduleSideEffects: false,
        propertyReadSideEffects: false,
      },
    },
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

### Frontend Builds
- Always use `target: 'es2020'` or higher for modern browsers
- Enable CSS code splitting for better caching
- Use manual chunks to separate vendor code
- Set appropriate `assetsInlineLimit` (4KB is good default)
- Enable brotli/gzip precompression for static hosting

### Lambda Builds
- Always set `platform: 'node'` in esbuild
- Match `target` to your Lambda Node.js runtime
- Externalize AWS SDK v3 (included in Lambda)
- Minify production bundles
- Use single-file output for simple handlers
- Consider Lambda layers for heavy dependencies

### General
- Analyze bundle size regularly
- Use dynamic imports for code splitting
- Tree shake unused dependencies
- Generate source maps for production debugging
- Test the bundle in the target environment

## COMMON MISTAKES TO AVOID
- Do NOT bundle AWS SDK v3 (use `external`)
- Do NOT forget to set `platform: 'node'` for Lambda
- Do NOT inline large assets (> 10KB) in frontend builds
- Do NOT bundle devDependencies in production
- Do NOT forget to handle native modules (.node files)

## REFERENCES
- Vite Build Guide: https://vitejs.dev/guide/build.html
- Vite Library Mode: https://vitejs.dev/guide/build.html#library-mode
- esbuild Documentation: https://esbuild.github.io/
- AWS Lambda Node.js Runtime: https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html
