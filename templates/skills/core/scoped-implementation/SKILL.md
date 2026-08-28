---
name: scoped-implementation
description: Use when implementing an approved work packet inside an isolated worker worktree.
---

# Scoped Implementation

## Metadata

- Version: 1.0.0
- Triggers: Mutating work packet assigned to an implementation specialist
- Allowed agents: Daemon, Neon, Grid Master
- Side effects: Changes files and creates an internal worker commit

## When to Use

Use only after objective, scope, acceptance, branch, worktree, and required skills are explicit.

## Inputs

Work packet, role contract, project context, relevant memory, selected skills, and current worker state.

## Procedure

1. Confirm the worktree, base, allowed paths, and dependencies.
2. Inspect existing behavior and conventions.
3. Add a failing test before behavior changes when practical.
4. Make the smallest change satisfying acceptance criteria.
5. Run relevant discovered verification and inspect the complete diff.
6. Record checks not run and remaining risks.
7. Commit verified work to the worker branch.

## Verification

Confirm all changed files are in scope, required acceptance evidence exists, and the worker tree is clean after the result commit.

## Output

Changed files, acceptance results, observed commands, omitted checks, risks, result commit, and merge readiness.
