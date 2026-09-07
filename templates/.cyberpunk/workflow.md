# Cyberpunk Engineering Team Workflow

The Nexus is the default entry point for engineering tasks and owns coordination through delivery. The Fixer is the direct entry point for product discovery and may also receive discovery-heavy work from Nexus. Agents exchange explicit artifacts; they do not rely on hidden conversational context.

## Intake

Nexus converts the request into an objective, measurable acceptance criteria, scope boundaries, authority constraints, target branch preference, and known risks. It reads `.cyberpunk/config.yml`, `.cyberpunk/project.md`, relevant memory, and current Git state before assigning work.

If the user names an integration branch, Nexus uses it. Otherwise Nexus creates `cyberpunk/<task-id>-<slug>` from the approved current base. Nexus never selects a protected branch implicitly.

## Requirements Discovery

Users may invoke The Fixer directly. Before classification, Nexus routes a new product, feature, or architectural request to The Fixer when material decisions about the target user, problem, scope, expected behavior, constraints, or acceptance criteria remain unresolved. Nexus does not route a routine bug fix or maintenance task, a sufficiently specified request, or an approved PRD with no blocking deferred decision.

The Fixer loads `requirements-discovery`, inspects project context and relevant memory, and uses Brief, Standard, or Architectural discovery depth. It asks one focused question at a time, compares two or three viable approaches, and presents requirements in sections for user approval. Work that is too broad for one PRD is decomposed before discovery continues.

No PRD is written before design approval. After approval, The Fixer writes `specs/YYYY-MM-DD-<topic>-prd.md`, self-reviews it, and asks the user to review the actual file. After artifact approval, The Fixer confirms the current named branch and creates a focused commit containing only the approved PRD.

Approved PRD authoring is a planning-artifact exception to worker worktree isolation. It does not exempt implementation or any other mutating assignment from its worker branch, review, and integration requirements.

Only after the commit succeeds does The Fixer ask whether to hand the PRD to Nexus. Declining the handoff ends successfully with the committed PRD. Approving it produces:

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

Capable runtimes may route the authorized contract directly to Nexus. Other runtimes continue sequentially from the same artifact and report that execution honestly rather than claiming a separate agent ran.

Nexus validates the artifact and does not repeat discovery when `discovery_complete: true` has no contradiction or blocking deferred decision. If a concrete blocker exists, Nexus asks for the smallest missing decision instead of restarting the discovery flow.

## Classification

- **Quick:** localized, reversible, established pattern, and low operational risk.
- **Standard:** meaningful behavior change, multiple files, or moderate uncertainty.
- **Complex:** architectural, cross-stack, security-sensitive, migratory, operationally risky, or highly uncertain.

Use only the roles and durable artifacts justified by the classification.

## Planning

Operator refreshes repository facts when needed. Mind defines the implementation and verification approach for standard or complex work. Interrogator reviews complex plans. Fragmenter turns complex work into dependency-aware units with explicit file ownership and interface contracts.

## Worktree Assignment

Every mutating implementation work unit receives its own branch and Git worktree, including sequential jobs. Read-only planning and review do not require worktrees. The approved PRD planning-artifact exception is defined under Requirements Discovery; it applies only to The Fixer's focused PRD commit on the current named branch.

- Worker branch: `cyberpunk/<task-id>/<role>-<work-unit>`
- Worktree: `<worktree-root>/<task-id>/<work-unit>`
- Base: the current approved integration-branch commit

Before creation, verify that a project-local worktree root is ignored. Run project setup and baseline verification inside the new worktree. Record the branch, worktree, base commit, owner, dependencies, and initial status in local run state.

Parallel jobs require non-overlapping file ownership or an explicit integration contract. A runtime without parallel agents executes the same isolated jobs sequentially.

## Implementation

The assigned specialist reads its role, required skills, work packet, relevant memory, and project context. It changes only the allowed scope, runs relevant discovered verification commands, and commits verified work to the worker branch. The result must include `result_commit` and `merge_ready`.

## Review and Repair

Gatekeeper independently inspects requirements, diff, commit, and fresh verification evidence. A rejected finding returns to the same worker worktree. After two unsuccessful repair cycles for the same finding, Nexus requires a new diagnosis. After a third unresolved cycle, Nexus escalates with evidence and the smallest needed decision.

## Integration

Nexus merges only Gatekeeper-approved worker branches into the resolved integration branch, in dependency order. It reruns assembled verification after each relevant merge. Contract-level conflicts are resolved centrally by the owner of the integration contract.

Nexus never merges implicitly into `main`, another protected branch, or a branch outside the resolved task integration branch. Pushes and pull requests require separate authority.

## Delivery

Deliver the verified integration branch and commit, acceptance results, worker branch and merge summary, changed files, commands run, checks not run with reasons, remaining risks, and memory updates.

## Retrospective

Store raw evidence and candidate lessons under `.cyberpunk/runs/<task-id>/`. Promote only validated, generalizable, actionable, non-secret lessons. After confirmed integration, remove completed worktrees and apply the configured worker-branch cleanup policy.

## Work Packet Contract

```yaml
id: TASK-014
objective: Add session renewal
owner: daemon
workflow: standard
integration_branch: cyberpunk/TASK-014-session-renewal
base_commit: abc123
worker_branch: cyberpunk/TASK-014/daemon-session-api
worktree: .worktrees/TASK-014/daemon-session-api
allowed_scope:
  - path/to/auth/**
acceptance:
  - Expired sessions are rejected
verification_categories:
  - unit_test
dependencies: []
memory_refs: []
required_skills:
  - scoped-implementation
```

## Result Contract

```yaml
status: completed
changed_files: []
acceptance_results: []
commands_run: []
checks_not_run: []
remaining_risks: []
candidate_lessons: []
result_commit: def456
merge_ready: true
```

## Run State

Local state at `.cyberpunk/runs/<task-id>/state.yml` is resumable but ignored by Git.

```yaml
integration_branch: cyberpunk/TASK-014-session-renewal
base_commit: abc123
jobs:
  backend:
    agent: daemon
    branch: cyberpunk/TASK-014/daemon-session-api
    worktree: .worktrees/TASK-014/daemon-session-api
    status: verified
    result_commit: def456
    review_status: approved
    merged: false
```

## Authority

Internal worker branches, worktrees, commits, and merges into the resolved task integration branch are allowed. Destructive operations, external messages, pushes, pull requests, deployments, and protected branch merges require explicit authority.

An approved Fixer PRD may be committed on the current named branch only through the Requirements Discovery gates. That authority does not include unrelated files or implementation work.
