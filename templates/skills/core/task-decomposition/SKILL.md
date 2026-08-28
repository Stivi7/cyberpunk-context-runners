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
3. Assign one owner and non-overlapping path scope per job.
4. Where paths or behavior interact, define an explicit integration contract.
5. Mark safe concurrency and dependency order.
6. Produce complete work packets with acceptance and skills.

## Verification

Confirm no concurrent jobs own the same mutable surface without a named integration owner.

## Output

Ordered work packets, ownership map, dependency graph, concurrency decision, and integration order.
