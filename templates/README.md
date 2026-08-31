# Generated Team Templates

The CLI copies this tree into a target project. Canonical policy lives under `.cyberpunk/`; runtime adapters only point coding agents to that policy. Plain `cyberpunk init` registers Codex, Claude Code, and Cursor; use `cyberpunk init --runtime codex`, `cyberpunk init --runtime claude`, `cyberpunk init --runtime cursor`, or `cyberpunk init --runtime codex --runtime claude` for a subset, and use `cyberpunk sync` to refresh registrations.

## Ownership

- Framework-owned templates may be refreshed with `cyberpunk init --force`.
- Existing project files are preserved by ordinary initialization.
- Extra files under `skills/project/` are user-owned and never overwritten or deleted.
- `.cyberpunk/runs/` is created locally and ignored rather than shipped as tracked history.
- `.cyberpunk/generated.yml` records Cyberpunk-owned native assets and their hashes. Modified generated files require `--force`; unknown files at owned paths are collisions rather than overwrite targets.
- Version-1 configuration migration is idempotent. A stale canonical workflow, roles, or skills requires a reviewed canonical-protocol upgrade before `sync`; ordinary sync preserves those files. `validate` diagnoses the upgrade requirement, configuration, manifests, collisions, and drift, while `status` does not prove live capability.

## Main Areas

- `.cyberpunk/` — configuration, workflow, project context, and curated memory
- `agents/` — role contracts, including The Fixer for product discovery and The Nexus for engineering delivery
- `skills/core/` — portable framework skills, including `requirements-discovery`
- `skills/project/` — explicitly enabled project skills
- `specs/`, `plans/`, and `tasks/` — durable artifacts; Fixer PRDs use `specs/YYYY-MM-DD-<topic>-prd.md`
- `AGENTS.md`, `CLAUDE.md`, and Cursor rules — thin runtime adapters

## Runtime Registrations

- Codex: `.codex/agents/` and `.agents/skills/`, with a bounded managed block in `AGENTS.md`
- Claude Code: `.claude/agents/` and `.claude/skills/`, with a bounded managed block in `CLAUDE.md`
- Cursor: `.cursor/agents/`, `.cursor/skills/`, and `.cursor/rules/cyberpunk.mdc`

These files are generated pointers, not a second workflow. Inspect them in the relevant runtime or on disk, then give work to Nexus in the runtime you started; the Bash CLI does not start agents. `max_concurrent_agents: 3` is a safety cap. Nexus uses the minimum of the configured maximum, the observed runtime cap, and three; `parallelism: sequential` makes that limit one. Nexus is the sole dispatcher, dependency-bound roles remain sequential, a full queue waits, and worktree isolation does not start agents. Keep interactive Fixer discovery in the parent conversation; non-interactive Fixer analysis may use a native subagent. Native Gatekeeper review is fresh, while parent fallback records `review_context: parent` and a `null` identity. Native model profiles are configured per runtime; a rejected preferred model retries once with `inherit`, with observed execution recorded in local run state and delivery rather than inferred from configuration. Project skills are registered only when explicitly enabled in `skills.enabled_project`.

The templates do not prescribe a language, framework, package manager, cloud, architecture style, or universal quality threshold. The Operator discovers project-specific commands and conventions from repository evidence.
