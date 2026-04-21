# esbuild-plugin-vue3

An esbuild plugin that compiles Vue 3 Single File Components (SFCs) — template,
script/script-setup, and style blocks — into ESBuild-consumable JavaScript.

## Team Standards

@.ai-config/claude/coding-style.md
@.ai-config/claude/testing-standards.md
@.ai-config/claude/security.md
@.ai-config/claude/git-workflow.md
@.ai-config/claude/ai-safe-development.md

## Project Overview

| Item | Value |
|---|---|
| Language | TypeScript |
| Runtime | Node.js |
| Test framework | Vitest |
| Build | `tsc` → `dist/` |
| Entry point | `src/index.ts` |

## Architecture

```
src/
  index.ts      Plugin entry — registers all esbuild onResolve / onLoad hooks
  paths.ts      PathResolver — loads tsconfig path aliases and applies them
  options.ts    Plugin options type definitions
  utils.ts      getFullPath, fileExists, AsyncCache, getUrlParams
  html.ts       Optional HTML generation for dev server
  random.ts     Seeded random bytes (for stable scope IDs in watch mode)

test/
  plugin.test.ts   Integration tests — full esbuild builds against fixtures
  paths.test.ts    Unit tests for PathResolver
  fixtures/        Input .vue / .ts files used by tests
```

## Key Design Decisions

### onResolve handler branching (src/index.ts)

The `.vue` `onResolve` handler splits on import style to avoid resolving tsconfig
path aliases with a plain `path.join`:

- **Absolute** paths (virtual SFC sub-imports like `…?type=script`) — used as-is.
- **Relative** paths starting with `.` — resolved with `path.join(resolveDir, path)`.
- **Non-relative, non-absolute** (tsconfig aliases like `'components/Button.vue'`) —
  delegated to `build.resolve()` so esbuild's native tsconfig paths apply.
  A `__vuePlugin_resolving` flag in `pluginData` prevents infinite recursion.

### SFC compilation flow

1. `onLoad` for `namespace: file` reads the `.vue` source and emits a stub that
   imports `?type=script`, `?type=template`, and `?type=style` virtual paths.
2. `onLoad` for `namespace: sfc-script` compiles the script block via
   `@vue/compiler-sfc`, using `fs: ts.sys` so TypeScript resolves imported types
   through tsconfig paths (required for `defineProps<ImportedType>()`).
3. `onLoad` for `namespace: sfc-template` compiles the template.
4. `onLoad` for `namespace: sfc-style` compiles styles, with SCSS importer
   support via `resolver.replaceRules()`.

### Path alias resolution (src/paths.ts)

`PathResolver.init()` reads `tsconfig.json` via TypeScript's own APIs so `extends`,
`baseUrl`, and `paths` are all resolved correctly. Rules are compiled to regexes
that produce absolute paths, so `fileExists` checks work cross-platform.

When `mustReplace` is true (rules loaded), a generic `/.*/` `onResolve` handler is
registered first and applies alias rules to all imports. For `.vue` aliased imports
this handler fires before the `.vue`-specific handler (registration order).

### SFC filename — absolute vs. relative

`sfc.parse()` receives an **absolute** path so `@vue/compiler-sfc` can walk up the
directory tree to find `tsconfig.json` for type resolution.
`script.__file` is set to a **relative** path for Vue devtools display.

## Running Tests

```bash
npm test          # vitest run (all tests)
npm run test:watch
```

## Building

```bash
npm run prepare   # rimraf dist && tsc
```

## Adding a Test Fixture

1. Create the `.vue` / `.ts` files under `test/fixtures/`.
2. Add an `entry-*.ts` (or a subdirectory with its own entry) as the esbuild
   entry point.
3. Use `buildFixture(entry, pluginOpts, buildOpts)` in `test/plugin.test.ts`.
   Pass `buildOpts.tsconfig` when the fixture needs path alias resolution.
