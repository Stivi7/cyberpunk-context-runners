---
name: worktree-isolation
description: Use when an agent assignment may modify repository files and must be tracked safely through Git.
---

# Worktree Isolation

## Metadata

- Version: 1.0.0
- Triggers: Any mutating agent job, sequential or parallel
- Allowed agents: Nexus, Fragmenter, Daemon, Neon, Grid Master
- Side effects: Creates branches, worktrees, internal commits, merges, and local run state

## When to Use

Use for every job that may write repository files. Read-only planning and review do not need their own worktree.

## Inputs

Task id, slug, requested target, approved base commit, role, work unit, path ownership, dependencies, worktree root, and cleanup policy.

## Procedure

1. Resolve the user-provided integration branch or create `cyberpunk/<task-id>-<slug>` from the approved base commit.
2. Refuse an implicit protected branch or unrelated branch as the integration target.
3. Verify a project-local worktree root is ignored.
4. Create `cyberpunk/<task-id>/<role>-<work-unit>` as the worker branch and give it a dedicated worktree.
5. Record owner, integration branch, worker branch, worktree, base commit, dependencies, and status in local run state.
6. Run project setup and baseline verification inside the worktree.
7. After implementation verification, create an internal worker commit and return its SHA.
8. Require Gatekeeper approval before integration.
9. Merge approved workers into the integration branch in dependency order and run assembled verification.
10. After confirmed integration, perform safe worktree cleanup and apply branch cleanup policy.

## Verification

Confirm the worktree uses the recorded branch and base, the result commit is reachable, approval exists, merge state is recorded, and no protected branch was changed implicitly.

## Output

Integration branch, worker branch, worktree, base commit, baseline result, result commit, review state, merge state, assembled verification, and cleanup state.
