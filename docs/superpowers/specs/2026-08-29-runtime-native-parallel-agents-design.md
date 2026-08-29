# Runtime-Native Parallel Agents Design

**Date:** 2026-08-29
**Status:** Approved
**Branch:** `implement-todo`

## Summary

Cyberpunk Context Runners will make safe parallel agent execution the default on Codex, Claude Code, and Cursor. The canonical Markdown and YAML protocol will remain runtime-neutral, while `cyberpunk init` and `cyberpunk sync` will install thin, native agent and skill registrations for every selected runtime.

Nexus remains the parent coordinator. It will dispatch real native subagents for non-user-facing roles, execute dependency-ready work concurrently up to a limit of three subagents, require fresh-context Gatekeeper review, and record the execution mode that actually occurred. A runtime that cannot spawn agents will fall back to sequential execution with an explicit reason instead of silently acting out multiple roles in one context.

This change also adds portable, profile-based model routing. Spawned agents receive a runtime-specific preferred model when available and fall back to the parent model through `inherit` when the preferred model cannot be used.

## Problem Statement

The current protocol describes safe concurrency but does not reliably trigger it:

- The generated Codex `AGENTS.md` loads the canonical workflow but never requests subagent delegation.
- The Claude adapter mentions capable subagents, while the Codex and Cursor adapters do not provide an equivalent obligation.
- Fragmenter marks jobs as parallel-safe, but no dispatch contract requires Nexus to convert those jobs into native agent invocations.
- Gatekeeper is logically independent, but the workflow does not require a fresh agent context.
- Worktrees isolate file changes but do not start agents.
- The CLI intentionally scaffolds protocol files and does not invoke an agent runtime.

As a result, a runtime may reasonably perform Nexus, Operator, Mind, a specialist, and Gatekeeper as sequential personas inside one session. This preserves the workflow order but pays coordination overhead without receiving real parallelism or fresh-context review.

## Verified Runtime Capabilities

All three supported runtimes provide the primitives needed by this design:

- Codex supports project-scoped custom subagents, parallel delegation, model and reasoning configuration, and project instructions that request delegation.
- Claude Code supports project subagents, parallel dispatch, resumable background work, model selection, and worktree isolation.
- Cursor supports project subagents, automatic and explicit delegation, parallel Task calls, background execution, model configuration, and isolated project copies.
- All three runtimes discover project-scoped Agent Skills from native filesystem paths.

The design uses these native mechanisms without turning the Cyberpunk CLI into a vendor process supervisor.

## Goals

- Make native parallel delegation the default when the active runtime supports it.
- Support Codex, Claude Code, and Cursor from project setup.
- Allow one project to enable one, several, or all supported runtimes.
- Limit concurrent subagents to three, excluding the parent Nexus session.
- Preserve dependency ordering and prevent unsafe parallel writes.
- Run non-user-facing roles as actual native subagents rather than sequential personas whenever possible.
- Require Gatekeeper to review from fresh context before integration.
- Register Cyberpunk agents and skills in each selected runtime's native discovery paths.
- Assign model profiles to every role and resolve them per runtime with `inherit` fallback.
- Preserve existing project instructions, runtime settings, and project-owned skills.
- Record actual concurrency, model fallback, failures, and sequential fallback honestly.
- Keep the CLI dependency-free, deterministic, and free of paid model calls.

## Non-Goals

- Build a process-level orchestration engine that launches vendor CLIs or SDKs.
- Implement cross-repository coordination; that remains a separate architectural project.
- Require cloud agents, vendor-hosted environments, or marketplace publishing.
- Guarantee parallelism for coupled tasks that cannot be given safe ownership boundaries.
- Override organization policies, user permission settings, or explicitly disabled native agent features.
- Force one portable model identifier on runtimes that do not expose that model.
- Allow nested subagents to coordinate the team; Nexus is the sole dispatcher.

## Selected Approach

Use runtime-native adapters over one canonical orchestration protocol.

The rejected alternatives are:

1. **Stronger prose only.** Updating `AGENTS.md`, `CLAUDE.md`, and Cursor rules without native definitions would leave model routing, fresh-context review, and actual dispatch dependent on informal prompt interpretation.
2. **A Cyberpunk agent runtime.** Launching and supervising Codex, Claude, or Cursor processes directly would introduce authentication, approvals, streaming, retries, vendor SDKs, and process management. It would conflict with the project's small scaffolding-CLI boundary.

## Architecture

The system has three layers.

### 1. Canonical protocol

The existing portable files remain the source of truth:

- `.cyberpunk/workflow.md` defines lifecycle and orchestration behavior.
- `.cyberpunk/config.yml` defines runtime, execution, model, Git, delivery, memory, and skill policy.
- `agents/*.md` defines role responsibilities and handoff contracts.
- `skills/core/*/SKILL.md` defines framework procedures.
- Enabled `skills/project/*/SKILL.md` defines project-owned procedures.
- `.cyberpunk/runs/<task-id>/state.yml` records actual execution.

No runtime-native agent or skill file may become a second source of behavioral truth.

### 2. Runtime-native registrations

Initialization generates the native files needed for selected runtimes:

```text
.agents/
└── skills/<skill>/SKILL.md            # Codex skill registrations
.codex/
└── agents/<role>.toml                 # Codex native agents
.claude/
├── agents/<role>.md                   # Claude native agents
└── skills/<skill>/SKILL.md            # Claude skill registrations
.cursor/
├── agents/<role>.md                   # Cursor native agents
├── rules/cyberpunk.mdc                # Cursor entry adapter
└── skills/<skill>/SKILL.md            # Cursor skill registrations
AGENTS.md                               # Codex managed entry block
CLAUDE.md                               # Claude managed entry block
```

Native agent definitions contain only runtime metadata, the resolved preferred model, role purpose, and instructions to load the canonical workflow, common principles, role contract, assigned work packet, and required skills.

Native skill registrations contain valid runtime frontmatter with the canonical name and description. Their body instructs the runtime to read and follow the canonical skill file completely and to resolve scripts, references, templates, and assets relative to the canonical skill directory.

### 3. Deterministic CLI

The Bash CLI installs, synchronizes, validates, and reports these artifacts. It does not call models, launch vendor processes, or claim an agent ran.

## Setup Interface

Fresh initialization supports one or several repeatable runtime flags:

```bash
cyberpunk init
cyberpunk init --runtime codex
cyberpunk init --runtime codex --runtime claude
cyberpunk init --runtime all
```

Rules:

- Plain `cyberpunk init` enables Codex, Claude, and Cursor.
- `--runtime` is repeatable.
- `all` normalizes to all supported runtimes.
- Re-running initialization adds selected runtimes and never silently removes an enabled runtime.
- An unknown runtime fails validation before any project file is written.
- `cyberpunk sync` regenerates runtime-native registrations from canonical configuration and content.
- `cyberpunk validate` checks canonical policy and generated adapter consistency.
- `cyberpunk status` reports configured runtimes, registered agents and skills, concurrency policy, model profiles, generated-asset drift, and local run state. It does not claim live runtime capability that it cannot observe.

## Configuration Contract

The configuration version will be incremented. Existing policy remains and gains the following sections:

```yaml
version: 2

runtimes:
  enabled: [codex, claude, cursor]

execution:
  parallelism: auto
  max_concurrent_agents: 3
  unavailable_runtime_fallback: sequential

models:
  fallback: inherit
  profiles:
    deep:
      codex: "gpt-5.6-sol"
      claude: "opus"
      cursor: "gpt-5.6-sol"
    balanced:
      codex: "gpt-5.6-terra"
      claude: "sonnet"
      cursor: "composer-2.5[]"
    fast:
      codex: "gpt-5.6-luna"
      claude: "haiku"
      cursor: "composer-2.5"
  roles:
    nexus: deep
    fixer: deep
    operator: fast
    mind: deep
    interrogator: deep
    fragmenter: balanced
    coder: balanced
    daemon: balanced
    neon: balanced
    grid-master: balanced
    gatekeeper: deep
  overrides: {}
```

`models.overrides` may provide a role-specific profile or runtime model without rewriting the default profile table.

The configured maximum of three counts all active subagents, including read-only planners, workers, and reviewers. Nexus is the parent and does not consume one of these slots. A runtime's lower native limit wins when applicable.

## Model Resolution

For a spawned role, Nexus resolves the model in this order:

1. A role-and-runtime override.
2. The role's assigned semantic profile mapped to the active runtime.
3. `inherit` from the parent session.

If the preferred model is rejected as unavailable, disallowed, or unsupported, Nexus retries the role once with `inherit` and records the preferred model, failure reason, and effective fallback. The retry uses the same custom role with an explicit inherited-model override when the runtime permits it. Otherwise Nexus spawns the runtime's built-in default worker with `inherit` and supplies the complete canonical role contract and work packet. The CLI does not generate duplicate fallback-agent definitions.

Nexus remains the parent coordinator and therefore uses the model selected by the user or active runtime. Its `deep` profile is a recommendation and may be used as a project default where a runtime supports that safely. Interactive Fixer discovery also remains in the parent conversation so the role can ask the user one focused question at a time. If Fixer is spawned for non-interactive analysis, its `deep` profile applies normally.

## Skill Registration

Canonical skill bodies remain under `skills/core/` and `skills/project/`. The CLI generates real, discoverable native registration wrappers rather than copying the complete bodies.

For a canonical skill named `task-decomposition`, the native wrapper follows this shape:

```markdown
---
name: task-decomposition
description: Split an approved complex plan into dependency-aware jobs with safe ownership boundaries.
---

Read `../../../skills/core/task-decomposition/SKILL.md` completely and follow it.
Resolve every referenced script, template, reference, or asset relative to that
canonical skill directory.
```

Core skills are always registered. Project skills are registered only when explicitly enabled by `.cyberpunk/config.yml`. A duplicate native or canonical skill name is an error because ambiguous discovery could select the wrong procedure.

The wrapper approach is preferred over symlinks for cross-platform behavior and over full copies to prevent procedural drift.

## Agent Dispatch Contract

Nexus is the only component allowed to spawn, resume, steer, interrupt, or replace subagents. Subagents never create sibling or nested team agents. This keeps the design compatible with runtimes that restrict nested delegation.

### Workflow stages

1. Nexus reads the active runtime adapter and canonical configuration.
2. Nexus classifies the task and selects the smallest required workflow.
3. Required non-user-facing roles run as native subagents with fresh context.
4. Operator findings feed Mind; an approved plan feeds Interrogator and Fragmenter when required. Dependency-bound stages remain sequential.
5. Fragmenter produces bounded work packets with dependencies, exclusive mutable scope or an explicit integration contract, required skills, and a `parallel_safe` decision.
6. Nexus places dependency-ready packets into a ready queue.
7. Nexus dispatches parallel-safe packets until three subagent slots are occupied.
8. Additional ready packets remain queued; a full queue is not a reason for sequential fallback.
9. Each mutating worker operates in its recorded branch and worktree, verifies its scope, commits the result, and returns a result contract.
10. Each completed worker receives a fresh Gatekeeper review. Independent reviews may run concurrently within the same global three-agent limit.
11. Rejected findings return to the original worker context when resumption is supported. Otherwise Nexus starts a replacement agent with the full work packet, result evidence, and Gatekeeper findings.
12. Nexus merges only approved result commits in dependency order.
13. A fresh Gatekeeper performs assembled-change review before final delivery.

Parallelism is based on independent work packets, not on making every conceptual role run at the same time. Roles with data dependencies still run sequentially as real, fresh agents.

## Worktree Isolation

Every mutating worker retains the existing Cyberpunk branch and worktree contract. The dispatch packet includes the absolute or repository-relative worktree path, worker branch, base commit, allowed paths, and dependencies.

The runtime adapter may use native isolation only when it can satisfy the recorded branch, base, path ownership, and integration contract. Otherwise Nexus creates the Cyberpunk worktree first and requires the subagent to perform all reads, writes, and verification within that path.

Two concurrent workers may not own the same mutable path unless an explicit integration owner and contract define how their results are combined. Worktree isolation does not make overlapping ownership safe by itself.

## Run-State Additions

Run state records what occurred rather than what the plan intended:

```yaml
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
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
    worker_branch: cyberpunk/TASK-014/neon-frontend
    worktree: .worktrees/TASK-014/frontend
    execution_status: completed
    review_agent_instance: codex-agent-c91b
    review_status: approved
    result_commit: def456
    merged: false
fallback:
  used: false
  reason: null
```

Runtime-provided identifiers and timing information are recorded when exposed. Their absence must not be fabricated.

## Sequential Fallback

Sequential fallback is allowed only when:

- The active runtime does not expose native subagent tools.
- Workspace or organization policy disables delegation.
- The user has disabled multi-agent behavior.
- No work packets are safe to execute concurrently.
- A runtime-specific failure prevents spawning and retry cannot recover.

The first three cases execute the workflow in the parent session when safe. The last two may still use real subagents sequentially. Every fallback records its category, observed evidence, affected jobs, and delivery impact.

The delivery report must distinguish:

- Native agents that ran concurrently.
- Native agents that ran sequentially because of dependencies.
- Roles performed in the parent context because native delegation was unavailable.

## Failure Handling

- A full three-agent queue waits for capacity.
- One failed independent worker does not cancel unrelated jobs.
- A failed or blocked worker keeps its worktree and evidence and is never integrated.
- A crashed worker is resumed when the runtime supports it; otherwise it is replaced from a complete packet.
- Model unavailability triggers one retry with `inherit`.
- Gatekeeper rejection returns to the responsible worker and never becomes implicit approval.
- After the existing repair threshold, Nexus requires a new root-cause diagnosis.
- Merge conflicts route to the named integration-contract owner.
- Missing approvals or prohibited actions remain blocked under the parent runtime's permission policy.

## Generated Asset Ownership

Runtime-native files generated by Cyberpunk contain a generated-file notice. A tracked `.cyberpunk/generated.yml` manifest records their source, runtime, role or skill identifier, and expected hash.

`cyberpunk sync`:

- Regenerates unchanged Cyberpunk-owned runtime assets.
- Adds registrations for newly enabled runtimes and project skills.
- Reports locally modified generated assets instead of overwriting them.
- Requires `--force` to replace modified generated assets.
- Never replaces canonical project-owned skills under `skills/project/`.

## Coexistence With Existing Runtime Files

Cyberpunk must preserve existing tool instructions and settings.

### Root instructions

`AGENTS.md` and `CLAUDE.md` receive a bounded managed block:

```markdown
<!-- cyberpunk:start -->
Read `.cyberpunk/workflow.md`, act as Nexus, and dispatch independent work
through the active runtime's native agents according to project policy.
<!-- cyberpunk:end -->
```

Synchronization replaces only the content between these markers. Content outside the block remains user-owned. Cursor uses a dedicated `.cursor/rules/cyberpunk.mdc` file rather than modifying unrelated Cursor rules.

### Runtime configuration

`.codex/config.toml` remains user-owned. If the file is absent, initialization creates a minimal `[agents]` section with `max_concurrent_threads_per_session = 3`. If the file exists without that section, initialization appends it. If `[agents]` exists without the concurrency key, initialization adds the key inside that section. Existing values are preserved. Nexus still enforces the canonical maximum of three even if a runtime permits more. If multi-agent support is explicitly disabled, Cyberpunk honors that preference and records sequential fallback.

Claude and Cursor use project-scoped agent and skill definitions without requiring changes to global settings.

### Collisions

If an existing native agent or skill uses a Cyberpunk identifier but is not listed as a Cyberpunk-generated asset, initialization and synchronization report a collision. They do not overwrite it automatically.

## Legacy Migration

`cyberpunk sync` upgrades version-1 projects by adding missing runtime, execution, and model sections with the approved defaults. It preserves existing delivery, workflow, Git, memory, skill policy, project instructions, and project-owned skill content.

A legacy project with no runtime selection migrates to all three runtimes. Migration is idempotent and must not duplicate managed blocks, native registrations, config sections, or ignore entries.

## Validation

Validation fails or warns with specific evidence for:

- Unknown or duplicate runtime identifiers.
- A concurrency limit greater than three or lower than one.
- Missing `inherit` model fallback.
- Roles without model profiles.
- Runtime model profiles without mappings.
- Missing native agent definitions for an enabled runtime.
- Missing native skill registrations for core or enabled project skills.
- Duplicate role or skill identifiers.
- Native registrations pointing to missing canonical files.
- Stale hashes or locally modified generated assets.
- Duplicate or malformed managed instruction blocks.
- Unsafe concurrent ownership in a recorded run.
- A review marked approved without a fresh Gatekeeper agent when native delegation was available.
- A delivery report claiming parallel execution without native agent evidence.

## Testing Strategy

The automated Bash suite will not invoke paid models.

### CLI tests

- Plain initialization enables all runtimes.
- Single, repeated, and `all` runtime flags normalize correctly.
- Invalid runtime input fails before writes.
- Re-running initialization adds runtimes without removing prior selections.
- `sync`, migration, and managed-block updates are idempotent.
- `--force` replaces only framework-generated assets.
- User project skills and unrelated runtime configuration are preserved.

### Contract tests

- Every canonical role has a valid native definition in each enabled runtime fixture.
- Every core and enabled project skill has a valid native registration.
- Native files point to canonical workflow, role, and skill paths.
- Nexus owns dispatch and subagents do not own nested orchestration.
- Fragmenter produces dependency and parallel-safety fields.
- Gatekeeper requires fresh context and observed verification.
- The workflow requires honest concurrency and fallback reporting.
- Role profile and runtime model resolution always terminate in `inherit`.

### Integration tests

Temporary repositories cover fresh initialization, one runtime, multiple runtimes, all runtimes, legacy migration, existing instruction files, existing Codex configuration, identifier collisions, locally modified generated files, enabled project skills, and force refresh.

### Optional live smoke matrix

For Codex, Claude Code, and Cursor separately:

1. Initialize a fixture for the runtime.
2. Give Nexus four independent work packets.
3. Observe three native subagents start while the fourth waits.
4. Confirm each mutating worker uses an isolated branch and worktree.
5. Confirm Gatekeeper uses a fresh agent context.
6. Disable or block native agents and confirm sequential fallback is recorded.
7. Configure an unavailable preferred model and confirm retry with `inherit`.

Live smoke tests are documented and opt-in because they consume model usage and depend on account-specific capabilities.

## Documentation Changes

The README and generated-template documentation will explain:

- Runtime selection commands and the default of all runtimes.
- Which native agent and skill paths are generated.
- Automatic safe parallelism and the three-agent limit.
- The difference between worktree isolation and agent concurrency.
- Model profiles, overrides, and `inherit` fallback.
- `sync`, validation, status, collision, and migration behavior.
- How to inspect subagent activity in each runtime.
- Why some dependency-bound stages remain sequential.

## Acceptance Criteria

- `cyberpunk init` enables Codex, Claude, and Cursor by default.
- Projects may enable any non-empty subset of supported runtimes.
- Every enabled runtime discovers all Cyberpunk roles as native agents.
- Every enabled runtime discovers all core and enabled project skills as native skills.
- Nexus automatically dispatches dependency-ready, parallel-safe work to native subagents.
- No more than three subagents run concurrently.
- Non-user-facing roles use fresh native agent contexts when capability is available.
- Gatekeeper review uses a fresh agent before integration.
- Mutating parallel workers use isolated, recorded branches and worktrees.
- Every role has a semantic model profile and runtime-specific mapping.
- Unavailable preferred models retry with `inherit` and record the fallback.
- Existing project instructions, settings, and project-owned skills are preserved.
- Sequential fallback includes an explicit observed reason.
- Delivery never claims agents, concurrency, model use, tests, or approvals that did not occur.
- Automated tests pass without paid model calls.

## Implementation Scope

Implementation is expected to update:

- The `cyberpunk` CLI and version.
- Canonical workflow and configuration templates.
- Nexus, Fragmenter, Gatekeeper, common principles, and relevant role contracts.
- Runtime-native agent templates for Codex, Claude, and Cursor.
- Runtime-native skill-registration generation.
- Generated-asset manifest handling.
- CLI, protocol, agent, skill, integration, smoke, and documentation tests.
- README and generated-template documentation.
- `todo.md`, marking the per-agent model-routing item complete only after verified implementation.

Marketplace plugin packaging and cross-repository execution remain separate follow-up projects.

## Sources

- OpenAI, “Subagents”: https://learn.chatgpt.com/docs/agent-configuration/subagents
- OpenAI, “Build skills”: https://learn.chatgpt.com/docs/build-skills
- Anthropic, “Run agents in parallel”: https://code.claude.com/docs/en/agents
- Anthropic, “Create custom subagents”: https://code.claude.com/docs/en/sub-agents
- Anthropic, “Extend Claude with skills”: https://code.claude.com/docs/en/slash-commands
- Cursor, “Subagents”: https://prod.cursor.com/docs/subagents
- Cursor, “Agent Skills”: https://prod.cursor.com/docs/skills
