---
name: repository-discovery
description: Use when project stack, commands, conventions, boundaries, or baseline health are unknown or stale.
---

# Repository Discovery

## Metadata

- Version: 1.0.0
- Triggers: New project, stale context, unfamiliar area, or contradictory evidence
- Allowed agents: Operator
- Side effects: Updates tracked project context

## When to Use

Use before standards or verification commands are inferred. Skip a full rescan when current evidence already covers the task area.

## Inputs

Repository tree, guidance files, dependency manifests, build configuration, automation, representative code, history, and task scope.

## Procedure

1. Inspect relevant files before making recommendations.
2. Record observed stack, structure, conventions, dependencies, and protected areas.
3. Derive command categories from repository documentation and automation.
4. Mark missing categories unavailable instead of inventing commands.
5. Separate facts, recommendations, unknowns, and baseline failures.

## Verification

Link important facts to repository evidence and confirm recorded commands match the project's own sources.

## Output

Updated project map, command registry, conventions, boundaries, unknowns, and baseline failures.
