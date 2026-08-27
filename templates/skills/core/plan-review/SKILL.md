---
name: plan-review
description: Use when a complex engineering plan needs adversarial review before implementation begins.
---

# Plan Review

## Metadata

- Version: 1.0.0
- Triggers: Complex plan ready for approval or materially revised after a defect
- Allowed agents: Interrogator
- Side effects: May require plan revision

## When to Use

Use for high-risk plans. Do not block lower-risk work for style preferences.

## Inputs

Task brief, plan, project context, decisions, contracts, authority, and risk classification.

## Procedure

1. Trace acceptance criteria through the plan.
2. Challenge ambiguity, invariants, boundaries, failure paths, compatibility, security, migration, rollback, and observability as applicable.
3. Identify missing evidence or ownership.
4. Classify findings as blocking, important, or optional.
5. Approve or return precise revisions to Mind.

## Verification

Every required finding must cite the affected requirement, plan section, or repository evidence.

## Output

Approval status, prioritized findings, required revisions, questions, and residual risks.
