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

Work packet, result commit, worker worktree, diff, project context, implementation evidence, baseline failures, and runtime-provided reviewer identity when exposed.

## Procedure

1. When native delegation is available, start in a fresh context; approval without fresh context is invalid. During parent-session fallback, review independently in the parent and record `review_agent_instance: null` plus `review_context: parent`.
2. Verify result commit, base, scope, and changed files.
3. Trace acceptance criteria to implementation and tests.
4. Review correctness, boundaries, failure handling, security, compatibility, and maintainability as applicable.
5. Rerun relevant verification independently.
6. Classify findings as critical, important, or optional with file evidence.
7. Approve merge readiness only after required findings are resolved.
8. After per-result integration, require a different fresh Gatekeeper instance for assembled review.

## Verification

The review identifies the exact commit and includes observed evidence for its decision. Native review uses fresh context. Parent-session fallback records parent context and a `null` identity; an unavailable runtime-provided identifier is never invented.

## Output

```yaml
review_agent_instance: runtime-provided-id-or-null
review_context: fresh
result_commit: def456
verification_observed: []
verification_skipped_reason: explicit reason when no verification was observed
review_status: approved
```

An approved per-result review requires a present `result_commit` and either non-empty `verification_observed` or an explicit `verification_skipped_reason`. An approved assembled review requires the same evidence and an `integrated_commit`.

Status, commit reviewed, acceptance results, verification, prioritized findings, residual risks, and merge-ready decision.
