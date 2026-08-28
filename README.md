# Cyberpunk Context Runners

Give The Nexus a task. The team inspects the repository, plans proportionally, implements in isolated worktrees, verifies independently, learns from evidence, and returns a verified integration branch.

Cyberpunk Context Runners is a runtime-neutral engineering-team protocol. Its canonical behavior is plain Markdown and YAML, so file-aware coding agents can execute it sequentially or concurrently without depending on one model vendor. The dependency-free Bash CLI installs and validates the protocol; it does not pretend to run agents itself.

## Quick Start

Download or clone this repository, make the `cyberpunk` script available on your path, then initialize it inside a project:

```bash
cd /path/to/your/project
cyberpunk init
cyberpunk validate
cyberpunk status
```

Then give the task to your coding agent through The Nexus:

```text
Act as The Nexus. Add account recovery with expiring, single-use tokens.
Deliver the verified integration branch; do not push or open a pull request.
```

The runtime adapter loads `.cyberpunk/workflow.md`, then Nexus selects only the roles and skills required for the task.

## Adaptive Workflow

Nexus classifies by risk and uncertainty:

- **quick:** a localized, reversible change following an established pattern
- **standard:** meaningful behavior spanning several files or moderate uncertainty
- **complex:** architectural, cross-stack, security-sensitive, migratory, operationally risky, or highly uncertain work

Quick work goes directly to the relevant specialist and Gatekeeper. Standard work adds repository discovery and a concise plan. Complex work adds adversarial plan review, dependency decomposition, explicit integration contracts, and multiple isolated worker jobs.

## The Engineering Team

The system contains 10 specialized roles:

- **The Nexus:** engineering lead, task router, Git job coordinator, and delivery owner
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

## Git Worktrees as Job Tracking

Every mutating agent assignment receives a worker branch and worktree, even when jobs execute sequentially.

1. Nexus uses the integration branch named by the user or creates `cyberpunk/<task-id>-<slug>`.
2. Each worker receives `cyberpunk/<task-id>/<role>-<work-unit>` and `.worktrees/<task-id>/<work-unit>`.
3. Local run state records the base commit, owner, dependencies, status, result commit, review, and merge state.
4. The worker verifies and commits its scoped change.
5. Gatekeeper reviews the actual commit and reruns applicable checks.
6. Nexus merges approved jobs into the integration branch in dependency order and runs assembled verification.
7. Completed worktrees are removed after confirmed integration.

The team may create the internal branches, commits, worktrees, and merges needed for this lifecycle. It does not implicitly push, open a pull request, deploy, or merge into a protected branch.

## Skills

Roles describe ownership; skills describe reusable methods. Core skills cover task classification, repository discovery, planning, plan review, decomposition, worktree isolation, scoped implementation, test-first development, debugging, backend safety, frontend quality, infrastructure safety, code review, verification, and memory curation.

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

Thin adapters are generated for common file-aware runtimes:

- `AGENTS.md`
- `CLAUDE.md`
- `.cursor/rules/rules.mdc`

All adapters point to the same canonical workflow rather than duplicating policy.

## Generated Structure

```text
.cyberpunk/
├── config.yml
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
.cursor/rules/rules.mdc
```

## CLI

```text
cyberpunk init [--dry-run] [--force]
cyberpunk validate
cyberpunk status
cyberpunk --help
cyberpunk --version
```

- `init` copies missing templates and adds ignored local-state paths.
- `init --dry-run` previews changes.
- `init --force` refreshes framework-owned template paths without deleting extra project skills.
- `validate` checks required protocol, agent, skill, and ignore contracts.
- `status` reports initialization, discovery, agent, skill, and local-run state without writing.

## Development

Run the dependency-free verification suite:

```bash
bash tests/run.sh
```

Contributions should preserve runtime neutrality, explicit role and skill contracts, safe Git authority, test-first behavior changes, and honest verification evidence.

## License

See [LICENSE](LICENSE).
