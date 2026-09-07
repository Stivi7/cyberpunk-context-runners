# The Fixer PRD Creator Design

**Date:** 2026-08-28
**Status:** Approved

## Summary

Cyberpunk Context Runners will add The Fixer, a client-facing requirements persona that turns an early product idea into a user-approved, committed product requirements document (PRD). The Fixer will be backed by a portable `requirements-discovery` core skill modeled on the interaction pattern of the Superpowers brainstorming skill without depending on Superpowers at runtime.

Users may invoke The Fixer directly. The Nexus will also route new-product, feature, and architectural requests to The Fixer automatically when material requirements remain unresolved. The Fixer asks focused questions, compares approaches, obtains section-by-section approval, writes and self-reviews the PRD, asks the user to review the resulting file, commits the approved PRD on the current branch, and then asks whether to hand it to Nexus.

## Goals

- Provide a named cyberpunk persona for collaborative product discovery.
- Turn ambiguous product ideas into durable requirements that Nexus and The Mind can consume without repeating discovery.
- Match the useful behavior of Superpowers brainstorming: proportional depth, one question at a time, explicit alternatives, progressive approval, and no artifact creation before design approval.
- Preserve runtime neutrality by shipping the discovery method as a Cyberpunk core skill.
- Commit an approved PRD on the current branch before any Nexus handoff.
- Keep product discovery separate from implementation planning and implementation work.

## Non-goals

- Implement the product or feature described by a PRD.
- Replace The Mind's responsibility for technical architecture and implementation planning.
- Require the Superpowers plugin or any vendor-specific agent capability.
- Route routine fixes, maintenance, or already well-specified tasks through PRD discovery.
- Design cross-repository memory or multi-runtime plugin packaging; those remain separate follow-up projects in `todo.md`.
- Create a new worker branch or worktree for PRD authoring.

## Selected Approach

The Fixer will be a dedicated persona backed by a separate `requirements-discovery` core skill.

The alternatives were rejected for these reasons:

- Depending directly on Superpowers brainstorming would make behavior conditional on an external installation and conflict with runtime neutrality.
- Embedding the complete discovery procedure in `agents/fixer.md` would couple identity to method, make the procedure harder to reuse, and diverge from the existing separation between roles and skills.

The custom skill may reproduce the process and safeguards of Superpowers brainstorming, but its wording, contracts, paths, and handoff semantics will be native to Cyberpunk Context Runners.

## Architecture and Responsibilities

The PRD flow precedes Nexus implementation coordination:

```text
Idea or discovery-heavy request
        |
        v
The Fixer + requirements-discovery skill
        |
        v
User-approved PRD
        |
        v
Commit PRD on current branch
        |
        v
Ask whether to hand off
        |
        +-- no --> stop with committed PRD
        |
        +-- yes -> The Nexus -> The Mind -> implementation workflow
```

### The Fixer

The Fixer owns:

- Product-discovery dialogue.
- Discovery-depth classification.
- Requirement and scope clarification.
- Alternative approaches and trade-off framing.
- Progressive user approval.
- PRD composition and self-review.
- Focused commit creation on the current branch.
- The explicit offer to hand the approved PRD to Nexus.

The Fixer does not own implementation, implementation planning, substantive code changes, or approval of its own product decisions.

### The Nexus

Nexus owns automatic routing into discovery and coordination after an approved handoff. Nexus consumes the approved PRD and does not repeat discovery unless it identifies a concrete contradiction or a deferred decision that blocks safe planning.

### The Mind

The Mind retains ownership of technical architecture, interface design, and implementation planning. The Fixer includes technical detail only when a technical choice is required to make product behavior or constraints unambiguous.

## Entry and Routing Rules

The Fixer has two supported entry paths:

1. A user explicitly invokes The Fixer for product discovery.
2. Nexus automatically routes a new-product, feature, or architectural request when material decisions are missing.

Materially incomplete requests include those missing one or more decisions needed to define the outcome safely, such as the target user, problem, scope boundary, expected behavior, constraints, or acceptance criteria.

Nexus must not route to The Fixer when:

- The request is a routine bug fix or maintenance task.
- The request is already sufficiently specified for proportional planning.
- The user supplies an approved PRD.
- A Fixer handoff declares discovery complete and contains no blocking deferred decision.

The discovery-complete marker in the handoff prevents a Fixer-to-Nexus routing loop.

## Requirements-Discovery Procedure

The core skill uses the following lifecycle:

1. Inspect repository context, relevant curated memory, existing specs, and applicable recent decisions.
2. Classify the discovery depth.
3. Decompose a request that is too large for one coherent PRD.
4. Ask one focused question at a time, preferring concise choices when they improve clarity.
5. Establish purpose, users, use cases, scope, constraints, success measures, authority boundaries, and risks.
6. Present two or three viable approaches, including trade-offs and a recommendation.
7. Present the proposed PRD in sections and request approval as the design progresses.
8. Write the PRD only after the complete design is approved.
9. Self-review the written artifact.
10. Ask the user to review the actual PRD file.
11. Commit only the approved PRD.
12. Ask whether to hand the PRD to Nexus.

### Proportional Depth

The Fixer classifies discovery into three levels:

- **Brief:** a bounded feature with a known user and outcome.
- **Standard:** a feature with multiple flows or meaningful product decisions.
- **Architectural:** a new product, cross-system behavior, or major uncertainty.

Depth changes the amount of exploration and design detail, not the approval gate. Every level requires approval before the PRD is written.

### Scope Decomposition

When a request contains multiple independently implementable products or subsystems, The Fixer first decomposes the request, records the relationships and suggested order, and then completes discovery for one PRD-sized slice. Each later slice receives its own discovery and approval cycle.

## PRD Contract

Approved PRDs are written to:

```text
specs/YYYY-MM-DD-<topic>-prd.md
```

Each PRD uses stable Markdown headings:

1. Summary and problem statement.
2. Target users and use cases.
3. Goals and measurable success criteria.
4. Non-goals and scope boundaries.
5. Functional requirements.
6. User journeys and expected behavior.
7. Constraints and non-functional requirements.
8. Considered approaches and accepted decisions.
9. Edge cases and failure behavior.
10. Acceptance criteria.
11. Dependencies and risks.
12. Deferred decisions.

A deferred decision must identify its owner, reason for deferral, and the stage at which it must be resolved. A decision that blocks safe planning cannot be deferred through the Nexus handoff.

## Approval, Commit, and Handoff

The Fixer uses three distinct gates:

1. **Design approval:** the user approves the requirements presented in conversation before any PRD file is created.
2. **Artifact approval:** after writing and self-review, the user reviews the actual PRD file.
3. **Handoff approval:** after the approved PRD is committed, The Fixer asks whether Nexus should continue from it.

### Current-Branch Commit

PRD authoring is an explicit planning-artifact exception to worker worktree isolation, matching the existing plan-authoring convention. The Fixer commits the PRD on the current named branch.

Before committing, The Fixer must:

- Confirm that the checkout is on a named branch.
- Inspect the working tree.
- Stage only the approved PRD path.
- Leave unrelated tracked and untracked changes untouched.
- Use a focused documentation commit message.
- Capture the resulting commit SHA and branch.

If a safe focused commit cannot be created, The Fixer reports the exact blocker and does not offer or claim a durable Nexus handoff.

### Handoff Contract

An approved handoff contains:

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

Runtimes with agent-routing support may continue directly as Nexus. Simpler runtimes present the same contract and continue sequentially. The protocol must describe the behavior honestly and must not claim that a separate agent ran when the runtime cannot provide one.

If the user declines handoff, the committed PRD remains the final artifact and no implementation workflow starts.

## Failure and Interruption Behavior

- If discovery stops before design approval, no PRD is written.
- If artifact review requests changes, The Fixer updates the PRD, repeats self-review, and requests artifact approval again before committing.
- If Git has no named current branch, the PRD cannot satisfy the approved commit contract; The Fixer reports the blocker.
- If the target PRD path already exists, The Fixer must not overwrite it silently. It either updates the explicitly identified existing PRD or selects a non-conflicting topic slug with the user's knowledge.
- If Nexus detects a contradiction after handoff, it returns the smallest concrete question to The Fixer or user instead of restarting discovery.
- If the user declines handoff, no state is treated as failed; the committed PRD is a valid terminal outcome.

## Repository Changes

Implementation is expected to add or update:

- `templates/agents/fixer.md`
- `templates/skills/core/requirements-discovery/SKILL.md`
- `templates/.cyberpunk/workflow.md`
- `templates/agents/nexus.md`
- `templates/README.md`
- `README.md`
- `cyberpunk`
- Relevant contract, CLI, integration, smoke, and documentation tests
- `todo.md`, marking only the PRD creator item complete while preserving the two follow-up projects

Generated adapters remain thin and runtime-neutral. They should continue routing normal tasks through canonical workflow rather than duplicating Fixer rules.

## Verification Strategy

Automated verification will cover:

- `cyberpunk init` generates The Fixer and the requirements-discovery skill.
- Ordinary initialization preserves existing generated files.
- Forced initialization refreshes framework-owned Fixer files.
- `cyberpunk validate` fails when the required Fixer persona or discovery skill is missing.
- The Fixer persona declares its responsibilities, non-responsibilities, default skill, PRD path, commit gate, and handoff gate.
- The discovery skill has portable frontmatter and contains the classification, questioning, alternatives, approval, self-review, and commit safeguards.
- Nexus routing distinguishes discovery-heavy product work from routine or already specified work.
- The workflow defines the discovery-complete handoff and prevents routing loops.
- Documentation lists the eleventh persona and the generated discovery skill.
- The full `bash tests/run.sh` suite passes.

## Acceptance Criteria

- A generated Cyberpunk project includes The Fixer persona and the `requirements-discovery` core skill.
- Users can invoke The Fixer directly.
- Nexus automatically routes incomplete new-product, feature, and architectural requests to The Fixer.
- Routine fixes and sufficiently specified tasks do not require a PRD.
- Discovery uses proportional depth, one question at a time, alternatives with trade-offs, and progressive approval.
- An approved PRD uses the documented path and stable content contract.
- The user reviews the written PRD before it is committed.
- The Fixer commits only the PRD on the current named branch.
- The Fixer asks before handing the committed PRD to Nexus.
- Nexus receives the PRD path, commit, branch, acceptance criteria, risks, and deferred decisions and does not repeat completed discovery without a concrete blocker.
- The system has no runtime dependency on Superpowers.
- Existing tests and new contract coverage pass.

## Follow-up Projects

After The Fixer is designed, planned, and implemented, the remaining `todo.md` items should be handled as separate architectural cycles:

1. A workspace-level graph for related repositories and shared curated memory.
2. Runtime adapter and plugin packaging for Codex, Claude Code, Cursor, and other supported tools.

The Fixer PRD contract deliberately leaves room for future related-repository metadata, but this project will not implement that metadata prematurely.
