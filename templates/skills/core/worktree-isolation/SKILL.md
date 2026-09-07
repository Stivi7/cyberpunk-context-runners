---
name: worktree-isolation
description: Use when an agent assignment may modify repository files and must be tracked safely through Git.
---

# Worktree Isolation

## Metadata

- Version: 1.0.0
- Triggers: Mutating implementation jobs, sequential or parallel
- Allowed agents: Nexus, Fragmenter, Daemon, Neon, Grid Master
- Side effects: Creates branches, worktrees, internal commits, merges, and local run state

## When to Use

Use for every mutating implementation job that may write repository files. The only approved planning-artifact exception is an approved PRD that The Fixer writes and commits by itself on the current named branch after design and artifact approval. This exception does not exempt implementation or unrelated files from worker branch, review, and integration requirements. Read-only planning and review do not need their own worktree.

## Inputs

Task id, slug, requested target, approved base commit, role, work unit, allowed scope, dependencies, integration contract, worktree root, runtime isolation capability, and cleanup policy.

## Procedure

1. Resolve the user-provided integration branch or create `cyberpunk/<task-id>-<slug>` from the approved base commit.
2. Refuse an implicit protected branch or unrelated branch as the integration target.
3. Verify a project-local worktree root is ignored.
4. Create `cyberpunk/<task-id>/<role>-<work-unit>` as the worker branch and give it a dedicated worktree.
5. Accept a native runtime worktree copy only when it preserves the recorded worker branch, base commit, allowed scope, and integration contract. Otherwise Nexus creates the Cyberpunk worktree before dispatch.
6. Record owner, integration branch, worker branch, worktree, base commit, allowed scope, integration contract, dependencies, and status in local run state.
7. Run project setup and baseline verification inside the worktree.
8. After implementation verification, create an internal worker commit and return its SHA.
9. Require Gatekeeper approval before integration.
10. Merge approved workers into the integration branch in dependency order and run assembled verification.
11. After confirmed integration, perform safe worktree cleanup and apply branch cleanup policy.

## Verification

Confirm the worktree uses the recorded branch and base, the result commit is reachable, approval exists, merge state is recorded, and no protected branch was changed implicitly.

## Output

Integration branch, worker branch, worktree, base commit, baseline result, result commit, review state, merge state, assembled verification, and cleanup state.
