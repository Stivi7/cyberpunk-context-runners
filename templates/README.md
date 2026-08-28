# Generated Team Templates

The CLI copies this tree into a target project. Canonical policy lives under `.cyberpunk/`; runtime adapters only point coding agents to that policy.

## Ownership

- Framework-owned templates may be refreshed with `cyberpunk init --force`.
- Existing project files are preserved by ordinary initialization.
- Extra files under `skills/project/` are user-owned and never overwritten or deleted.
- `.cyberpunk/runs/` is created locally and ignored rather than shipped as tracked history.

## Main Areas

- `.cyberpunk/` — configuration, workflow, project context, and curated memory
- `agents/` — role contracts for The Nexus and the engineering team
- `skills/core/` — portable framework skills
- `skills/project/` — explicitly enabled project skills
- `specs/`, `plans/`, and `tasks/` — durable artifacts created only when useful
- `AGENTS.md`, `CLAUDE.md`, and Cursor rules — thin runtime adapters

The templates do not prescribe a language, framework, package manager, cloud, architecture style, or universal quality threshold. The Operator discovers project-specific commands and conventions from repository evidence.
