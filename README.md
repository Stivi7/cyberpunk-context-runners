# Cyberpunk Context Runners

Give The Nexus a task. The team inspects the repository, plans proportionally, implements in isolated worktrees, verifies independently, learns from evidence, and returns a verified integration branch.

Cyberpunk Context Runners is a runtime-neutral engineering-team protocol. Its canonical behavior is plain Markdown and YAML, so file-aware coding agents can execute it sequentially or concurrently without depending on one model vendor. The dependency-free Bash CLI installs and validates the protocol; it does not pretend to run agents itself.

## Quick Start

Download or clone this repository, make the `cyberpunk` script available on your path, then initialize it inside a project. Plain `init` enables Codex, Claude Code, and Cursor registrations together:

```bash
cd /path/to/your/project
cyberpunk init
cyberpunk validate
cyberpunk status
```

To register only the runtimes used by a project, choose one or more explicit runtimes. Re-running `init` adds selected runtimes; it does not remove existing registrations.

```bash
cyberpunk init --runtime codex
cyberpunk init --runtime claude
cyberpunk init --runtime cursor
cyberpunk init --runtime codex --runtime claude
cyberpunk sync
```

Start Codex, Claude Code, or Cursor normally after initialization, then ask Nexus for work. The Bash CLI installs and checks registrations; it never starts model processes or claims a provider session is available.

Then give the task to your coding agent through The Nexus:

```text
Act as The Nexus. Add account recovery with expiring, single-use tokens.
Deliver the verified integration branch; do not push or open a pull request.
```

For a new product, feature, or architectural idea whose requirements still need discovery, invoke The Fixer directly:

```text
Act as The Fixer. Help me define account recovery before implementation planning.
```

Nexus also routes materially incomplete product work to The Fixer. The Fixer uses `requirements-discovery`, asks one focused question at a time, and writes an approved PRD to `specs/YYYY-MM-DD-<topic>-prd.md`. After the user reviews the file, The Fixer commits only that PRD on the current named branch and asks whether to hand it to Nexus.

Keep interactive Fixer discovery in the parent conversation so questions and approvals remain with the user. Keep non-interactive Fixer analysis eligible for a native subagent that returns its findings before dialogue continues.

The runtime adapter loads `.cyberpunk/workflow.md`, then Nexus selects only the roles and skills required for the task.

## Adaptive Workflow

Nexus classifies by risk and uncertainty:

Product discovery precedes engineering classification when a new product, feature, or architectural request still lacks material requirements. Routine fixes, sufficiently specified work, and approved PRDs continue directly through Nexus.

- **quick:** a localized, reversible change following an established pattern
- **standard:** meaningful behavior spanning several files or moderate uncertainty
- **complex:** architectural, cross-stack, security-sensitive, migratory, operationally risky, or highly uncertain work

Quick work goes directly to the relevant specialist and Gatekeeper. Standard work adds repository discovery and a concise plan. Complex work adds adversarial plan review, dependency decomposition, explicit integration contracts, and multiple isolated worker jobs.

## The Engineering Team

The system contains 11 specialized roles:

- **The Nexus:** engineering lead, task router, Git job coordinator, and delivery owner
- **The Fixer:** product requirements broker for collaborative discovery, approved PRD commits, and explicit Nexus handoff
- **The Operator:** repository intelligence and verification-command discovery
- **The Mind:** architecture, interfaces, and proportional implementation planning
- **The Interrogator:** adversarial review for complex plans
- **The Fragmenter:** dependency-aware work decomposition and ownership boundaries
- **The Coder:** shared implementation, test, debugging, and evidence contract
- **The Daemon:** backend engineer for services, APIs, persistence, and domain logic
- **The Neon:** frontend engineer for interfaces, accessibility, interactions, and visual quality
- **The Grid Master:** platform, automation, observability, and operational engineering
- **The Gatekeeper:** independent requirement, diff, risk, and verification reviewer

Direct role invocation remains available for focused work, but Nexus is the recommended entry point because it owns the complete lifecycle.

## Native Dispatch, Models, and Worktrees

Nexus is the parent and sole dispatcher. Its effective limit is the minimum of the configured maximum, the observed runtime cap, and three; Nexus is excluded. With `parallelism: sequential`, that limit is one. Only dependency-ready, ownership-safe packets may run concurrently: dependency-bound roles remain sequential, and a full queue waits for capacity rather than being described as fallback.

Every mutating packet still receives a recorded branch and worktree. Worktree isolation does not start agents or create concurrency; it only separates approved changes. Gatekeeper uses fresh context before integration and again for the assembled change when native delegation is available. A parent-session fallback records `review_agent_instance: null` and `review_context: parent` rather than claiming a fresh agent.

The configured model profiles map deep, balanced, and fast roles to each runtime. A runtime may reject a preferred model; Nexus records that observation and retries once with `inherit`. Configuration is intent, not evidence: actual native-agent identity, preferred/effective model, fallback reason, execution mode, reviews, and verification belong in local run state and delivery reporting. `status` does not prove live capability.

Inspect registrations in the runtime you use: Codex reads `.codex/agents/` and `.agents/skills/`; Claude Code reads `.claude/agents/` and `.claude/skills/`; Cursor reads `.cursor/agents/` and `.cursor/skills/`. The generated files are thin pointers to the canonical Markdown policy, so runtime UI details can differ without changing the workflow.

## Git Worktrees as Job Tracking

Every mutating agent assignment receives a worker branch and worktree, even when jobs execute sequentially.

1. Nexus uses the integration branch named by the user or creates `cyberpunk/<task-id>-<slug>`.
2. Each worker receives `cyberpunk/<task-id>/<role>-<work-unit>` and `.worktrees/<task-id>/<work-unit>`.
3. Local run state records the base commit, owner, dependencies, status, result commit, review, and merge state.
4. The worker verifies and commits its scoped change.
5. Gatekeeper reviews the actual commit and reruns applicable checks.
6. Nexus merges approved jobs into the integration branch in dependency order and runs assembled verification.
7. Completed worktrees are removed after confirmed integration.

Approved PRD authoring is the sole planning-artifact exception: The Fixer may commit only the reviewed PRD on the current named branch before offering handoff. Implementation assignments still use worker branches and worktrees.

The team may create the internal branches, commits, worktrees, and merges needed for this lifecycle. It does not implicitly push, open a pull request, deploy, or merge into a protected branch.

## Skills

Roles describe ownership; skills describe reusable methods. Core skills cover requirements discovery, task classification, repository discovery, planning, plan review, decomposition, worktree isolation, scoped implementation, test-first development, debugging, backend safety, frontend quality, infrastructure safety, code review, verification, and memory curation.

Skills are loaded lazily: agents inspect descriptions and then read only those selected for the work packet.

- `skills/core/` contains framework-provided skills.
- `skills/project/` contains user-owned scenario skills and is never overwritten by initialization.
- Project skills must be explicitly enabled in `.cyberpunk/config.yml`.

This lets a project add framework, compliance, migration, performance, or domain-specific procedures without rewriting agent identities.

## Memory

The memory model separates durable knowledge from noisy execution history:

- `.cyberpunk/project.md` records repository facts, commands, conventions, and boundaries.
- `.cyberpunk/memory/decisions.md` records accepted decisions and rationale.
- `.cyberpunk/memory/patterns.md` records proven conventions.
- `.cyberpunk/memory/lessons.md` records validated root causes and preventive rules.
- `.cyberpunk/runs/` stores ignored local task state, raw evidence, attempts, and candidate lessons.

Lessons are promoted only when supported by evidence, reusable, actionable, non-duplicative, and free of secrets. Stale entries are marked superseded.

## Runtime Neutrality

The Operator discovers the project's real setup, formatting, linting, static analysis, test, build, and security commands from repository evidence. Missing commands remain unavailable instead of being invented. Quality policy belongs to the project; the team does not impose a language, framework, package manager, cloud, programming paradigm, or universal coverage target.

Native adapters are generated for the selected runtimes. The canonical `agents/`, `skills/`, and `.cyberpunk/` files remain the behavioral source of truth; generated adapters only point back to them. Bounded Cyberpunk-managed blocks are added to `AGENTS.md` and `CLAUDE.md`, preserving text outside the markers. Cursor owns `.cursor/rules/cyberpunk.mdc`.

Generated paths and hashes are recorded in `.cyberpunk/generated.yml`. `sync` reports a collision at an unowned native path and detects locally modified generated files as drift; modified generated files require `--force` to replace them. Version-1 configuration migration is idempotent and preserves existing project-owned settings. A stale version-1 canonical workflow, roles, or skills requires a reviewed canonical-protocol upgrade before `sync` generates version-2 registrations; ordinary sync preserves those policy files and reports the review command. Enable project-owned skills explicitly in `skills.enabled_project` before they receive native wrappers.

## Generated Structure

```text
.cyberpunk/
├── config.yml
├── generated.yml            # generated asset ownership and hashes
├── project.md
├── workflow.md
├── memory/
└── runs/                  # ignored local state
agents/
skills/
├── core/
└── project/               # user-owned
specs/
plans/
tasks/
AGENTS.md
CLAUDE.md
.codex/
├── config.toml
└── agents/
.agents/skills/
.claude/
├── agents/
└── skills/
.cursor/
├── agents/
├── skills/
└── rules/cyberpunk.mdc
```

## CLI

```text
cyberpunk init [--runtime codex|claude|cursor|all]... [--dry-run] [--force]
cyberpunk sync [--dry-run] [--force]
cyberpunk validate
cyberpunk status
cyberpunk --help
cyberpunk --version
```

- `init` copies missing canonical templates, adds ignored local-state paths, and registers all runtimes by default; `--runtime` selects a subset.
- `init --dry-run` previews changes.
- `init --force` refreshes framework-owned template paths without deleting extra project skills. It is also required before replacing drifted Cyberpunk-generated assets.
- `sync` migrates configuration when needed and regenerates the selected runtime registrations without recopying ordinary project-owned files.
- `validate` checks canonical protocol, selected native agents and skills, managed instruction blocks, manifests, collisions, and drift without writing.
- `status` reports configured policy and generated-state inspection without writing; it does not prove live capability or model availability.

The default execution policy records `max_concurrent_agents: 3`. It is a safety cap, not a promise that a runtime can delegate: a provider-disabled or unavailable native path is recorded as sequential fallback instead of simulated parallel work. See [the optional live runtime smoke matrix](docs/live-runtime-smoke.md) for manual account-level verification.

## Development

Run the dependency-free verification suite:

```bash
bash tests/run.sh
```

Contributions should preserve runtime neutrality, explicit role and skill contracts, safe Git authority, test-first behavior changes, and honest verification evidence.

## License

See [LICENSE](LICENSE).
