---
name: implementation-planning
description: Use when a standard or complex change needs explicit architecture, interfaces, sequencing, and verification before implementation.
---

# Implementation Planning

## Metadata

- Version: 1.0.0
- Triggers: Standard or complex task after requirements and repository context are known
- Allowed agents: Mind
- Side effects: May create a tracked plan

## When to Use

Use when implementation has meaningful dependencies, uncertainty, integration boundaries, or rollout risk. Avoid durable plans for obvious quick tasks.

## Inputs

Task brief, acceptance criteria, project context, decisions, constraints, and relevant memory.

## Procedure

1. Map acceptance criteria to affected components and invariants.
2. Define ownership and interfaces before independent jobs.
3. Describe data flow, failure behavior, compatibility, rollout, and rollback where relevant.
4. List exact implementation steps in dependency order.
5. Assign verification categories to each step.
6. Record assumptions and decisions that could change the result.

## Verification

Trace every acceptance criterion to a planned change and an observable validation method.

## Output

Proportional design, interface contracts, ordered steps, verification strategy, risks, and assumptions.
