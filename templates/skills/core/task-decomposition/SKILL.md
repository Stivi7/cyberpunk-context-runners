---
name: task-decomposition
description: Use when an approved complex plan must be split into dependency-aware jobs with safe ownership boundaries.
---

# Task Decomposition

## Metadata

- Version: 1.0.0
- Triggers: Approved complex plan requiring multiple work units
- Allowed agents: Fragmenter
- Side effects: Creates work packets

## When to Use

Use when multiple specialists or independently verifiable units are justified. Avoid fragmentation that creates more coordination than value.

## Inputs

Approved plan, interface contracts, repository map, role capabilities, and verification strategy.

## Procedure

1. Build the dependency graph.
2. Group cohesive changes that can be verified independently.
3. Assign one owner and non-overlapping mutable `allowed_scope` per job.
4. Where paths or behavior interact, name an `integration_owner` and define a concrete `integration_contract`.
5. Mark `parallel_safe: true` only when dependencies are satisfied and mutable paths do not overlap. Worktree isolation does not make overlap safe; otherwise mark it false or define the integration owner and contract.
6. Produce complete work packets with acceptance, required skills, `dependencies`, `required_skills`, and model profile `model_profile`.

## Verification

Confirm no `parallel_safe` concurrent jobs own the same mutable surface without a named integration owner and concrete integration contract.

## Output

Ordered work packets with this required shape, ownership map, dependency graph, concurrency decision, and integration order:

```yaml
parallel_safe: true
dependencies: []
allowed_scope:
  - path/to/owned/**
integration_owner: null
integration_contract: null
required_skills: []
model_profile: balanced
```
