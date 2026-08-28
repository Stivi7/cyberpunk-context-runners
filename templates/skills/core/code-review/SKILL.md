---
name: code-review
description: Use when a worker result commit needs independent requirement, correctness, risk, and maintainability review before integration.
---

# Code Review

## Metadata

- Version: 1.0.0
- Triggers: Worker result ready for Gatekeeper review
- Allowed agents: Gatekeeper
- Side effects: May block integration and request revision

## When to Use

Use before every worker merge. Review the actual commit and diff, not only the handoff summary.

## Inputs

Work packet, result commit, worker worktree, diff, project context, implementation evidence, and baseline failures.

## Procedure

1. Verify result commit, base, scope, and changed files.
2. Trace acceptance criteria to implementation and tests.
3. Review correctness, boundaries, failure handling, security, compatibility, and maintainability as applicable.
4. Rerun relevant verification independently.
5. Classify findings as critical, important, or optional with file evidence.
6. Approve merge readiness only after required findings are resolved.

## Verification

The review identifies the exact commit and includes fresh observed evidence for its decision.

## Output

Status, commit reviewed, acceptance results, verification, prioritized findings, residual risks, and merge-ready decision.
