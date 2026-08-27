# Runtime-Neutral Agentic Engineering Team Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the static, stack-specific prompt scaffold with a tested, runtime-neutral engineering-team protocol that tracks mutating agent jobs in isolated worktrees and assembles them into a verified integration branch.

**Architecture:** Canonical Markdown agent, workflow, memory, and skill files define the portable protocol. A dependency-free Bash CLI initializes and validates those artifacts but never invokes a model. Nexus resolves an integration branch, tracks every mutating agent assignment through a worktree branch and commit, merges reviewed work in dependency order, and delivers the verified integration branch.

**Tech Stack:** Bash 3.2-compatible shell, Markdown, YAML-as-data, Git, and a dependency-free Bash test harness.

---

## Execution Coordination

Use `@superpowers:verification-before-completion` when executing this plan. Tasks 2–4 and Tasks 5–6 have deliberately non-overlapping ownership and may be delegated in parallel only when the active runtime and user authorization allow it. This implementation-plan coordination is separate from the product requirement below.

The generated team must use `@worktree-isolation` for every mutating agent assignment, whether assignments execute concurrently or sequentially. Product behavior must include:

1. Resolve a user-provided integration branch, or create `cyberpunk/<task-id>-<slug>` from the approved base.
2. Create each worker at `cyberpunk/<task-id>/<role>-<work-unit>` in a dedicated worktree.
3. Record worktree path, branch, base commit, owner, state, result commit, and merge status.
4. Require worker verification and a commit before Gatekeeper approval.
5. Merge approved workers into the integration branch in dependency order.
6. Rerun assembled verification and deliver the integration branch.
7. Remove integrated worktrees safely while retaining or deleting branches according to project policy.

No product workflow may merge implicitly into `main`, another protected branch, or a branch outside the resolved task integration branch.

### Task 1: Establish the Test Harness and Worktree Safety

**Files:**
- Create: `.gitignore`
- Create: `tests/test_helper.bash`
- Create: `tests/smoke_test.bash`
- Create: `tests/run.sh`

**Step 1: Add the worktree ignore rule**

Create `.gitignore` with:

```gitignore
.worktrees/
```

Run:

```bash
git check-ignore -q .worktrees
```

Expected: exit status 0.

**Step 2: Write the shared test helpers**

Create `tests/test_helper.bash` with helpers that:

- Resolve `REPO_ROOT` and `CYBERPUNK_BIN` without relying on the caller's directory.
- Create isolated temporary project directories with `mktemp -d`.
- Clean temporary directories through a trap.
- Provide `fail`, `assert_eq`, `assert_contains`, `assert_not_contains`, `assert_file`, `assert_dir`, and `assert_exit` functions.
- Print a clear test name before each case.

The helper must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
CYBERPUNK_BIN="$REPO_ROOT/cyberpunk"
```

**Step 3: Write passing baseline smoke tests**

Create `tests/smoke_test.bash` to assert:

- `bash -n cyberpunk` succeeds.
- `cyberpunk --version` exits 0 and contains `Cyberpunk CLI`.
- `cyberpunk --help` exits 0 and contains `USAGE`.

These tests describe current supported behavior and must pass before feature work branches.

**Step 4: Create the test runner**

Create `tests/run.sh` to find `tests/*_test.bash` in sorted order, execute each file in a new Bash process, count files, and fail immediately when a test file fails.

Expected final line:

```text
All <N> test files passed.
```

**Step 5: Run the baseline suite**

Run:

```bash
bash tests/run.sh
```

Expected: `smoke_test.bash` passes and the final summary reports one passing test file.

**Step 6: Commit the shared baseline**

```bash
git add .gitignore tests/test_helper.bash tests/smoke_test.bash tests/run.sh
git commit -m "test: add dependency-free shell test harness"
```

### Task 2: Build the Canonical Team Protocol and Memory Templates

**Parallel ownership:** `templates/.cyberpunk/**`, `templates/specs/**`, `tests/protocol_contract_test.bash`

**Required skills:** `@superpowers:test-driven-development`

**Files:**
- Create: `tests/protocol_contract_test.bash`
- Create: `templates/.cyberpunk/config.yml`
- Create: `templates/.cyberpunk/project.md`
- Create: `templates/.cyberpunk/workflow.md`
- Create: `templates/.cyberpunk/memory/decisions.md`
- Create: `templates/.cyberpunk/memory/patterns.md`
- Create: `templates/.cyberpunk/memory/lessons.md`
- Create: `templates/specs/.gitkeep`

**Step 1: Write failing protocol contract tests**

Create `tests/protocol_contract_test.bash` and assert:

- All listed canonical files exist.
- `config.yml` declares version 1, `integration-branch` delivery, adaptive workflow levels, skill search paths, empty enabled project skills, worktree isolation, internal job commits, and disabled push/PR/deploy/protected-branch merge defaults.
- `workflow.md` contains intake, classification, planning, worktree assignment, implementation, review, repair, delivery, and retrospective stages.
- `workflow.md` defines the work packet and result contracts.
- `project.md` defines conceptual setup, format, lint, static analysis, unit, integration, build, and security command categories without assigning ecosystem commands.
- Lesson memory requires symptom, root cause, prevention, scope, evidence, and status.

Run:

```bash
bash tests/protocol_contract_test.bash
```

Expected: FAIL because canonical protocol templates do not exist.

**Step 2: Add runtime-neutral configuration**

Create `templates/.cyberpunk/config.yml` with this top-level schema:

```yaml
version: 1
delivery:
  default: integration-branch
  allow_push: false
  allow_pull_requests: false
  allow_deploy: false
workflow:
  mode: adaptive
  levels: [quick, standard, complex]
git:
  integration_branch: auto
  branch_prefix: cyberpunk/
  worktree_root: .worktrees
  require_worktrees: true
  require_non_overlapping_ownership: true
  allow_internal_commits: true
  merge_worker_branches: true
  allow_protected_branch_merge: false
  cleanup_worktrees_after_integration: true
memory:
  tracked: [.cyberpunk/project.md, .cyberpunk/memory]
  local: .cyberpunk/runs
skills:
  core_path: skills/core
  project_path: skills/project
  enabled_project: []
```

Do not add language, package-manager, cloud-provider, programming-style, or coverage defaults.

**Step 3: Add the canonical workflow**

Create `templates/.cyberpunk/workflow.md` with:

- Nexus as the sole task entry point and delivery owner.
- Risk-based quick, standard, and complex routing criteria.
- Role participation for every route.
- Mandatory isolated worktrees for every mutating assignment, including sequential execution.
- Integration-branch resolution from user input or the `cyberpunk/<task-id>-<slug>` default.
- Worker branch naming as `cyberpunk/<task-id>/<role>-<work-unit>`.
- A YAML work packet containing id, objective, owner, integration branch, base commit, worker branch, worktree, allowed scope, acceptance, verification categories, dependencies, memory references, and required skills.
- A result contract containing status, changed files, acceptance results, commands observed, checks not run, risks, candidate lessons, result commit, and merge readiness.
- Run-state tracking for each worktree, commit, review status, and merge status.
- Gatekeeper review before merge, dependency-ordered integration, assembled verification, and safe cleanup.
- Review routing and the two-repair re-diagnosis / third-cycle escalation rule.
- Default authority boundaries.

**Step 4: Add project discovery and curated memory templates**

Create `project.md` with a `needs-discovery` status, repository facts section, boundaries section, and an empty conceptual verification command table.

Create memory templates with entry schemas:

```markdown
## <Entry title>

- Status: active | superseded
- Scope:
- Evidence:
- Recorded:
```

Add decision-specific rationale and revisit fields, pattern-specific example and applicability fields, and lesson-specific symptom, root cause, and prevention fields.

**Step 5: Run the protocol tests**

Run:

```bash
bash tests/protocol_contract_test.bash
bash tests/run.sh
```

Expected: both commands pass.

**Step 6: Commit the protocol worktree**

```bash
git add templates/.cyberpunk templates/specs tests/protocol_contract_test.bash
git commit -m "feat: add canonical team workflow and memory protocol"
```

### Task 3: Rewrite the Agent Team and Add Daemon and Neon

**Parallel ownership:** `templates/agents/**`, `tests/agent_contract_test.bash`

**Required skills:** `@superpowers:test-driven-development`

**Files:**
- Create: `tests/agent_contract_test.bash`
- Modify: `templates/agents/_common-principles.md`
- Modify: `templates/agents/nexus.md`
- Modify: `templates/agents/operator.md`
- Modify: `templates/agents/mind.md`
- Modify: `templates/agents/interrogator.md`
- Modify: `templates/agents/fragmenter.md`
- Modify: `templates/agents/coder.md`
- Create: `templates/agents/daemon.md`
- Create: `templates/agents/neon.md`
- Modify: `templates/agents/grid-master.md`
- Modify: `templates/agents/gatekeeper.md`

**Step 1: Write failing agent contract tests**

Create `tests/agent_contract_test.bash` to iterate over the ten public agent files and require these headings:

```text
## Mission
## Owns
## Does Not Own
## Default Skills
## Inputs
## Workflow
## Output Contract
## Escalation
## References
```

Also assert:

- Nexus contains adaptive routing and delivery ownership.
- Nexus contains integration-branch resolution, worker merge ordering, and worktree cleanup ownership.
- Coder identifies itself as a shared engineering contract.
- Daemon identifies itself as the backend engineer.
- Neon identifies itself as the frontend engineer.
- Gatekeeper states that it independently reruns applicable verification.
- Fragmenter requires non-overlapping ownership for parallel work.
- No agent mandates AWS, TypeScript, npm, functional programming, or a fixed coverage percentage.

Run:

```bash
bash tests/agent_contract_test.bash
```

Expected: FAIL because current agents use the legacy schema and Daemon/Neon are absent.

**Step 2: Rewrite common principles**

Replace stack-specific standards with:

- Evidence before completion claims.
- Repository conventions before personal preference.
- Minimal relevant context and explicit assumptions.
- Least authority and safe handling of destructive/external actions.
- Proportional planning.
- Explicit work packets and result contracts.
- Independent review and root-cause-driven repair.
- Runtime-neutral skill discovery and use.

**Step 3: Rewrite coordination roles**

Rewrite Nexus, Operator, Mind, Interrogator, and Fragmenter using the required headings and the approved responsibilities. Each file must name its default core skills using exact skill identifiers from Task 4.

**Step 4: Build the Coder guild**

Rewrite Coder as the shared implementation contract. Add Daemon and Neon as specialists that inherit Coder's scope, test, evidence, and handoff rules. Ensure cross-stack work requires a shared interface contract before parallelization.

**Step 5: Rewrite operations and review roles**

Make Grid Master platform-neutral and authority-aware. Make Gatekeeper independently inspect the diff, rerun relevant discovered project commands, distinguish pre-existing failures, and route findings by root cause.

**Step 6: Run agent tests**

Run:

```bash
bash tests/agent_contract_test.bash
bash tests/run.sh
```

Expected: both commands pass.

**Step 7: Commit the agent worktree**

```bash
git add templates/agents tests/agent_contract_test.bash
git commit -m "feat: modernize the cyberpunk engineering team"
```

### Task 4: Add Core Skills and Project Skill Extension Points

**Parallel ownership:** `templates/skills/**`, `tests/skill_contract_test.bash`

**Required skills:** `@superpowers:writing-skills`, `@skill-creator`, `@superpowers:test-driven-development`

**Files:**
- Create: `tests/skill_contract_test.bash`
- Create: `templates/skills/README.md`
- Create: `templates/skills/project/.gitkeep`
- Create: `templates/skills/core/task-classification/SKILL.md`
- Create: `templates/skills/core/repository-discovery/SKILL.md`
- Create: `templates/skills/core/implementation-planning/SKILL.md`
- Create: `templates/skills/core/plan-review/SKILL.md`
- Create: `templates/skills/core/task-decomposition/SKILL.md`
- Create: `templates/skills/core/worktree-isolation/SKILL.md`
- Create: `templates/skills/core/scoped-implementation/SKILL.md`
- Create: `templates/skills/core/systematic-debugging/SKILL.md`
- Create: `templates/skills/core/test-first-development/SKILL.md`
- Create: `templates/skills/core/backend-safety/SKILL.md`
- Create: `templates/skills/core/frontend-quality/SKILL.md`
- Create: `templates/skills/core/infrastructure-safety/SKILL.md`
- Create: `templates/skills/core/code-review/SKILL.md`
- Create: `templates/skills/core/verification-before-delivery/SKILL.md`
- Create: `templates/skills/core/memory-curation/SKILL.md`

**Step 1: Write failing skill contract tests**

Create `tests/skill_contract_test.bash` that finds every `templates/skills/core/*/SKILL.md` and requires YAML frontmatter fields:

```yaml
name:
version:
description:
triggers:
allowed-agents:
side-effects:
```

The test must also verify:

- Directory names equal skill names.
- Skill names are unique.
- Every skill contains `## When to Use`, `## Inputs`, `## Procedure`, `## Verification`, and `## Output`.
- `skills/project` exists and the README states that it is user-owned and not overwritten.
- Core skills do not prescribe a language-specific command.

Run:

```bash
bash tests/skill_contract_test.bash
```

Expected: FAIL because the skill system does not exist.

**Step 2: Add the skill authoring contract**

Create `templates/skills/README.md` documenting:

- Core versus project ownership.
- Lazy discovery: inspect metadata, then fully read selected skills.
- Explicit project-skill registration through `.cyberpunk/config.yml`.
- Precedence: user instruction, project policy, work packet, role contract, selected skill.
- No silent core-skill shadowing.
- Required review and validation for skill changes.

**Step 3: Implement planning and coordination skills**

Add task classification, repository discovery, implementation planning, plan review, task decomposition, and worktree isolation. The worktree skill must cover integration-branch resolution, worker branch creation, state recording, baseline verification, worker commit handoff, Gatekeeper review, dependency-ordered merge, assembled verification, and cleanup. Each procedure must be a short checklist with explicit stop conditions and an evidence-bearing output.

**Step 4: Implement engineering skills**

Add scoped implementation, systematic debugging, test-first development, backend safety, frontend quality, and infrastructure safety. Trigger test-first development only for behavior changes where an executable test is practical; require an explicit reason otherwise.

**Step 5: Implement review and learning skills**

Add code review, verification before delivery, and memory curation. Verification must require fresh command output. Memory curation must reject secrets, machine-specific noise, one-off failures, and unsupported generalizations.

**Step 6: Run skill tests**

Run:

```bash
bash tests/skill_contract_test.bash
bash tests/run.sh
```

Expected: both commands pass.

**Step 7: Commit the skill worktree**

```bash
git add templates/skills tests/skill_contract_test.bash
git commit -m "feat: add extensible agent skill system"
```

### Task 5: Upgrade the CLI for Initialization, Validation, and Status

**Parallel wave 2 ownership:** `cyberpunk`, `tests/cli_test.bash`

**Required skills:** `@superpowers:test-driven-development`, `@superpowers:systematic-debugging`

**Files:**
- Modify: `cyberpunk`
- Create: `tests/cli_test.bash`

**Step 1: Write failing CLI behavior tests**

Create `tests/cli_test.bash` with isolated temporary projects covering:

1. `init --dry-run` creates no files and reports planned operations.
2. `init` copies multiple agent, protocol, skill, and adapter files, catching the existing first-copy exit regression.
3. `init` creates `.cyberpunk/runs/` and appends `.cyberpunk/runs/` and the configured `.worktrees/` root to `.gitignore` exactly once.
4. A second `init` preserves a user-modified file.
5. `init --force` refreshes framework-owned templates.
6. `init --force` does not delete or overwrite an extra `skills/project/custom/SKILL.md` file.
7. `validate` succeeds for a complete scaffold.
8. `validate` fails and names a missing canonical file.
9. `status` reports initialized state plus agent and skill counts.
10. `--version` reports `0.2.0`.

Run:

```bash
bash tests/cli_test.bash
```

Expected: FAIL because `validate`, `status`, the new templates, and safe ignore handling are unsupported.

**Step 2: Refactor argument parsing**

Support:

```text
cyberpunk init [--dry-run] [--force]
cyberpunk validate
cyberpunk status
cyberpunk --help
cyberpunk --version
```

Reject flags that do not apply to a command. Keep `set -euo pipefail` and Bash 3.2 compatibility.

**Step 3: Generalize template copying**

Walk the `templates/` tree and copy its relative paths instead of maintaining a brittle manual mapping. Replace unsafe `((file_count++))` with:

```bash
file_count=$((file_count + 1))
```

Preserve destination files unless `--force` is set. Never delete destination-only project skills.

**Step 4: Add local-state ignore management**

Ensure `.cyberpunk/runs/` and `.worktrees/` are present exactly once in the target project's `.gitignore`. Dry-run reports additions without writing them.

**Step 5: Add validation**

Validate canonical protocol files, all ten agent files, at least one core skill, core skill metadata, and required ignore rules. Print every finding and return nonzero when any required contract is missing.

**Step 6: Add status reporting**

Report initialization state, project discovery status, agent count, core skill count, enabled project skill count, and local active-run count without changing the project.

**Step 7: Run CLI and complete tests**

Run:

```bash
bash -n cyberpunk
bash tests/cli_test.bash
bash tests/run.sh
```

Expected: all commands pass.

**Step 8: Commit the CLI worktree**

```bash
git add cyberpunk tests/cli_test.bash
git commit -m "feat: add team protocol validation and status commands"
```

### Task 6: Add Thin Runtime Adapters and Rewrite Documentation

**Parallel wave 2 ownership:** `README.md`, `templates/README.md`, `templates/AGENTS.md`, `templates/CLAUDE.md`, `templates/.cursor/rules/rules.mdc`, `tests/documentation_contract_test.bash`

**Required skills:** `@superpowers:test-driven-development`

**Files:**
- Modify: `README.md`
- Modify: `templates/README.md`
- Create: `templates/AGENTS.md`
- Create: `templates/CLAUDE.md`
- Modify: `templates/.cursor/rules/rules.mdc`
- Create: `tests/documentation_contract_test.bash`

**Step 1: Write failing documentation contract tests**

Assert that:

- All three runtime adapters point to `.cyberpunk/workflow.md` and `agents/nexus.md`.
- No adapter duplicates the full workflow.
- README describes the single-task Nexus interface, adaptive modes, Daemon, Neon, hybrid memory, skills, worker worktrees, integration branches, validation, and branch delivery.
- The documented role count matches the templates.
- Documentation does not claim universal AWS, TypeScript, functional-programming, npm, or fixed-coverage requirements.

Run:

```bash
bash tests/documentation_contract_test.bash
```

Expected: FAIL against the legacy documentation.

**Step 2: Create thin adapters**

Each adapter must instruct its runtime to:

1. Read `.cyberpunk/workflow.md`.
2. Read `agents/nexus.md` for user tasks.
3. Load only assigned role and skill files.
4. Follow project authority and worktree rules.

Keep each adapter concise and runtime-specific only where discovery requires it.

**Step 3: Rewrite the main README**

Lead with:

```text
Give The Nexus a task. The team inspects, plans proportionally, implements,
verifies, learns, and returns a verified integration branch.
```

Document installation, `init`, `validate`, `status`, architecture, adaptive workflows, roles, skills, memory, worker worktree tracking, integration-branch resolution, internal commit/merge authority, protected-branch restrictions, direct-role compatibility, and troubleshooting.

**Step 4: Update template documentation**

Explain canonical versus adapter files, framework-owned core skills, user-owned project skills, tracked memory, ignored run state, and force-update behavior.

**Step 5: Run documentation tests**

Run:

```bash
bash tests/documentation_contract_test.bash
bash tests/run.sh
```

Expected: both commands pass.

**Step 6: Commit the documentation worktree**

```bash
git add README.md templates/README.md templates/AGENTS.md templates/CLAUDE.md templates/.cursor/rules/rules.mdc tests/documentation_contract_test.bash
git commit -m "docs: document the autonomous engineering team workflow"
```

### Task 7: Integrate, Add Cross-Component Tests, and Verify Delivery

**Files:**
- Create: `tests/integration_test.bash`
- Modify if required: files already integrated from Tasks 2–6

**Required skills:** `@superpowers:systematic-debugging`, `@superpowers:verification-before-completion`, `@superpowers:requesting-code-review`

**Step 1: Write the failing integration test**

Create `tests/integration_test.bash` that:

1. Initializes a temporary Git repository.
2. Runs `cyberpunk init` from outside the source repository.
3. Runs `cyberpunk validate` successfully.
4. Confirms every default skill named by every agent exists under `skills/core/<name>/SKILL.md`.
5. Confirms `.cyberpunk/runs/` and `.worktrees/` are ignored with `git check-ignore`.
6. Adds a custom project skill, runs `init --force`, and confirms its checksum is unchanged.
7. Confirms a second initialization does not duplicate ignore entries.
8. Confirms `status` is read-only by comparing `git status --porcelain` before and after.
9. Confirms generated workflow and config define integration-branch resolution, worker branches, worktree state, internal commits, review-before-merge, assembled verification, and cleanup.
10. Confirms generated policy prohibits implicit protected-branch merges, pushes, pull requests, and deployments.

Run:

```bash
bash tests/integration_test.bash
```

Expected: FAIL if any independently implemented contract does not integrate.

**Step 2: Fix integration mismatches minimally**

Use the failing assertion to identify whether the owner is protocol, agent, skill, CLI, or documentation. Change the owning file only; do not weaken contract tests to accept incorrect behavior.

**Step 3: Run the complete verification suite**

Run:

```bash
bash -n cyberpunk
bash tests/run.sh
git diff --check
```

If `shellcheck` is installed, also run:

```bash
shellcheck cyberpunk tests/*.bash
```

Expected: all required commands pass. If ShellCheck is unavailable, record that fact in the delivery report.

**Step 4: Perform independent code review**

Review the complete branch against `docs/plans/2026-08-28-agentic-engineering-team-design.md`. Check especially:

- Runtime neutrality.
- Safe `--force` behavior for user-owned project skills.
- No claims of agent execution by the CLI.
- Correct worktree isolation guidance.
- Independent Gatekeeper evidence requirements.
- Internal worker commits and merges are limited to the resolved task integration branch.
- No implicit pushes, PRs, deployments, protected-branch merges, or skill mutation in generated policy.

Resolve critical and important findings, then rerun the complete verification suite.

**Step 5: Commit the integrated result**

```bash
git add cyberpunk README.md templates tests
git commit -m "feat: deliver runtime-neutral agentic engineering team"
```

## Final Delivery Evidence

Before reporting completion, capture:

- Current branch and commit.
- Generated integration-branch and worker-worktree policy validation.
- `bash -n cyberpunk` result.
- Test-file and assertion counts from `bash tests/run.sh`.
- ShellCheck result or explicit unavailability.
- `git diff --check` result.
- A temporary-project `init`, `validate`, and `status` transcript.
- Any remaining risks or intentionally deferred items.
