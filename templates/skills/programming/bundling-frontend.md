# Skill: Bundling Frontend Applications

## PURPOSE
Configure optimal bundling for frontend applications and libraries. Produce minimal, efficient bundles with correct asset handling for browsers.

## WHEN TO USE
- Setting up Vite for frontend SPA or library builds
- Handling special asset types (images, fonts, workers)
- Optimizing bundle size and build performance
- Configuring code splitting and lazy loading

## INPUTS
- framework (optional) - Framework type: `react`, `vue`, `svelte`
- assets (optional) - Special assets to handle: `images`, `fonts`, `webworkers`, `wasm`
- bundle_strategy (optional) - `code-split` for web apps, `single-file` for simple apps

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

### Library Mode (for npm packages)

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
      formats: ['es', 'cjs'],
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

## BEST PRACTICES

### Frontend Builds
- Always use `target: 'es2020'` or higher for modern browsers
- Enable CSS code splitting for better caching
- Use manual chunks to separate vendor code
- Set appropriate `assetsInlineLimit` (4KB is good default)
- Enable brotli/gzip precompression for static hosting

### General
- Analyze bundle size regularly
- Use dynamic imports for code splitting
- Tree shake unused dependencies
- Generate source maps for production debugging
- Test the bundle in the target environment

## COMMON MISTAKES TO AVOID
- Do NOT inline large assets (> 10KB) in frontend builds
- Do NOT bundle devDependencies in production
- Do NOT forget to handle native modules (.node files)

## REFERENCES
- Vite Build Guide: https://vitejs.dev/guide/build.html
- Vite Library Mode: https://vitejs.dev/guide/build.html#library-mode
