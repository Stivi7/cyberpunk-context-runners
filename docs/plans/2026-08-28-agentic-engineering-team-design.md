# Runtime-Neutral Agentic Engineering Team Design

**Date:** 2026-08-28
**Status:** Approved
**Branch:** `feature/agentic-engineering-team`

## Summary

Cyberpunk Context Runners will evolve from a collection of manually invoked role prompts into a runtime-neutral team operating system. A user gives one task to The Nexus. The team inspects the repository, chooses a proportional workflow, implements the change, independently verifies it, delivers evidence, and promotes validated lessons into durable project memory.

Markdown defines agent behavior and handoff contracts. YAML stores project policy and resumable task state. The CLI scaffolds and validates the system without depending on a particular model vendor or agent runtime.

The default delivery target is a verified integration branch plus a concise delivery report. The team may create internal work branches, commits, worktrees, and merges needed to assemble that branch. Pushes, pull requests, deployments, destructive actions, protected-branch merges, and external communication require explicit project policy or user authorization.

## Goals

- Provide a single task entry point that can independently coordinate engineering work.
- Remain portable across Codex, Claude Code, Cursor, and other file-aware agents.
- Scale the workflow to task risk and uncertainty instead of applying full ceremony every time.
- Preserve the existing cyberpunk identities while giving each role a precise engineering contract.
- Support frontend, backend, infrastructure, planning, and independent review specialties.
- Track every mutating assignment through an isolated Git worktree, branch, commit, and merge state.
- Assemble verified agent contributions into a user-selected or Nexus-created integration branch.
- Learn from evidence-backed mistakes without accumulating unreviewed context.
- Discover verification commands and quality policies from each repository.
- Produce transparent delivery evidence and retain unresolved risks.

## Non-goals

- Build a vendor-specific agent invocation engine.
- Require a particular language, framework, package manager, cloud provider, or architecture style.
- Require functional programming, AWS, TypeScript, or a universal coverage percentage.
- Automatically push, open pull requests, deploy, or merge into protected branches by default.
- Store every conversation or raw command output in version control.
- Pretend that roles ran concurrently on runtimes that do not support parallel agents.

## Current Repository Findings

The current repository provides a Bash scaffolding command and static Markdown agent definitions. The documented handoffs are manual, the workflow has no coordinator or resumable state, and there is no memory or review-repair loop. Several defaults are unnecessarily stack-specific, including AWS, TypeScript, functional programming, and a fixed 95% coverage target.

The documentation also disagrees about the number of agents, agent question limits conflict, and the repository has no automated test suite. The CLI's `((file_count++))` expression can terminate template copying under `set -e` on the first copied file. The redesign will retain useful role separation while replacing these brittle assumptions.

## Architecture

The system is a hybrid protocol:

1. Canonical Markdown files define team behavior, roles, workflow, and contracts.
2. YAML configuration records project policy and local task state.
3. The Bash CLI initializes and validates the protocol artifacts.
4. Thin adapters point individual runtimes to the same canonical instructions.
5. Capable runtimes may assign independent roles concurrently; simpler runtimes execute the same protocol sequentially.

The Nexus is the sole user-facing coordinator:

```text
User task
   |
   v
Nexus: normalize, classify, coordinate, track, deliver
   |
   +-- Quick:    specialist -> Gatekeeper
   +-- Standard: Operator -> Mind -> specialist -> Gatekeeper
   +-- Complex:  Operator -> Mind -> Interrogator -> Fragmenter
                  -> specialists/Grid Master -> Gatekeeper -> repair loop
   |
   v
Verified integration branch + delivery report + curated learning
```

The system never depends on agent personas sharing hidden conversational context. Each handoff is an explicit work packet and each result follows a stable contract.

## Team Roles

### The Nexus — Engineering Lead

- Owns task intake, classification, routing, state, escalation, and delivery.
- Reads project policy and relevant memory before assigning work.
- Selects the smallest workflow that safely handles the task.
- Ensures the user receives one coherent outcome rather than separate agent reports.
- Does not implement substantive code when a specialist is available.

### The Operator — Repository Intelligence

- Inspects the actual repository before standards are inferred.
- Maintains the project map, command registry, conventions, boundaries, and detected stack.
- Records observed facts separately from recommendations.
- Refreshes stale context when failures reveal an incorrect assumption.

### The Mind — Architect and Planner

- Produces proportional designs and implementation plans.
- Defines component ownership, interfaces, data flow, rollout, and verification strategy.
- Defines cross-stack contracts before backend and frontend work is parallelized.

### The Interrogator — Adversarial Design Reviewer

- Reviews complex requirements and plans for ambiguity, risk, security, feasibility, and missing acceptance criteria.
- Returns concrete findings to The Mind rather than producing a competing plan.
- Is skipped when task risk does not justify the extra gate.

### The Fragmenter — Work Decomposer

- Converts approved complex plans into dependency-aware work packets.
- Separates tasks by file ownership and integration boundary.
- Marks assignments that are safe to execute concurrently.
- Prevents two parallel agents from owning the same files unless explicitly coordinated.

### The Coder — Shared Engineering Contract

The Coder becomes the common implementation discipline rather than a single generic specialist. It defines scope control, repository conventions, test practices, evidence requirements, and the result handoff used by implementation roles.

### The Daemon — Backend Engineer

- Owns server-side domain logic, APIs, persistence, migrations, authorization, concurrency, performance, and backend integration tests.
- Implements against contracts defined by The Mind for cross-stack changes.
- Applies the repository's actual backend conventions rather than a prescribed architecture style.

### The Neon — Frontend Engineer

- Owns UI architecture, interaction behavior, state management, accessibility, responsive behavior, design-system consistency, browser verification, and perceived performance.
- Implements against shared contracts without inventing backend behavior.
- Uses the project's established frontend stack and visual conventions.

### The Grid Master — Platform and Operations Engineer

- Owns infrastructure, CI/CD, deployment configuration, observability, reliability, security controls, and operational runbooks.
- Uses the project's actual platform and infrastructure tools.
- Never deploys or mutates external environments without authority.

### The Gatekeeper — Independent Reviewer

- Reviews acceptance criteria, repository diff, and observed verification evidence independently.
- Reviews backend, frontend, infrastructure, and assembled user flows as applicable.
- Returns specific findings to the responsible role.
- Cannot approve based solely on an implementer's summary.

## Generated Project Structure

```text
.cyberpunk/
├── config.yml
├── project.md
├── workflow.md
├── memory/
│   ├── decisions.md
│   ├── lessons.md
│   └── patterns.md
└── runs/                     # ignored local execution records
agents/
├── _common-principles.md
├── nexus.md
├── operator.md
├── mind.md
├── interrogator.md
├── fragmenter.md
├── coder.md
├── daemon.md
├── neon.md
├── grid-master.md
└── gatekeeper.md
skills/
├── core/                     # Framework-provided skills
└── project/                  # User-owned skills, never overwritten
specs/
plans/
tasks/
```

Runtime-specific entry files such as `AGENTS.md`, `CLAUDE.md`, or Cursor rules are optional thin adapters. They direct the runtime to the canonical workflow and do not duplicate team policy.

## Skill System

Agents define who owns work. Skills define repeatable methods for performing it. This separation keeps roles stable while allowing the team to gain new capabilities for different stacks, domains, and risk profiles.

Every portable skill lives in its own directory:

```text
skills/
├── core/
│   ├── repository-discovery/SKILL.md
│   ├── task-classification/SKILL.md
│   ├── implementation-planning/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── test-first-development/SKILL.md
│   ├── worktree-isolation/SKILL.md
│   ├── code-review/SKILL.md
│   ├── verification/SKILL.md
│   └── memory-curation/SKILL.md
└── project/
    └── <custom-skill>/SKILL.md
```

Core skills ship with the framework. Project skills are owned by the user and must never be overwritten by initialization or framework updates.

Each `SKILL.md` uses portable YAML frontmatter and Markdown instructions. Its metadata includes an identifier, version, description, triggers, compatible agents, required inputs or tools, possible side effects, expected outputs, and verification requirements. Supporting references, templates, or scripts may live beside it.

Agents first inspect the skill catalog, then fully load only the smallest relevant set. Nexus records required and conditional skills in each work packet:

```yaml
owner: neon
required_skills:
  - scoped-implementation
  - accessibility
  - visual-verification
conditional_skills:
  - systematic-debugging
```

Default role profiles are:

- Nexus: task classification, workflow routing, task-state management, parallel-worktree coordination, delivery, and memory curation.
- Operator: repository discovery, convention extraction, and verification-command discovery.
- Mind: requirements exploration, architecture design, implementation planning, and interface contracts.
- Interrogator: adversarial plan review, risk analysis, and conditional threat modeling.
- Fragmenter: dependency decomposition, ownership boundaries, and parallel-safety analysis.
- Daemon: scoped implementation, test-first development, systematic debugging, and backend change safety.
- Neon: scoped implementation, test-first development, accessibility, and visual or browser verification.
- Grid Master: infrastructure safety, rollback planning, observability, and configuration verification.
- Gatekeeper: requirement review, code review, verification before completion, and lesson validation.

Projects can add skills for scenarios such as framework-specific migrations, UI performance, rollout safety, regulatory review, or mobile accessibility without rewriting agent identities. Custom skills must be explicitly registered and cannot silently shadow core skill identifiers.

The learning system may recommend creating or improving a skill. It never rewrites a skill automatically from a single failure. Skill changes require review, examples, and validation because incorrect procedural guidance can spread mistakes across future tasks.

## Adaptive Workflow

Nexus classifies tasks using risk and uncertainty, not line count alone.

### Quick

Use for localized, reversible work that follows an established pattern and has low operational risk.

1. Nexus creates a concise task brief.
2. Daemon, Neon, or Grid Master implements it.
3. Gatekeeper performs focused verification.
4. Nexus delivers the result.

### Standard

Use for meaningful behavior changes, multiple files, or moderate uncertainty.

1. Operator refreshes relevant project context.
2. Mind creates a concise implementation plan.
3. Nexus assigns the appropriate specialist.
4. Gatekeeper reviews requirements, diff, and verification.
5. The specialist repairs findings when needed.
6. Nexus delivers and evaluates candidate lessons.

### Complex

Use for architectural, cross-stack, security-sensitive, migratory, operationally risky, or highly uncertain work.

1. Operator establishes current repository facts.
2. Mind creates the design and integration contracts.
3. Interrogator pressure-tests the plan.
4. Fragmenter creates dependency-aware assignments.
5. Independent work runs sequentially or in parallel worktrees.
6. Gatekeeper validates specialist outputs and the assembled change.
7. Findings route to the responsible role until resolved or escalated.
8. Nexus delivers and curates validated learning.

## Parallel Worktree Isolation

Git worktrees are part of the generated team's normal implementation lifecycle, not only an optimization for capable runtimes. Every assignment that may modify repository files receives an isolated worktree and branch. Read-only planning and review work may operate without a dedicated worktree.

At task intake, Nexus resolves the integration branch:

- Use the branch named by the user when one is explicitly provided.
- Otherwise create `cyberpunk/<task-id>-<slug>` from the current approved base.
- Never merge into `main`, another protected branch, or an unrelated user branch implicitly.

Each mutating work unit receives:

- Branch: `cyberpunk/<task-id>/<role>-<work-unit>`.
- Worktree: `<configured-root>/<task-id>/<work-unit>`; the default root is `.worktrees/`.
- The approved integration-branch commit as its base.
- Explicit file ownership and integration-contract boundaries.

Project-local worktree roots must be ignored before creation. The project-specific setup and baseline verification run inside each worktree. The assigned agent changes only its permitted scope, runs relevant verification, commits the result on the work branch, and returns the commit SHA with its evidence.

Gatekeeper reviews each worktree and commit before integration. Failed work returns to the same worktree for repair. Nexus merges approved commits into the integration branch in dependency order and reruns assembled verification after each relevant merge. Merge conflicts are resolved centrally by the role owning the integration contract, not independently in multiple worktrees.

Run state records the relationship explicitly:

```yaml
integration_branch: cyberpunk/TASK-014-session-renewal
base_commit: abc123
jobs:
  backend:
    agent: daemon
    branch: cyberpunk/TASK-014/daemon-session-api
    worktree: .worktrees/TASK-014/daemon-session-api
    status: verified
    commit: def456
    merged: false
```

Parallel work is allowed only when Fragmenter identifies independent assignments with non-overlapping ownership or an explicit integration contract. Runtimes without parallel agents execute the same isolated worktree jobs sequentially and record that execution honestly.

After successful integration and final verification, Nexus removes completed worktrees. Worker branches remain until integration is confirmed and are then handled according to project cleanup policy. The integration branch is the delivered artifact; pushing it, opening a pull request, or merging it into a protected branch remains outside default authority.

## Work Packet Contract

Every assignment includes a bounded packet similar to:

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
  - Valid sessions renew safely
verification_categories:
  - unit_test
  - static_analysis
dependencies: []
memory_refs:
  - .cyberpunk/memory/patterns.md#authentication
required_skills:
  - scoped-implementation
  - backend-safety
```

The packet contains objectives and conceptual verification categories, not hardcoded ecosystem commands. Operator resolves categories through the project command registry.

Every agent returns:

- Status: completed, revision-needed, or blocked.
- Files changed or artifacts produced.
- Acceptance criteria addressed.
- Commands actually run and observed results.
- Commands not run and the reason.
- Remaining risks and assumptions.
- Discoveries and candidate lessons.
- Result commit SHA and merge readiness.

## Project Discovery and Verification

Operator records the repository's discovered commands in `.cyberpunk/project.md`:

```yaml
runtime: discovered
commands:
  setup: null
  format_check: null
  lint: null
  static_analysis: null
  unit_test: null
  integration_test: null
  build: null
  security: null
```

The actual values come from repository documentation, package files, build tools, and CI configuration. The categories apply across languages; their commands do not. Missing capabilities remain unavailable and are reported rather than invented.

Quality gates are project policy. The system has no universal coverage percentage, package manager, language, framework, cloud, or programming paradigm requirement. Gatekeeper chooses the relevant discovered commands based on the task's affected areas and risk.

## Hybrid Memory

### Tracked curated memory

- `project.md`: detected stack, commands, repository map, constraints, and boundaries.
- `decisions.md`: accepted decisions with rationale, scope, and revisit conditions.
- `patterns.md`: proven conventions and reusable implementation patterns.
- `lessons.md`: validated failure patterns, root causes, and preventive actions.

### Ignored operational memory

`.cyberpunk/runs/<task-id>/` stores resumable task state, raw evidence, failed attempts, temporary observations, review cycles, and candidate lessons. It is local by default and must be ignored by Git.

A lesson is promoted only when it is evidence-backed, generalizable, actionable, non-duplicative, free of secrets, and confirmed by Gatekeeper or repeated independently. A lesson records its symptom, root cause, preventive action, applicability, evidence, and status. Obsolete entries are marked superseded rather than left in contradiction.

Nexus retrieves memory by affected path, technology, task type, and tags. Agents receive only relevant entries, preventing memory growth from consuming the task context.

## Failure Recovery and Escalation

Failures route according to their cause:

- Implementation defect -> responsible specialist.
- Design or contract defect -> Mind, then Interrogator for complex revisions.
- Incorrect task decomposition -> Fragmenter.
- Stale repository understanding -> Operator.
- Unavailable tool -> record evidence and use safe alternatives where possible.
- Pre-existing failure -> distinguish from the change and report it.
- Missing authority or destructive action -> request user approval.

After two unsuccessful repairs for the same finding, Nexus requires a new root-cause diagnosis and plan. After a third unresolved cycle, Nexus escalates with evidence, attempted approaches, and the smallest decision needed from the user. Repeating the same command or patch without a changed hypothesis is prohibited.

## Authority and Delivery

Default authority allows repository inspection, project-relevant verification, creation of the task integration branch, isolated worker worktrees and branches, internal commits, and merges of approved worker branches into the task integration branch. These Git operations are required for task tracking and assembly.

Default authority does not allow deployment, destructive operations, external messages, pushes, pull requests, or merges into `main`, protected branches, or branches outside the resolved task integration branch unless the user or project policy enables them.

The default delivery report contains:

- Outcome and acceptance status.
- Delivered integration branch and commit.
- Worker branch, worktree, commit, and merge status summary.
- Changed files.
- Verification commands and observed results.
- Relevant checks not run and why.
- Remaining risks or follow-up work.
- Curated memory entries added or updated.

## CLI Responsibilities

The CLI remains small and deterministic. It will:

- Initialize the canonical team structure.
- Preserve existing project files unless forced.
- Add required ignore rules safely.
- Validate required files and agent contracts.
- Check configuration and local task-state structure.
- Validate integration-branch, worker-branch, worktree, commit, and merge-state policy.
- Report team and project status.
- Support dry-run and idempotent initialization.

The CLI will not call a particular model or claim that an agent ran. Runtime adapters and the active AI environment perform orchestration according to the canonical protocol.

## Testing Strategy

The repository will gain automated coverage for:

- Bash syntax and CLI behavior.
- Initialization in temporary directories.
- Dry-run, force, conflict, and idempotency behavior.
- Template mappings and the existing template-copying regression.
- Required sections and contracts in every agent definition.
- Runtime adapters pointing to canonical instructions.
- Skill metadata, required sections, registry resolution, and core identifier uniqueness.
- Project-owned skills remaining untouched during initialization and forced updates.
- Integration-branch resolution, isolated worker-job tracking, and protected-branch restrictions.
- Local run data being ignored while curated memory remains trackable.
- Cross-language fixtures showing project-specific command registries.
- Absence of universal Node, AWS, TypeScript, or fixed coverage assumptions.

Verification must use tools available in the repository and report unavailable optional checks honestly.

## Migration

The existing agent names remain recognizable. Nexus changes from a PRP author into the team lead; requirements work becomes part of its intake responsibility. Coder becomes the common implementation contract, and Daemon and Neon become backend and frontend specialists. Existing PRP content migrates toward `specs/`, while plans and tasks remain compatible concepts.

The README and Cursor adapter will be rewritten around the single-task workflow. Existing direct role invocation may remain as an advanced compatibility path, but the recommended interface will be a task addressed to Nexus.

## Success Criteria

- A new project can initialize the team without stack-specific assumptions.
- One user task can progress through an appropriate workflow and produce a consistent delivery report.
- Quick tasks avoid unnecessary planning artifacts.
- Complex tasks produce explicit contracts and dependency-aware assignments.
- Every mutating agent job is traceable through run state, an isolated worktree, a worker branch, a reviewed commit, and integration status.
- Daemon and Neon can work independently in isolated worktrees and merge safely into the resolved integration branch.
- Agents load default and scenario-specific skills without duplicating role definitions.
- User-owned project skills can be added without modifying or shadowing core skills.
- Gatekeeper bases approval on observed evidence.
- Repeated failures change the hypothesis or escalate instead of looping.
- Validated lessons influence later work while raw run logs remain local.
- The CLI is tested, idempotent, and does not exit during the first template copy.
