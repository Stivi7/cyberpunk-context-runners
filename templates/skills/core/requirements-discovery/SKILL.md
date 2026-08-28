---
name: requirements-discovery
description: Use when a new product, feature, or architectural request needs collaborative discovery before Nexus can plan implementation.
---

# Requirements Discovery

## Metadata

- Version: 1.0.0
- Triggers: Direct Fixer invocation or Nexus routing of materially incomplete product work
- Allowed agents: Fixer
- Side effects: Writes and commits one user-approved PRD on the current named branch

## When to Use

Use for a new product, feature, or architectural change when the target user, problem, scope, expected behavior, constraints, or acceptance criteria still require material decisions. Do not use for routine fixes, maintenance, a sufficiently specified task, or an approved PRD with no blocking deferred decision.

## Inputs

The user's idea, repository context, relevant curated memory, existing specs, applicable decisions, authority boundaries, Git state, and answers gathered during discovery.

## Procedure

1. Inspect `.cyberpunk/project.md`, relevant memory, existing specs, applicable decisions, and current Git state before detailed questions.
2. Classify the discovery depth:
   - **Brief:** a bounded feature with a known user and outcome.
   - **Standard:** multiple flows or meaningful product decisions.
   - **Architectural:** a new product, cross-system behavior, or major uncertainty.
3. If the request contains independently implementable products or subsystems, show their relationships and suggested order, then complete one PRD-sized slice at a time.
4. Ask one focused question at a time. Prefer concise choices when they improve clarity, but allow an open answer when the available choices would constrain the user incorrectly.
5. Resolve purpose, target users, use cases, goals, measurable success, non-goals, behavior, constraints, authority, risks, and acceptance criteria. Include technical detail only when it is necessary to make a requirement unambiguous; The Mind owns later implementation architecture.
6. Present two or three viable approaches with trade-offs and a recommendation.
7. Present the requirements in sections proportional to their complexity and request design approval as the design progresses.
8. Do not create a PRD until the user has approved the complete design.
9. Resolve the PRD path under the literal pattern `specs/YYYY-MM-DD-<topic>-prd.md`. The Fixer must not overwrite an existing PRD silently: update it only when the user explicitly identified it, otherwise disclose the conflict and agree on a non-conflicting topic slug. Write the approved PRD with these headings:
   - Summary and Problem Statement
   - Target Users and Use Cases
   - Goals and Success Criteria
   - Non-goals and Scope Boundaries
   - Functional Requirements
   - User Journeys and Expected Behavior
   - Constraints and Non-functional Requirements
   - Considered Approaches and Accepted Decisions
   - Edge Cases and Failure Behavior
   - Acceptance Criteria
   - Dependencies and Risks
   - Deferred Decisions
10. Self-review for placeholders, contradictions, ambiguous requirements, excess scope, and missing acceptance coverage. A deferred decision records its owner, reason, and resolution stage; it cannot block safe Nexus planning.
11. Ask the user to review the written file. Revise and repeat self-review until artifact approval.
12. Before committing:
    - Confirm `git branch --show-current` returns the current named branch.
    - Inspect tracked, untracked, and already staged changes.
    - Stage only the approved PRD path without unstaging or modifying unrelated work.
    - Verify the PRD diff and use a path-limited documentation commit so unrelated staged paths remain untouched.
    - The Git procedure is to commit only the approved PRD.
    - Capture the resulting branch and commit SHA.
13. Ask whether to hand the committed PRD to Nexus. Do not continue automatically.
14. On approval, emit the handoff contract below. On decline, stop with the committed PRD as a successful terminal result.

## Verification

Before offering handoff, verify all of the following:

- The design and written artifact have separate recorded user approvals.
- The PRD exists at the agreed non-conflicting path and contains every required heading.
- No placeholder or contradictory requirement remains.
- Every acceptance criterion is measurable from observable behavior or evidence.
- Every deferred decision has an owner, reason, and resolution stage and none blocks planning.
- The current branch is named and the resulting commit contains only the approved PRD.
- The handoff is offered only after the commit succeeds.

## Output

Return the PRD path, current branch, commit SHA, acceptance criteria, risks, deferred decisions, and approval state. After explicit handoff approval, include:

```yaml
source: fixer
discovery_complete: true
prd_path: specs/YYYY-MM-DD-topic-prd.md
prd_commit: abc123
branch: current-branch
acceptance_criteria: []
risks: []
deferred_decisions: []
user_authorized_handoff: true
```

If the commit cannot be created safely, report the exact blocker and do not emit an authorized handoff.
