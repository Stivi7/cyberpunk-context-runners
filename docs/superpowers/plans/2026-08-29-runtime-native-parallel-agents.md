# Runtime-Native Parallel Agents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `cyberpunk init` and `cyberpunk sync` register the canonical Cyberpunk team as native agents and skills for Codex, Claude Code, and Cursor, with safe automatic parallel dispatch, a three-subagent limit, runtime-specific model profiles, and honest sequential fallback.

**Architecture:** Keep `.cyberpunk/`, `agents/`, and `skills/` as the only behavioral source of truth. Extend the dependency-free Bash CLI with small configuration and generated-asset modules, then render thin runtime-native files from canonical content. Nexus remains the parent and sole dispatcher; generated adapters only tell each runtime how to load and execute the canonical protocol.

**Tech Stack:** Portable Markdown, YAML, and TOML contracts; dependency-free Bash; Git; Bash contract and integration tests. No vendor CLI, SDK, model call, or paid smoke test is part of the automated suite.

**Spec:** `docs/superpowers/specs/2026-08-29-runtime-native-parallel-agents-design.md`

## Global Constraints

- Canonical workflow, role, and skill files remain authoritative. Runtime-native files are generated pointers, never copied behavioral forks.
- Support exactly `codex`, `claude`, and `cursor`. Plain `cyberpunk init` and `--runtime all` enable all three; repeated `--runtime` flags normalize and deduplicate; reinitialization only adds runtimes.
- Reject an unknown runtime before creating or modifying any project file.
- Configuration version is `2`; migration preserves existing delivery, workflow, Git, memory, skill, instruction, and project-owned content.
- Nexus is the parent and sole dispatcher. Subagents never spawn sibling or nested Cyberpunk agents.
- Automatic parallelism schedules only dependency-ready `parallel_safe: true` packets, never exceeds three active subagents excluding Nexus, and never treats a full queue as a reason for sequential fallback.
- Mutating workers keep exclusive paths, a recorded branch/worktree/base, verification evidence, and a result commit. Gatekeeper is a fresh native agent before integration and again for assembled review.
- Role model routing resolves role/runtime override, then semantic profile/runtime mapping, then `inherit`. An unavailable preferred model receives one retry with `inherit`, and observed preferred/effective/fallback values are recorded.
- Use the approved default mappings verbatim: deep = `gpt-5.6-sol`/`opus`/`gpt-5.6-sol`; balanced = `gpt-5.6-terra`/`sonnet`/`composer-2.5[]`; fast = `gpt-5.6-luna`/`haiku`/`composer-2.5` for Codex/Claude/Cursor respectively.
- Deep roles: `nexus`, `fixer`, `mind`, `interrogator`, `gatekeeper`. Balanced roles: `fragmenter`, `coder`, `daemon`, `neon`, `grid-master`. Fast role: `operator`.
- Interactive Fixer discovery remains in the parent conversation. Nexus's configured deep model is a recommendation only when Nexus is spawned; the active parent model remains user-selected.
- Generate native agents at `.codex/agents/*.toml`, `.claude/agents/*.md`, and `.cursor/agents/*.md`.
- Generate native skills at `.agents/skills/*/SKILL.md`, `.claude/skills/*/SKILL.md`, and `.cursor/skills/*/SKILL.md`. Core skills are always registered; project skills are registered only when explicitly enabled.
- Preserve user content outside the `<!-- cyberpunk:start -->` / `<!-- cyberpunk:end -->` blocks in `AGENTS.md` and `CLAUDE.md`. Cursor owns only `.cursor/rules/cyberpunk.mdc`.
- Preserve existing `.codex/config.toml` values, including `agents.enabled = false` and an existing concurrency value. Add `max_concurrent_threads_per_session = 3` only when missing.
- Generated native assets have notices and are tracked by `.cyberpunk/generated.yml`. Modified generated assets and identifier collisions are reported; only `--force` may replace a modified Cyberpunk-owned asset.
- Bash code must remain compatible with macOS Bash 3.2: do not use associative arrays, `mapfile`, `readarray`, or Bash 4-only case conversion.
- Automated tests must not invoke Codex, Claude, Cursor, or any paid model. The live runtime matrix is documentation-only and opt-in.
- Preserve the user's unrelated working-tree edits. Mark the model-routing todo complete only after the implementation and full automated suite are verified.
- Baseline evidence on 2026-08-29: `bash tests/run.sh` passes all seven test files at commit `fea6c97`.

## File Structure

### New files

- `lib/config.bash` — runtime normalization, version-1 migration, version-2 YAML reads/writes, model profile and project-skill lookups.
- `lib/generated-assets.bash` — portable hashing, manifest reads/writes, collision/drift protection, managed instruction blocks, and Codex settings coexistence.
- `tests/runtime_adapter_test.bash` — focused native-agent, native-skill, manifest, collision, and runtime-subset contracts.
- `docs/live-runtime-smoke.md` — opt-in Codex, Claude Code, and Cursor smoke matrix.

### Modified files

- `cyberpunk` — source the two modules, add repeatable runtime options and `sync`, orchestrate migration/generation/validation/status, and bump the version.
- `templates/.cyberpunk/config.yml` — version-2 runtime, execution, model, and override defaults.
- `templates/.cyberpunk/workflow.md` — native dispatch queue, fresh review, model fallback, run-state, and honest delivery contracts.
- `templates/agents/_common-principles.md` — sole-dispatcher and honest native-execution invariants.
- `templates/agents/nexus.md` — native role dispatch, ready queue, fallback, review, and reporting ownership.
- `templates/agents/fragmenter.md` — dependencies, exclusive ownership/integration owner, and `parallel_safe` output.
- `templates/agents/gatekeeper.md` — fresh-context per-result and assembled-change review.
- `templates/skills/core/task-decomposition/SKILL.md` — required packet fields and safety decision.
- `templates/skills/core/worktree-isolation/SKILL.md` — native-isolation compatibility and overlapping-path prohibition.
- `templates/skills/core/code-review/SKILL.md` — fresh reviewer identity and result-commit evidence.
- `templates/AGENTS.md` and `templates/CLAUDE.md` — fixture form of the bounded managed block.
- `templates/.cursor/rules/rules.mdc` — remove the obsolete generic Cursor adapter; generated projects use `cyberpunk.mdc`.
- `README.md` and `templates/README.md` — setup, generated paths, execution semantics, models, status, migration, and inspection guidance.
- `tests/cli_test.bash` — CLI surface, runtime selection, migration, managed files, validation, status, and version.
- `tests/protocol_contract_test.bash` — configuration, dispatch, run-state, fallback, and review contracts.
- `tests/agent_contract_test.bash` — sole-dispatcher, model, packet, and fresh-review obligations.
- `tests/skill_contract_test.bash` — native wrapper source metadata and orchestration skill obligations.
- `tests/integration_test.bash` — fresh/subset/multi-runtime projects, legacy migration, coexistence, drift, collision, and project skills.
- `tests/documentation_contract_test.bash` — public commands, paths, semantics, and opt-in smoke documentation.
- `tests/run.sh` — add `runtime_adapter_test.bash`.
- `todo.md` — mark only the per-agent model-routing item complete after final verification.

## Shared Interfaces

Implement these interfaces once and keep later tasks as callers:

```bash
# lib/config.bash
SUPPORTED_RUNTIMES=(codex claude cursor)
ROLE_IDS=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)

normalize_runtime_selection <runtime>...
configured_runtimes <config-path>
merge_configured_runtimes <config-path> <runtime>...
migrate_config_v1 <config-path>
configured_project_skills <config-path>
role_profile <config-path> <role>
profile_model <config-path> <profile> <runtime>
role_model_override <config-path> <role> <runtime>
resolve_role_model <config-path> <role> <runtime>

# lib/generated-assets.bash
sha256_file <path>
begin_generated_manifest <manifest-path>
write_generated_asset <path> <source> <runtime> <kind> <identifier> <content-file>
finish_generated_manifest
update_managed_block <path> <body-file>
ensure_codex_agent_settings <path>
validate_generated_manifest <manifest-path>
```

`normalize_runtime_selection` prints one identifier per line in canonical order. `resolve_role_model` prints exactly one model string and always terminates in `inherit` when no valid preferred value exists.

The supported override shape is deliberately explicit and Bash-readable:

```yaml
models:
  overrides:
    gatekeeper:
      profile: deep
      codex: "inherit"
      claude: "opus"
```

An override may set `profile` and/or a runtime key. Runtime-specific value wins over the override profile; an override profile wins over `models.roles`; a missing mapping terminates in `inherit`.

The generated manifest schema is:

```yaml
version: 1
assets:
  - path: ".codex/agents/gatekeeper.toml"
    source: "agents/gatekeeper.md"
    runtime: "codex"
    kind: "agent"
    identifier: "gatekeeper"
    sha256: "<64 lowercase hex characters>"
```

---

### Task 1: Add version-2 configuration, runtime selection, and migration

**Files:**

- Create: `lib/config.bash`
- Modify: `cyberpunk:3-419`
- Modify: `templates/.cyberpunk/config.yml`
- Modify: `tests/cli_test.bash`
- Modify: `tests/protocol_contract_test.bash`
- Modify: `tests/integration_test.bash`
- Modify: `tests/smoke_test.bash`

**Interfaces:**

- Produces every `lib/config.bash` function listed under Shared Interfaces.
- Produces normalized runtime output in canonical `codex`, `claude`, `cursor` order.
- Produces a version-2 config that Tasks 3–5 consume.
- Adds `sync [--dry-run] [--force]` command plumbing; Task 2 supplies generated-asset behavior.

- [ ] **Step 1: Write failing configuration and runtime-selection tests**

Update protocol assertions from `version: 1` to the exact version-2 values from the spec. In CLI/integration tests cover:

```bash
assert_exit 0 run_cli "$project" init
assert_contains "$(<"$project/.cyberpunk/config.yml")" "enabled: [codex, claude, cursor]"

assert_exit 0 run_cli "$codex_project" init --runtime codex
assert_contains "$(<"$codex_project/.cyberpunk/config.yml")" "enabled: [codex]"

assert_exit 0 run_cli "$multi_project" init --runtime cursor --runtime codex --runtime cursor
assert_contains "$(<"$multi_project/.cyberpunk/config.yml")" "enabled: [codex, cursor]"

capture run_cli "$invalid_project" init --runtime warp
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Unknown runtime: warp"
[[ ! -e "$invalid_project/.cyberpunk" ]] || fail "invalid runtime wrote project files"
```

Add a legacy fixture by copying the current version-1 config text, run `cyberpunk sync`, and assert version 2 plus all new sections while the old `delivery`, `git`, and `skills` values remain byte-for-byte present. Re-run sync and assert a stable checksum.

- [ ] **Step 2: Run focused tests and confirm RED**

```bash
bash tests/protocol_contract_test.bash
bash tests/cli_test.bash
bash tests/integration_test.bash
```

Expected: failures for version 2, `--runtime`, and `sync`; invalid runtime is currently parsed as an unknown init option.

- [ ] **Step 3: Create `lib/config.bash` with portable parsers and writers**

Implement the Shared Interfaces without a general YAML dependency. Use indentation-aware `awk` only for the fixed schema. Quote stripping must accept bare and double-quoted scalar values. Inline and block-list readers must both work for `runtimes.enabled` and `skills.enabled_project`.

Runtime normalization must follow this contract:

```bash
normalize_runtime_selection() {
    local requested="${*:-all}"
    local runtime

    [[ " $requested " == *" all "* ]] && requested="codex claude cursor"
    for runtime in "${SUPPORTED_RUNTIMES[@]}"; do
        [[ " $requested " == *" $runtime "* ]] && printf '%s\n' "$runtime"
    done
    # Compare every requested token against all/codex/claude/cursor and fail
    # before callers mutate the project.
}
```

Do not use substring matching as the validation check; iterate tokens so `code` does not match `codex`.

`migrate_config_v1` must:

1. no-op on `version: 2`;
2. reject unknown versions;
3. replace only the first top-level `version: 1` line;
4. append missing `runtimes`, `execution`, and `models` sections with the approved defaults;
5. preserve every existing line outside those additions;
6. write through a project-local temporary file and rename only after successful generation;
7. honor `DRY_RUN` without writing.

`merge_configured_runtimes` reads the current enabled list, unions requested values, and rewrites only `runtimes.enabled` in canonical order.

- [ ] **Step 4: Update the canonical configuration template**

Place the exact approved blocks before `delivery:`:

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

- [ ] **Step 5: Wire CLI parsing and command flow**

Source `lib/config.bash` after constants, store repeatable flags in a Bash-3-compatible indexed array, and validate them before `validate_templates` or any call that writes. Use the same `--dry-run`/`--force` parser for `init` and `sync`; `--runtime` is accepted only by `init`.

Update usage to:

```text
cyberpunk init [--runtime codex|claude|cursor|all]... [--dry-run] [--force]
cyberpunk sync [--dry-run] [--force]
cyberpunk validate
cyberpunk status
```

`init_project` copies canonical templates, migrates/merges config, and then calls an initially migration-only `sync_project`. Later tasks extend that function with generated assets. Reset global option state at command entry so test helpers can invoke the executable repeatedly without state leaks.

- [ ] **Step 6: Verify focused and full tests**

```bash
for path in cyberpunk lib/config.bash; do bash -n "$path"; done
bash tests/protocol_contract_test.bash
bash tests/cli_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

Expected: all commands pass with no warnings or paid-runtime calls.

- [ ] **Step 7: Self-review and commit**

Check unknown-runtime preflight with `git status --short` before and after the command, scan `lib/config.bash` for Bash-4-only syntax, then:

```bash
git add cyberpunk lib/config.bash templates/.cyberpunk/config.yml tests/cli_test.bash tests/protocol_contract_test.bash tests/integration_test.bash tests/smoke_test.bash
git diff --cached --check
git commit -m "feat: add runtime configuration and migration"
```

### Task 2: Add generated-asset ownership and coexistence-safe adapters

**Files:**

- Create: `lib/generated-assets.bash`
- Modify: `cyberpunk`
- Modify: `templates/AGENTS.md`
- Modify: `templates/CLAUDE.md`
- Delete: `templates/.cursor/rules/rules.mdc`
- Modify: `tests/cli_test.bash`
- Modify: `tests/integration_test.bash`
- Modify: `tests/documentation_contract_test.bash`

**Interfaces:**

- Produces every `lib/generated-assets.bash` interface listed under Shared Interfaces.
- Produces bounded root instruction blocks, `.cursor/rules/cyberpunk.mdc`, `.codex/config.toml`, and `.cyberpunk/generated.yml` for later native assets.
- `write_generated_asset` is the sole writer Tasks 3 and 4 use for native files.

- [ ] **Step 1: Write failing coexistence, drift, and manifest tests**

Create fixtures with existing root instructions and Codex settings:

```bash
printf '%s\n' '# User instructions' > "$project/AGENTS.md"
printf '%s\n' '# Claude user instructions' > "$project/CLAUDE.md"
mkdir -p "$project/.codex"
printf '%s\n' '[agents]' 'enabled = false' 'max_concurrent_threads_per_session = 2' > "$project/.codex/config.toml"

assert_exit 0 run_cli "$project" init --runtime codex --runtime cursor
assert_contains "$(<"$project/AGENTS.md")" "# User instructions"
assert_eq 1 "$(line_count '<!-- cyberpunk:start -->' "$project/AGENTS.md")"
assert_eq 1 "$(line_count '<!-- cyberpunk:end -->' "$project/AGENTS.md")"
assert_contains "$(<"$project/.codex/config.toml")" "enabled = false"
assert_contains "$(<"$project/.codex/config.toml")" "max_concurrent_threads_per_session = 2"
assert_file "$project/.cursor/rules/cyberpunk.mdc"
assert_file "$project/.cyberpunk/generated.yml"
```

Also cover an absent Codex file, an existing file without `[agents]`, an existing `[agents]` section without the key, malformed/duplicate managed markers, a user-owned collision at `.cursor/rules/cyberpunk.mdc`, a locally modified generated rule, non-force refusal, and force replacement. Re-run sync twice and assert root content and manifest checksums remain stable.

- [ ] **Step 2: Run focused tests and confirm RED**

```bash
bash tests/cli_test.bash
bash tests/integration_test.bash
bash tests/documentation_contract_test.bash
```

Expected: failures because managed blocks, generated ownership, the dedicated Cursor rule, and safe Codex settings do not exist.

- [ ] **Step 3: Implement portable generated-asset ownership**

Create `lib/generated-assets.bash`. Use `shasum -a 256` when present and `sha256sum` otherwise; fail with a clear message if neither exists. Do not use `cksum` because the manifest contract requires portable SHA-256.

`begin_generated_manifest` loads prior records into a tab-separated temporary index and opens a new records file. `write_generated_asset` must implement this decision table:

| Destination | Prior manifest record | Actual hash equals prior hash | `--force` | Result |
|---|---:|---:|---:|---|
| absent | either | n/a | either | create and record |
| present | no | n/a | either | collision error; never overwrite |
| present | yes | yes | either | replace only if content changed; record new hash |
| present | yes | no | false | drift error; preserve file |
| present | yes | no | true | replace and record new hash |

Every Markdown/MDC asset begins with:

```markdown
<!-- Generated by Cyberpunk. Canonical source is recorded in .cyberpunk/generated.yml. -->
```

Every TOML asset begins with:

```toml
# Generated by Cyberpunk. Canonical source is recorded in .cyberpunk/generated.yml.
```

Write a new manifest only if every expected asset succeeds. Sort records by path before rendering the exact Shared Interfaces schema. Preserve prior records for still-existing generated assets not touched by the current runtime subset; do not silently abandon ownership.

- [ ] **Step 4: Implement managed blocks and Codex settings coexistence**

`update_managed_block` accepts only zero markers or exactly one ordered pair. With zero markers, append one blank line plus the managed block. With one pair, replace only the inclusive marker range. Duplicate, reversed, or unmatched markers fail without writing.

The body is exactly:

```markdown
<!-- cyberpunk:start -->
Read `.cyberpunk/workflow.md` completely, act as Nexus in the parent session,
and use the active runtime's native Cyberpunk agents and skills. Dispatch
dependency-ready independent work in parallel up to project policy limits.
<!-- cyberpunk:end -->
```

`ensure_codex_agent_settings` must preserve the three existing-file cases from the spec. Insert a missing key inside the existing `[agents]` section before the next TOML table. Never change an existing `enabled`, concurrency, default-model, or reasoning value.

- [ ] **Step 5: Extend `sync_project` and stop copying runtime-owned adapters**

Source the new module. Skip `AGENTS.md`, `CLAUDE.md`, and every runtime-native destination during `copy_template_tree`; otherwise `init --force` could overwrite user content before managed synchronization.

For enabled runtimes:

- Codex: update `AGENTS.md` and `.codex/config.toml`.
- Claude: update `CLAUDE.md`.
- Cursor: render `.cursor/rules/cyberpunk.mdc` through `write_generated_asset` with `source: .cyberpunk/workflow.md`, `kind: adapter`, and `identifier: cyberpunk`.

Delete the obsolete source fixture `templates/.cursor/rules/rules.mdc`. Change adapter documentation tests to inspect the managed-block fixtures plus the generated Cursor rule in an initialized temporary project.

- [ ] **Step 6: Verify focused and full tests**

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash; do bash -n "$path"; done
bash tests/cli_test.bash
bash tests/integration_test.bash
bash tests/documentation_contract_test.bash
bash tests/run.sh
```

- [ ] **Step 7: Self-review and commit**

Verify `init --force` cannot erase sentinel text outside either managed block, verify a modified generated Cursor rule survives non-force sync byte-for-byte, scan for broad `rm`/glob deletion, then:

```bash
git add cyberpunk lib/generated-assets.bash templates/AGENTS.md templates/CLAUDE.md templates/.cursor/rules/rules.mdc tests/cli_test.bash tests/integration_test.bash tests/documentation_contract_test.bash
git diff --cached --check
git commit -m "feat: manage runtime adapter assets safely"
```

### Task 3: Generate runtime-native agents and resolve role models

**Files:**

- Create: `tests/runtime_adapter_test.bash`
- Modify: `cyberpunk`
- Modify: `lib/config.bash`
- Modify: `tests/run.sh`
- Modify: `tests/agent_contract_test.bash`
- Modify: `tests/cli_test.bash`
- Modify: `tests/integration_test.bash`

**Interfaces:**

- Consumes `ROLE_IDS`, configured runtimes, `resolve_role_model`, and `write_generated_asset`.
- Produces one native definition per canonical role for every enabled runtime.
- Produces model values later referenced by orchestration and status contracts.

- [ ] **Step 1: Add the runtime-adapter test harness and failing agent matrix**

Add `tests/runtime_adapter_test.bash` to `tests/run.sh`. Initialize a fresh all-runtime fixture and assert all 33 files exist:

```bash
roles=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)

for role in "${roles[@]}"; do
    assert_file "$project/.codex/agents/$role.toml"
    assert_file "$project/.claude/agents/$role.md"
    assert_file "$project/.cursor/agents/$role.md"
done
```

For every generated file assert the identifier, a non-empty description, the expected model, and pointers to:

- `.cyberpunk/workflow.md`
- `agents/_common-principles.md`
- `agents/<role>.md`
- the assigned work packet and its required skills

Assert every non-Nexus definition forbids spawning or delegating nested team agents. Assert Nexus says it is the parent and sole dispatcher. Check exact representative models for `fixer`, `operator`, `daemon`, and `gatekeeper` in all three runtimes.

Add subset assertions so `init --runtime claude` creates `.claude/agents/*` but no `.codex/agents`, `.cursor/agents`, `AGENTS.md`, or Cursor rule. Add a model-override fixture using the Shared Interfaces YAML shape and assert runtime override > override profile > role profile > `inherit`.

- [ ] **Step 2: Run the new and focused tests and confirm RED**

```bash
bash tests/runtime_adapter_test.bash
bash tests/agent_contract_test.bash
bash tests/integration_test.bash
```

Expected: the new test fails on the first missing `.codex/agents/nexus.toml`.

- [ ] **Step 3: Complete model parsing and resolution**

Implement the configuration functions so resolution is deterministic:

```bash
resolve_role_model() {
    local config="$1" role="$2" runtime="$3"
    local model profile

    model="$(role_model_override "$config" "$role" "$runtime")"
    [[ -n "$model" ]] && { printf '%s\n' "$model"; return 0; }

    profile="$(role_model_override "$config" "$role" profile)"
    [[ -n "$profile" ]] || profile="$(role_profile "$config" "$role")"
    model="$(profile_model "$config" "$profile" "$runtime")"
    [[ -n "$model" ]] && printf '%s\n' "$model" || printf '%s\n' inherit
}
```

Reject an override profile outside `deep|balanced|fast`, a role without a profile, a profile without all enabled-runtime mappings, and a `models.fallback` value other than `inherit` during validation. Do not validate whether a vendor account actually offers the configured model; runtime fallback handles that observation.

- [ ] **Step 4: Add one canonical role-description mapping**

Implement `role_description <role>` as a complete `case` in `cyberpunk`. Descriptions must state when Nexus should delegate and remain under one line. Use these meanings:

| Role | Delegation description |
|---|---|
| nexus | Parent engineering coordinator for complete Cyberpunk task delivery |
| fixer | Product requirements discovery for unresolved product or feature decisions |
| operator | Read-only repository discovery and verification-command mapping |
| mind | Architecture and implementation planning from approved requirements |
| interrogator | Adversarial review of complex implementation plans |
| fragmenter | Dependency-aware work decomposition and safe ownership boundaries |
| coder | General scoped implementation following an approved work packet |
| daemon | Backend, API, persistence, and domain-logic implementation |
| neon | Frontend, interaction, accessibility, and responsive implementation |
| grid-master | Platform, automation, observability, and operational implementation |
| gatekeeper | Fresh-context review of a result commit or assembled change |

Unknown roles are errors; do not generate vague fallback definitions.

- [ ] **Step 5: Render the three native formats**

Generate Codex TOML with the current required keys:

```toml
# Generated by Cyberpunk. Canonical source is recorded in .cyberpunk/generated.yml.
name = "gatekeeper"
description = "Fresh-context review of a result commit or assembled change"
model = "gpt-5.6-sol"
developer_instructions = """
Read `.cyberpunk/workflow.md`, `agents/_common-principles.md`, and
`agents/gatekeeper.md` completely. Read the assigned work packet, result
evidence, and every required skill before acting. Follow canonical policy;
this file contains no replacement workflow. Return the role's output contract.
Do not spawn, delegate, or coordinate sibling or nested Cyberpunk agents.
"""
```

Generate Claude Markdown:

```markdown
<!-- Generated by Cyberpunk. Canonical source is recorded in .cyberpunk/generated.yml. -->
---
name: gatekeeper
description: Fresh-context review of a result commit or assembled change
model: opus
---

Read `.cyberpunk/workflow.md`, `agents/_common-principles.md`, and
`agents/gatekeeper.md` completely. Read the assigned work packet, result
evidence, and every required skill before acting. Follow canonical policy;
this file contains no replacement workflow. Return the role's output contract.
Do not spawn, delegate, or coordinate sibling or nested Cyberpunk agents.
```

Generate Cursor Markdown with the same body and frontmatter keys `name`, `description`, and `model`. Do not add unsupported vendor fields. For Nexus, replace the final prohibition with:

```text
You are the parent and sole Cyberpunk dispatcher. Spawn, steer, resume, interrupt,
and replace native subagents only as the canonical workflow permits. Never ask a
subagent to create sibling or nested Cyberpunk agents.
```

Escape TOML strings safely and fail on a newline or quote in an identifier/model rather than emitting malformed configuration.

- [ ] **Step 6: Register agents during sync and test ownership behavior**

For each enabled runtime and canonical role, render to a temporary content file and call `write_generated_asset` with `source: agents/<role>.md`, `kind: agent`, and the role identifier. Test a pre-existing unowned `.claude/agents/nexus.md` collision, a modified owned `.codex/agents/operator.toml`, non-force preservation, and force regeneration.

- [ ] **Step 7: Verify focused and full tests**

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash tests/runtime_adapter_test.bash; do bash -n "$path"; done
bash tests/runtime_adapter_test.bash
bash tests/agent_contract_test.bash
bash tests/cli_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

- [ ] **Step 8: Self-review and commit**

Count canonical roles and generated records, confirm a single-runtime fixture has exactly 11 agent records, scan generated bodies for duplicated role policy, then:

```bash
git add cyberpunk lib/config.bash tests/runtime_adapter_test.bash tests/run.sh tests/agent_contract_test.bash tests/cli_test.bash tests/integration_test.bash
git diff --cached --check
git commit -m "feat: register runtime-native agents"
```

### Task 4: Generate native skill registrations for core and enabled project skills

**Files:**

- Modify: `cyberpunk`
- Modify: `lib/config.bash`
- Modify: `tests/runtime_adapter_test.bash`
- Modify: `tests/skill_contract_test.bash`
- Modify: `tests/integration_test.bash`

**Interfaces:**

- Consumes canonical skill frontmatter, configured runtimes, enabled project skill identifiers, and `write_generated_asset`.
- Produces discoverable wrappers with the canonical name/description and one relative pointer back to the complete canonical skill.

- [ ] **Step 1: Write failing core and project skill matrix tests**

In the all-runtime fixture, count the canonical core skills and assert the same count under each native skill root. For every canonical skill name and description, assert:

```bash
assert_file "$project/.agents/skills/$skill/SKILL.md"
assert_file "$project/.claude/skills/$skill/SKILL.md"
assert_file "$project/.cursor/skills/$skill/SKILL.md"
assert_contains "$wrapper" "name: $skill"
assert_contains "$wrapper" "description: $description"
assert_contains "$wrapper" "../../../skills/core/$skill/SKILL.md"
assert_contains "$wrapper" "read and follow"
assert_contains "$wrapper" "relative to that canonical skill directory"
```

Create `skills/project/release-policy/SKILL.md`, set `enabled_project: [release-policy]`, sync, and assert all enabled runtimes receive a wrapper pointing to `skills/project/release-policy/SKILL.md`. Assert an unlisted project skill has no wrapper.

Add failing cases for:

- enabled project identifier with no canonical file;
- duplicate core frontmatter names;
- project skill whose frontmatter name differs from its directory;
- project skill name colliding with a core skill;
- existing unowned native wrapper collision;
- modified owned wrapper preserved without force and replaced with force.

- [ ] **Step 2: Run focused tests and confirm RED**

```bash
bash tests/runtime_adapter_test.bash
bash tests/skill_contract_test.bash
bash tests/integration_test.bash
```

Expected: wrappers are missing and project-skill validation does not yet exist.

- [ ] **Step 3: Implement strict canonical skill discovery**

Add functions that enumerate `skills/core/*/SKILL.md` and only explicitly enabled `skills/project/*/SKILL.md`. Parse frontmatter only between the first two `---` lines. Require exactly one single-line `name:` and `description:` value, require directory/name equality, and reject duplicate identifiers before any wrapper is written.

`configured_project_skills` must accept:

```yaml
enabled_project: []
enabled_project: [release-policy, compliance]
enabled_project:
  - release-policy
  - compliance
```

Normalize identifiers in lexical order for deterministic generation. An enabled missing skill is an error, not a warning.

- [ ] **Step 4: Render the exact thin wrapper**

For a core skill:

```markdown
<!-- Generated by Cyberpunk. Canonical source is recorded in .cyberpunk/generated.yml. -->
---
name: task-decomposition
description: Split an approved complex plan into dependency-aware jobs with safe ownership boundaries.
---

Read `../../../skills/core/task-decomposition/SKILL.md` completely and follow it.
Resolve every referenced script, template, reference, or asset relative to that
canonical skill directory.
```

For a project skill, change only `core` to `project`. Do not copy any canonical procedure body into the wrapper.

Codex uses `.agents/skills`; Claude uses `.claude/skills`; Cursor uses `.cursor/skills`. Call `write_generated_asset` with the canonical skill path as source, the runtime, `kind: skill`, and canonical name.

- [ ] **Step 5: Verify focused and full tests**

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash; do bash -n "$path"; done
bash tests/runtime_adapter_test.bash
bash tests/skill_contract_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

- [ ] **Step 6: Self-review and commit**

Compare the canonical and native name sets with sorted temporary files, scan wrapper bodies for copied `## Procedure` headings, verify custom project skill contents are unchanged after `sync --force`, then:

```bash
git add cyberpunk lib/config.bash tests/runtime_adapter_test.bash tests/skill_contract_test.bash tests/integration_test.bash
git diff --cached --check
git commit -m "feat: register runtime-native skills"
```

### Task 5: Validate generated runtime state and expand read-only status

**Files:**

- Modify: `cyberpunk`
- Modify: `lib/config.bash`
- Modify: `lib/generated-assets.bash`
- Modify: `tests/cli_test.bash`
- Modify: `tests/runtime_adapter_test.bash`
- Modify: `tests/integration_test.bash`

**Interfaces:**

- Consumes version-2 config, expected native path sets, and generated manifest records.
- Produces actionable validation errors and a status report that describes configuration and drift without claiming observed runtime activity.

- [ ] **Step 1: Write failing validation and status tests**

Add fixtures for each validation category that can be checked deterministically without invoking a runtime:

- unknown/duplicate runtime identifiers;
- `max_concurrent_agents` of 0 and 4;
- missing `models.fallback: inherit`;
- missing role profile and enabled-runtime profile mapping;
- missing native agent;
- missing native core/enabled-project skill wrapper;
- wrapper pointing to a missing canonical path;
- stale/modified hash;
- malformed or duplicate managed block;
- native identifier collision.

Status for a healthy all-runtime project must contain:

```text
Configured runtimes: codex, claude, cursor
Parallelism: auto
Maximum concurrent subagents: 3
Model fallback: inherit
Native agents: codex=11 claude=11 cursor=11
Native skills: codex=16 claude=16 cursor=16
Generated assets: synchronized
```

Modify one generated file and assert status says `Generated assets: drift detected` while remaining read-only by comparing `git status --porcelain` before and after.

- [ ] **Step 2: Run focused tests and confirm RED**

```bash
bash tests/cli_test.bash
bash tests/runtime_adapter_test.bash
bash tests/integration_test.bash
```

Expected: existing validation checks only canonical baseline policy, and status lacks all runtime-native fields.

- [ ] **Step 3: Implement configuration validation**

Validate the fixed schema with evidence-bearing errors. Runtime duplicates must be detected before normalization hides them. The concurrency limit is an integer in `[1,3]`. Every canonical role appears exactly once under `models.roles`, maps to `deep|balanced|fast`, and every referenced profile has a non-empty model or `inherit` for each enabled runtime.

Validate project skill enablement and canonical skill metadata using Task 4's discovery functions; do not duplicate parsers in `cyberpunk`.

- [ ] **Step 4: Implement generated adapter validation**

`validate_generated_manifest` must:

1. require one manifest record for every expected agent, skill, and Cursor adapter;
2. reject duplicate manifest paths and duplicate `(runtime, kind, identifier)` tuples;
3. require every listed path to exist;
4. require actual SHA-256 to equal the recorded value;
5. verify the manifest source exists;
6. verify agent paths and extensions match their runtime;
7. verify skill wrappers contain the canonical name, description, and correct source pointer;
8. validate exactly one managed block in each enabled runtime's root instruction file;
9. report specific paths and expected/actual evidence.

Do not rewrite anything during validation. Extra user files with unrelated identifiers are allowed. A Cyberpunk identifier at an expected native path without a manifest record is a collision error.

- [ ] **Step 5: Expand status without fabricating capability**

Reuse read-only parsers and counters. Report configured policy and generated state, plus the existing project discovery, canonical agent/skill, project-skill, and local-run counts. Do not print “parallel agents available,” “model available,” or any claim that requires observing a running vendor session.

If config or manifest is malformed, status remains non-mutating and reports `unknown` or `drift detected` rather than silently fixing it.

- [ ] **Step 6: Verify focused and full tests**

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash; do bash -n "$path"; done
bash tests/cli_test.bash
bash tests/runtime_adapter_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

- [ ] **Step 7: Self-review and commit**

Run `status` and `validate` against a healthy fixture and every corrupt fixture, confirm neither changes checksums, scan messages for unsupported live-capability claims, then:

```bash
git add cyberpunk lib/config.bash lib/generated-assets.bash tests/cli_test.bash tests/runtime_adapter_test.bash tests/integration_test.bash
git diff --cached --check
git commit -m "feat: validate native runtime registrations"
```

### Task 6: Strengthen the canonical native dispatch and run-state protocol

**Files:**

- Modify: `templates/.cyberpunk/workflow.md`
- Modify: `templates/agents/_common-principles.md`
- Modify: `templates/agents/nexus.md`
- Modify: `templates/agents/fragmenter.md`
- Modify: `templates/agents/gatekeeper.md`
- Modify: `templates/skills/core/task-decomposition/SKILL.md`
- Modify: `templates/skills/core/worktree-isolation/SKILL.md`
- Modify: `templates/skills/core/code-review/SKILL.md`
- Modify: `tests/protocol_contract_test.bash`
- Modify: `tests/agent_contract_test.bash`
- Modify: `tests/skill_contract_test.bash`
- Modify: `tests/integration_test.bash`

**Interfaces:**

- Consumes configured runtime, model, parallelism, worktree, and generated registration contracts.
- Produces the behavioral instructions the parent Nexus and native roles execute.
- Produces work-packet, result, review, fallback, and run-state fields used to prove what actually ran.

- [ ] **Step 1: Write failing orchestration contract tests**

Extend protocol, agent, and skill tests with exact obligations. The combined canonical contract must contain:

```text
Nexus is the only component allowed to spawn
dependency-ready
ready queue
parallel_safe
max_concurrent_agents
three active subagents
full queue
fresh Gatekeeper
assembled-change review
model_preferred
model_effective
model_fallback_reason
inherit
native agent evidence
roles performed in the parent context
```

Assert the Nexus owns spawn/resume/steer/interrupt/replace and queue capacity; every other public role plus common principles forbids nested team delegation. Assert Fragmenter emits dependencies, exclusive mutable scope or an integration owner/contract, and `parallel_safe`. Assert Gatekeeper requires a fresh agent identity, result commit, observed verification, and assembled review.

Add generated-project integration assertions so native agent bodies reinforce rather than contradict these canonical rules.

- [ ] **Step 2: Run focused tests and confirm RED**

```bash
bash tests/protocol_contract_test.bash
bash tests/agent_contract_test.bash
bash tests/skill_contract_test.bash
bash tests/integration_test.bash
```

Expected: failures for sole native dispatch, the ready queue, the three-agent cap, model fallback evidence, and fresh assembled review.

- [ ] **Step 3: Update common principles and Nexus ownership**

Add a `## Native Delegation` section to common principles with these invariants:

- Nexus is the parent and only dispatcher.
- Subagents do their assigned role and never spawn, steer, resume, interrupt, or replace team agents.
- Fresh contexts receive complete work packets because conversational context is not inherited.
- Actual runtime, native-agent identity, execution mode, preferred/effective model, and fallback reason are evidence, not assumptions.
- A missing native capability is an explicit sequential fallback, never simulated concurrency.

Extend Nexus `Owns`, `Does Not Own`, `Inputs`, `Workflow`, and `Output Contract`. Its queue algorithm must be unambiguous:

1. Resolve the active runtime and configured maximum; honor a lower runtime cap and `agents.enabled = false` when observable.
2. Run dependency-bound planning stages as fresh native roles sequentially.
3. Enqueue only packets whose dependencies are approved and integrated as required.
4. Dispatch `parallel_safe: true` packets while active subagents are below three.
5. Leave excess ready packets queued; do not label capacity waiting as fallback.
6. Continue unrelated jobs if one worker fails; retain failed worktree/evidence and never integrate it.
7. Start fresh Gatekeeper review for each result, allowing independent reviews to share the same global capacity.
8. Resume the original worker for rejection when supported; otherwise replace it with the complete packet, evidence, and findings.
9. Merge approved results in dependency order and run a fresh assembled Gatekeeper review before delivery.

- [ ] **Step 4: Extend work packet and decomposition contracts**

Add these required work-packet fields to workflow and task-decomposition skill:

```yaml
parallel_safe: true
dependencies: []
allowed_scope:
  - path/to/owned/**
integration_owner: null
integration_contract: null
required_skills: []
model_profile: balanced
```

`parallel_safe: true` is valid only when dependencies are satisfied and mutable paths do not overlap. Overlap requires `parallel_safe: false` or a named integration owner plus a concrete integration contract; worktree isolation alone is insufficient.

Update worktree-isolation so a native runtime copy is acceptable only when it preserves the recorded worker branch, base commit, allowed scope, and integration contract. Otherwise Nexus creates the Cyberpunk worktree before dispatch.

- [ ] **Step 5: Require fresh Gatekeeper evidence**

Update Gatekeeper and code-review skill so each review output includes:

```yaml
review_agent_instance: runtime-provided-id-or-null
review_context: fresh
result_commit: def456
verification_observed: []
review_status: approved
```

The absence of a runtime-provided identifier is recorded as `null`, never invented. When native delegation is available, an approval without fresh context is invalid. After per-result integration, assembled review uses another fresh Gatekeeper instance.

- [ ] **Step 6: Replace the run-state example with observed execution fields**

Use the spec's schema and include ownership evidence needed for validation:

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
    allowed_scope: [src/frontend/**]
    worker_branch: cyberpunk/TASK-014/neon-frontend
    worktree: .worktrees/TASK-014/frontend
    execution_status: completed
    review_agent_instance: codex-agent-c91b
    review_context: fresh
    review_status: approved
    result_commit: def456
    merged: false
fallback:
  used: false
  category: null
  reason: null
  observed_evidence: []
  affected_jobs: []
  delivery_impact: null
```

Document the five allowed fallback categories from the spec. Model rejection receives one retry with `inherit`; record preferred model, observed failure reason, and effective fallback. Prefer the same custom role with explicit inherited model; otherwise use the runtime's built-in default worker with the complete canonical role and packet. Never generate duplicate fallback agent files.

- [ ] **Step 7: Define honest delivery reporting**

Delivery must separately list:

- native agents that ran concurrently;
- native agents that ran sequentially because of dependencies;
- roles performed in the parent because native delegation was unavailable;
- jobs that waited only for queue capacity;
- preferred/effective models and fallbacks actually observed;
- tests, result commits, fresh reviews, and merges actually observed.

Prohibit claims inferred only from configuration or planned execution.

- [ ] **Step 8: Verify focused and full tests**

```bash
bash tests/protocol_contract_test.bash
bash tests/agent_contract_test.bash
bash tests/skill_contract_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

- [ ] **Step 9: Self-review and commit**

Trace one four-job example through queue, worker, review, merge, assembled review, and fallback vocabulary. Search every non-Nexus canonical role for wording that authorizes delegation. Then:

```bash
git add templates/.cyberpunk/workflow.md templates/agents/_common-principles.md templates/agents/nexus.md templates/agents/fragmenter.md templates/agents/gatekeeper.md templates/skills/core/task-decomposition/SKILL.md templates/skills/core/worktree-isolation/SKILL.md templates/skills/core/code-review/SKILL.md tests/protocol_contract_test.bash tests/agent_contract_test.bash tests/skill_contract_test.bash tests/integration_test.bash
git diff --cached --check
git commit -m "feat: require native parallel dispatch and review"
```

### Task 7: Document setup and close the verified model-routing todo

**Files:**

- Create: `docs/live-runtime-smoke.md`
- Modify: `README.md`
- Modify: `templates/README.md`
- Modify: `tests/documentation_contract_test.bash`
- Modify: `tests/cli_test.bash`
- Modify: `tests/smoke_test.bash`
- Modify: `cyberpunk`
- Modify: `todo.md`

**Interfaces:**

- Consumes the final CLI, generated paths, model/parallelism semantics, and validation/status output.
- Produces complete user-facing setup and inspection guidance.
- Closes only the model-routing todo after fresh verification succeeds.

- [ ] **Step 1: Write failing documentation and version tests**

Require README and generated-template documentation to include:

```text
cyberpunk init --runtime codex
cyberpunk init --runtime claude
cyberpunk init --runtime cursor
cyberpunk init --runtime codex --runtime claude
cyberpunk sync
.codex/agents/
.agents/skills/
.claude/agents/
.claude/skills/
.cursor/agents/
.cursor/skills/
max_concurrent_agents: 3
worktree isolation does not start agents
inherit
generated.yml
```

Assert docs explain that dependency-bound roles remain sequential, a full queue waits, modified generated files require `--force`, migration is idempotent, and status does not prove live capability. Assert `docs/live-runtime-smoke.md` exists and is labeled optional/usage-consuming. Update version expectations to `0.4.0`.

- [ ] **Step 2: Run documentation and CLI tests and confirm RED**

```bash
bash tests/documentation_contract_test.bash
bash tests/cli_test.bash
bash tests/smoke_test.bash
```

Expected: failures for missing runtime-native documentation, smoke matrix, and version `0.4.0`.

- [ ] **Step 3: Rewrite Quick Start and CLI documentation**

Show default-all and subset setup, then explain that the user starts the installed runtime normally and asks Nexus for work; the Bash CLI installs registrations but never starts model processes.

Update Generated Structure with all native paths and `.cyberpunk/generated.yml`. Explain canonical-vs-generated ownership, managed blocks, project-skill enablement, collision/drift handling, `sync`, `validate`, `status`, and version-1 migration. Remove the duplicated `init --force` bullet.

- [ ] **Step 4: Document safe parallelism and model routing**

State clearly:

- Nexus is the parent and sole dispatcher.
- At most three active subagents run; Nexus is excluded.
- Only dependency-ready, ownership-safe work runs concurrently.
- Worktrees isolate changes but do not themselves create concurrency.
- Gatekeeper uses fresh context before integration.
- Model profiles map per runtime and retry once with `inherit` when rejected.
- Actual execution and fallback evidence appears in local run state and delivery; configuration alone is not proof.

Include paths or UI/command hints to inspect native agents in Codex, Claude Code, and Cursor without promising identical vendor interfaces.

- [ ] **Step 5: Add the opt-in live smoke matrix**

Create `docs/live-runtime-smoke.md` with separate Codex, Claude Code, and Cursor sections. Each repeats the seven approved observations:

1. initialize a runtime-specific fixture;
2. give Nexus four independent packets;
3. observe three native subagents and one queued packet;
4. confirm mutating worktree/branch isolation;
5. confirm fresh Gatekeeper identity;
6. disable/block native delegation and confirm recorded sequential fallback;
7. configure an unavailable model and confirm one `inherit` retry.

Begin with a warning that it is manual, opt-in, account-dependent, and consumes model usage. Do not add it to `tests/run.sh`.

- [ ] **Step 6: Bump version and run final verification before editing todo**

Set `VERSION="0.4.0"`, then run:

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash tests/*.bash; do bash -n "$path"; done
bash tests/run.sh
git diff --check
```

Expected: syntax checks pass and all eight test files pass with no paid-runtime calls. If any check fails, do not mark the todo complete.

- [ ] **Step 7: Mark only the verified model-routing todo complete**

Preserve all other todo text. Change the model-routing line when it is present; if this isolated branch does not contain the user's preserved unstaged addition, add the checked line exactly once:

```markdown
- [x] For each agent specify the ai model that will be used. for example fixer and nexus gpt sol. If the model is not found, it falls to inherit (since it depends on the ai tool being used)
```

Do not normalize the user's wording as part of this task.

- [ ] **Step 8: Re-run completion verification and inspect scope**

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash tests/*.bash; do bash -n "$path"; done
bash tests/run.sh
git diff --check
git status --short
```

Expected: all eight test files pass; only implementation, documentation, tests, and the one checked todo line differ from Task 6's base.

- [ ] **Step 9: Self-review and commit**

Search docs for obsolete `.cursor/rules/rules.mdc`, duplicate `init --force` bullets, claims that the CLI launches agents, and claims that configured parallelism proves live execution. Then:

```bash
git add cyberpunk README.md templates/README.md docs/live-runtime-smoke.md tests/documentation_contract_test.bash tests/cli_test.bash tests/smoke_test.bash todo.md
git diff --cached --check
git commit -m "docs: explain runtime-native parallel setup"
```

## Final Verification

After all task reviews are clean, run the whole-branch review package and one fresh final reviewer. Resolve its Critical/Important findings through the SDD fix loop, then run:

```bash
for path in cyberpunk lib/config.bash lib/generated-assets.bash tests/*.bash; do bash -n "$path"; done
bash tests/run.sh
git diff --check "$(git merge-base HEAD implement-todo)"..HEAD
git status --short
```

Expected final evidence:

- eight automated Bash test files pass;
- no automated command invokes a vendor runtime or paid model;
- the implementation worktree is clean;
- generated native agents and skills match canonical role/skill sets for all enabled runtimes;
- subset initialization, migration, collisions, drift, managed blocks, Codex coexistence, validation, and read-only status are covered;
- only the model-routing todo is newly checked;
- final Gatekeeper/code review has no unadjudicated Critical or Important finding.
