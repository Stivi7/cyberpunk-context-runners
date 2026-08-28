---
name: test-first-development
description: Use when changing behavior or fixing a defect and an executable automated test is practical.
---

# Test-First Development

## Metadata

- Version: 1.0.0
- Triggers: Behavior change, bug fix, or refactor with observable behavior
- Allowed agents: Daemon, Neon, Grid Master
- Side effects: Adds or changes tests and implementation

## When to Use

Use for executable behavior. For pure documentation or configuration without a practical executable assertion, record why a test is not appropriate and use the strongest available validation.

## Inputs

Acceptance criterion, current behavior, project test conventions, and relevant command registry entry.

## Procedure

1. Write one minimal test for the desired behavior.
2. Run it and confirm it fails for the missing behavior, not a test defect.
3. Implement the smallest passing change.
4. Run the focused test and relevant broader suite.
5. Refactor only while green.
6. Repeat for the next behavior.

## Verification

Record the expected failing observation and the later passing observation. A test that never failed does not prove the change.

## Output

Test added, red evidence, implementation summary, green evidence, and justified exceptions.
