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

## Native Dispatch

Nexus is the only component allowed to spawn, resume, steer, interrupt, or replace Cyberpunk subagents. Every other role performs its assigned work only; it never creates sibling or nested team agents. Fresh native contexts receive the complete work packet, required skills, result evidence, and findings because conversational context is not inherited.

Nexus resolves the active runtime and configured `max_concurrent_agents` before dispatch. It honors an observable lower runtime cap and `agents.enabled = false`. The global maximum is three active subagents, including planners, workers, and reviewers but excluding Nexus.

Dependency-bound planning stages run sequentially as fresh native roles. Nexus places only dependency-ready packets into a ready queue after their dependencies are approved and integrated where required. It dispatches only `parallel_safe: true` packets while fewer than three active subagents occupy the global capacity. A full queue leaves excess ready packets queued; capacity waiting is not a fallback.

When a worker fails, Nexus continues unrelated jobs, retains the failed worker's worktree and evidence, and never integrates that result. Every completed result receives a fresh Gatekeeper review; independent reviews share the same global capacity. On rejection, Nexus resumes the original worker when supported, otherwise it replaces the worker with the complete packet, result evidence, and findings. Nexus merges approved results in dependency order and starts a different fresh Gatekeeper instance for assembled-change review before delivery.

## Worktree Assignment

Every mutating implementation work unit receives its own branch and Git worktree, including sequential jobs. Read-only planning and review do not require worktrees. The approved PRD planning-artifact exception is defined under Requirements Discovery; it applies only to The Fixer's focused PRD commit on the current named branch.

- Worker branch: `cyberpunk/<task-id>/<role>-<work-unit>`
- Worktree: `<worktree-root>/<task-id>/<work-unit>`
- Base: the current approved integration-branch commit

Before creation, verify that a project-local worktree root is ignored. Run project setup and baseline verification inside the new worktree. Record the branch, worktree, base commit, owner, dependencies, and initial status in local run state.

Parallel jobs require non-overlapping file ownership or a named integration owner with an explicit integration contract. `parallel_safe: true` is valid only when dependencies are satisfied and mutable paths do not overlap; worktree isolation does not make overlapping ownership safe. A runtime without native delegation executes the same isolated jobs sequentially and records why.

## Implementation

The assigned specialist reads its role, required skills, work packet, relevant memory, and project context. It changes only the allowed scope, runs relevant discovered verification commands, and commits verified work to the worker branch. It never spawns or delegates Cyberpunk team agents. The result must include `result_commit` and `merge_ready`.

## Review and Repair

Gatekeeper independently inspects requirements, diff, commit, and fresh verification evidence in a fresh context. Each review records the runtime-provided reviewer identity when exposed; otherwise it records `null` and never invents an identity. When native delegation is available, approval without fresh context is invalid. A rejected finding returns to the same worker worktree. After two unsuccessful repair cycles for the same finding, Nexus requires a new diagnosis. After a third unresolved cycle, Nexus escalates with evidence and the smallest needed decision.

## Integration

Nexus merges only Gatekeeper-approved worker branches into the resolved integration branch, in dependency order. It reruns assembled verification after each relevant merge. A different fresh Gatekeeper performs assembled-change review after the approved results are integrated. Contract-level conflicts are resolved centrally by the named owner of the integration contract.

Nexus never merges implicitly into `main`, another protected branch, or a branch outside the resolved task integration branch. Pushes and pull requests require separate authority.

## Delivery

Deliver the verified integration branch and commit, acceptance results, worker branch and merge summary, changed files, commands run, checks not run with reasons, remaining risks, and memory updates. Separately list native agents that ran concurrently, native agents that ran sequentially because of dependencies, roles performed in the parent context because native delegation was unavailable, and jobs that waited only for queue capacity. Report preferred/effective models and fallbacks actually observed, plus tests, result commits, fresh reviews, and merges actually observed. Never claim native agents, concurrency, model use, tests, approvals, or merges from configuration or planned execution alone; native agent evidence is required.

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
parallel_safe: true
dependencies: []
integration_owner: null
integration_contract: null
required_skills: []
model_profile: balanced
acceptance:
  - Expired sessions are rejected
verification_categories:
  - unit_test
memory_refs: []
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
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
integration_branch: cyberpunk/TASK-014-session-renewal
base_commit: abc123
jobs:
  frontend:
    role: neon
    native_agent: neon
    agent_instance: codex-agent-7f3a
    model_preferred: gpt-5.6-terra
    model_effective: gpt-5.6-terra
    model_fallback_reason: null
    parallel_safe: true
    dependencies: []
    allowed_scope: [src/frontend/**]
    integration_owner: null
    integration_contract: null
    worker_branch: cyberpunk/TASK-014/neon-frontend
    worktree: .worktrees/TASK-014/frontend
    execution_status: completed
    review_agent_instance: codex-agent-c91b
    review_context: fresh
    verification_observed: []
    verification_skipped_reason: null
    review_status: approved
    result_commit: def456
    merged: false
assembled_review:
  integrated_commit: fed789
  review_agent_instance: codex-agent-d41e
  review_context: fresh
  verification_observed: []
  verification_skipped_reason: manual environment unavailable
  review_status: approved
fallback:
  used: false
  category: null
  reason: null
  observed_evidence: []
  affected_jobs: []
  delivery_impact: null
```

Run state records observed execution rather than the plan. `native_agent`, `agent_instance`, and `review_agent_instance` contain runtime-provided values when exposed and `null` when not exposed; identities are never invented. Every approved per-result review requires `review_context: fresh`, `result_commit`, and either non-empty `verification_observed` or an explicit `verification_skipped_reason`. Every run has one `assembled_review` tied to `integrated_commit`; an approved assembled review follows the same fresh-context and verification-evidence requirements. These names are compatible with local recorded-state validation.

## Sequential Fallback

Sequential fallback is allowed only in these five categories:

1. `native_tools_unavailable` — the active runtime exposes no native subagent tools.
2. `delegation_disabled_by_policy` — workspace or organization policy disables delegation.
3. `delegation_disabled_by_user` — the user disabled multi-agent behavior.
4. `no_parallel_safe_packets` — no dependency-ready packet is safe to run concurrently.
5. `runtime_spawn_failure` — a runtime-specific spawn failure remains after the allowed retry.

The first three categories may perform safe roles in the parent context; the last two may use real subagents sequentially. Every fallback records its category, reason, observed evidence, affected jobs, and delivery impact. A full queue is capacity waiting, never fallback.

For model rejection, Nexus retries once with `inherit`, records the preferred model, observed failure reason, and effective model. It prefers the same custom role with an explicit inherited model; if unavailable, it uses the runtime's built-in default worker with the complete canonical role and packet. There are no duplicate fallback agent files.

## Authority

Internal worker branches, worktrees, commits, and merges into the resolved task integration branch are allowed. Destructive operations, external messages, pushes, pull requests, deployments, and protected branch merges require explicit authority.

An approved Fixer PRD may be committed on the current named branch only through the Requirements Discovery gates. That authority does not include unrelated files or implementation work.
