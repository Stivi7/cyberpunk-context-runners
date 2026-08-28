# The Fixer PRD Creator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add The Fixer persona and a runtime-neutral requirements-discovery workflow that produces an approved, current-branch PRD commit and offers an explicit Nexus handoff.

**Architecture:** The Fixer is a focused persona backed by a reusable `requirements-discovery` core skill. The canonical workflow and Nexus define routing and the handoff contract, while the existing Bash CLI distributes and validates the new templates without becoming an agent runtime.

**Tech Stack:** Portable Markdown and YAML contracts, dependency-free Bash CLI and Bash contract tests, Git.

**Spec:** `docs/superpowers/specs/2026-08-28-fixer-prd-creator-design.md`

## Global Constraints

- The implementation must not depend on Superpowers or any other external runtime plugin.
- The Fixer handles new products, features, and architectural changes; routine fixes and sufficiently specified tasks stay with Nexus.
- Discovery depth is `Brief`, `Standard`, or `Architectural`, but every depth retains the design-approval gate.
- PRDs use the literal path pattern `specs/YYYY-MM-DD-<topic>-prd.md` and the stable section contract from the spec.
- The user reviews the written PRD before it is committed.
- The Fixer commits only the approved PRD on the current named branch and asks before handing it to Nexus.
- The existing worker-worktree rules remain mandatory for implementation; only approved PRD authoring receives the documented planning-artifact exception.
- Preserve all three entries currently represented by `todo.md`; mark only the Fixer entry complete.
- Preserve runtime neutrality: do not prescribe a language, package manager, cloud, framework, or universal quality threshold.
- Baseline evidence on 2026-08-28: `bash tests/run.sh` passes all seven test files.

## File Structure

### New files

- `templates/agents/fixer.md` — persona identity, ownership boundary, workflow, output, and escalation contract.
- `templates/skills/core/requirements-discovery/SKILL.md` — portable discovery method, PRD schema, approval gates, commit safety, and handoff schema.

### Modified files

- `templates/.cyberpunk/workflow.md` — canonical discovery routing, PRD exception, and handoff lifecycle.
- `templates/agents/nexus.md` — Nexus routing and consumption responsibilities.
- `templates/agents/_common-principles.md` — narrow PRD-authoring exception to the general worktree rule.
- `cyberpunk` — required template paths and minor version bump to `0.3.0`.
- `README.md` — user-facing Fixer flow, eleventh role, discovery skill, and worktree exception.
- `templates/README.md` — generated-project area descriptions.
- `todo.md` — completed Fixer item and preserved follow-up items.
- `tests/agent_contract_test.bash` — Fixer role contract.
- `tests/skill_contract_test.bash` — discovery-skill metadata and behavior contract.
- `tests/protocol_contract_test.bash` — routing, handoff, and isolation-exception contract.
- `tests/cli_test.bash` — generation, preservation, refresh, validation, counts, and version.
- `tests/integration_test.bash` — generated Fixer-to-skill resolution and handoff protocol.
- `tests/documentation_contract_test.bash` — public documentation contract.

---

### Task 1: Add The Fixer persona and requirements-discovery skill

**Files:**

- Create: `templates/agents/fixer.md`
- Create: `templates/skills/core/requirements-discovery/SKILL.md`
- Modify: `tests/agent_contract_test.bash:9-60`
- Modify: `tests/skill_contract_test.bash:9-73`

**Interfaces:**

- Consumes: the shared agent headings in `templates/agents/_common-principles.md` and the portable skill headings enforced by `tests/skill_contract_test.bash`.
- Produces: public agent identifier `fixer`, core skill identifier `requirements-discovery`, PRD path pattern `specs/YYYY-MM-DD-<topic>-prd.md`, and the Fixer output fields consumed by Task 2.

- [ ] **Step 1: Write the failing Fixer agent contract test**

Add `fixer` to the public agent list and append a focused contract test:

```bash
agents=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)

test_start "Fixer owns approved PRD creation and handoff gates"
fixer="$(<"$AGENT_ROOT/fixer.md")"
for value in \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "commit only the approved PRD" \
    "ask whether to hand" \
    "does not implement"; do
    assert_contains "$fixer" "$value" "Fixer responsibility"
done
```

Place the focused test before the runtime-neutrality loop so the new persona is also checked for banned stack assumptions.

- [ ] **Step 2: Write the failing discovery-skill contract test**

Add `requirements-discovery` to `expected_skills` immediately after `task-classification`, then append:

```bash
test_start "requirements discovery preserves approval and handoff gates"
discovery="$(<"$SKILL_ROOT/core/requirements-discovery/SKILL.md")"
for value in \
    "Brief" \
    "Standard" \
    "Architectural" \
    "one focused question" \
    "two or three" \
    "design approval" \
    "artifact approval" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "must not overwrite" \
    "current named branch" \
    "commit only the approved PRD" \
    "discovery_complete: true" \
    "user_authorized_handoff: true"; do
    assert_contains "$discovery" "$value" "requirements-discovery safeguard"
done
```

- [ ] **Step 3: Run the two contract tests and verify the new files are missing**

Run:

```bash
bash tests/agent_contract_test.bash
bash tests/skill_contract_test.bash
```

Expected: both commands fail; the first reports missing `templates/agents/fixer.md`, and the second reports missing `templates/skills/core/requirements-discovery/SKILL.md`.

- [ ] **Step 4: Create the Fixer persona**

Create `templates/agents/fixer.md` with this complete contract:

```markdown
# The Fixer — Product Requirements Broker

## Mission

Turn an early product idea into an approved, committed product requirements document that Nexus can consume without repeating discovery.

## Owns

- Direct and Nexus-routed product-discovery conversations.
- Brief, Standard, or Architectural discovery-depth classification.
- Requirement, scope, success, constraint, risk, and authority clarification.
- Alternative approaches, trade-offs, recommendations, and progressive approval.
- PRD composition, self-review, artifact review, and a focused current-branch commit.
- Asking whether to hand the committed PRD to Nexus.

## Does Not Own

- The Fixer does not implement the requested product or feature.
- Implementation architecture or implementation plans owned by The Mind.
- Approval of product decisions on the user's behalf.
- Automatic implementation, handoff, push, pull request, deployment, or protected-branch merge.

## Default Skills

- `requirements-discovery`

## Inputs

- A user idea or a discovery-heavy request routed by Nexus.
- `.cyberpunk/project.md`, relevant curated memory, existing specs, and applicable decisions.
- User answers, approvals, authority boundaries, and the current named branch.

## Workflow

1. Read the complete `requirements-discovery` skill and relevant project context.
2. Classify discovery depth and decompose work that is too large for one PRD.
3. Ask one focused question at a time until purpose, users, scope, behavior, constraints, success, and risks are clear.
4. Compare viable approaches and present the recommended requirements in sections for approval.
5. After design approval, write and self-review `specs/YYYY-MM-DD-<topic>-prd.md`.
6. Ask the user to review the written artifact and revise it until artifact approval.
7. Confirm the current named branch, preserve unrelated changes, and commit only the approved PRD.
8. Ask whether to hand the committed PRD to Nexus; stop cleanly when the user declines.

## Output Contract

- Approved PRD path, branch, and commit SHA.
- Acceptance criteria, risks, and explicitly deferred decisions.
- Design-approval and artifact-approval evidence.
- If authorized, a handoff with `source: fixer`, `discovery_complete: true`, and `user_authorized_handoff: true`.
- If handoff is declined, a committed PRD as the valid terminal result.

## Escalation

Escalate an irreducible product decision, a request too broad to decompose safely, a blocking deferred decision, a conflicting PRD path, the absence of a current named branch, or any condition that prevents a focused PRD-only commit.

## References

- `./_common-principles.md`
- `../.cyberpunk/workflow.md`
- `../skills/core/requirements-discovery/SKILL.md`
```

- [ ] **Step 5: Create the requirements-discovery skill**

Create `templates/skills/core/requirements-discovery/SKILL.md` with this complete procedure:

````markdown
---
name: requirements-discovery
description: Use when a new product, feature, or architectural request needs collaborative discovery before Nexus can plan implementation.
---

# Requirements Discovery

## Metadata

- Version: 1.0.0
- Triggers: Direct Fixer invocation or Nexus routing of materially incomplete product work
- Allowed agents: Fixer
- Side effects: Writes and commits one user-approved PRD on the current named branch

## When to Use

Use for a new product, feature, or architectural change when the target user, problem, scope, expected behavior, constraints, or acceptance criteria still require material decisions. Do not use for routine fixes, maintenance, a sufficiently specified task, or an approved PRD with no blocking deferred decision.

## Inputs

The user's idea, repository context, relevant curated memory, existing specs, applicable decisions, authority boundaries, Git state, and answers gathered during discovery.

## Procedure

1. Inspect `.cyberpunk/project.md`, relevant memory, existing specs, applicable decisions, and current Git state before detailed questions.
2. Classify the discovery depth:
   - **Brief:** a bounded feature with a known user and outcome.
   - **Standard:** multiple flows or meaningful product decisions.
   - **Architectural:** a new product, cross-system behavior, or major uncertainty.
3. If the request contains independently implementable products or subsystems, show their relationships and suggested order, then complete one PRD-sized slice at a time.
4. Ask one focused question at a time. Prefer concise choices when they improve clarity, but allow an open answer when the available choices would constrain the user incorrectly.
5. Resolve purpose, target users, use cases, goals, measurable success, non-goals, behavior, constraints, authority, risks, and acceptance criteria. Include technical detail only when it is necessary to make a requirement unambiguous; The Mind owns later implementation architecture.
6. Present two or three viable approaches with trade-offs and a recommendation.
7. Present the requirements in sections proportional to their complexity and request design approval as the design progresses.
8. Do not create a PRD until the user has approved the complete design.
9. Resolve the PRD path under the literal pattern `specs/YYYY-MM-DD-<topic>-prd.md`. The Fixer must not overwrite an existing PRD silently: update it only when the user explicitly identified it, otherwise disclose the conflict and agree on a non-conflicting topic slug. Write the approved PRD with these headings:
   - Summary and Problem Statement
   - Target Users and Use Cases
   - Goals and Success Criteria
   - Non-goals and Scope Boundaries
   - Functional Requirements
   - User Journeys and Expected Behavior
   - Constraints and Non-functional Requirements
   - Considered Approaches and Accepted Decisions
   - Edge Cases and Failure Behavior
   - Acceptance Criteria
   - Dependencies and Risks
   - Deferred Decisions
10. Self-review for placeholders, contradictions, ambiguous requirements, excess scope, and missing acceptance coverage. A deferred decision records its owner, reason, and resolution stage; it cannot block safe Nexus planning.
11. Ask the user to review the written file. Revise and repeat self-review until artifact approval.
12. Before committing:
    - Confirm `git branch --show-current` returns the current named branch.
    - Inspect tracked, untracked, and already staged changes.
    - Stage only the approved PRD path without unstaging or modifying unrelated work.
    - Verify the PRD diff and use a path-limited documentation commit so unrelated staged paths remain untouched.
    - Capture the resulting branch and commit SHA.
13. Ask whether to hand the committed PRD to Nexus. Do not continue automatically.
14. On approval, emit the handoff contract below. On decline, stop with the committed PRD as a successful terminal result.

## Verification

Before offering handoff, verify all of the following:

- The design and written artifact have separate recorded user approvals.
- The PRD exists at the agreed non-conflicting path and contains every required heading.
- No placeholder or contradictory requirement remains.
- Every acceptance criterion is measurable from observable behavior or evidence.
- Every deferred decision has an owner, reason, and resolution stage and none blocks planning.
- The current branch is named and the resulting commit contains only the approved PRD.
- The handoff is offered only after the commit succeeds.

## Output

Return the PRD path, current branch, commit SHA, acceptance criteria, risks, deferred decisions, and approval state. After explicit handoff approval, include:

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

If the commit cannot be created safely, report the exact blocker and do not emit an authorized handoff.
````

- [ ] **Step 6: Run the persona and skill contract tests**

Run:

```bash
bash tests/agent_contract_test.bash
bash tests/skill_contract_test.bash
```

Expected: both commands pass, including runtime-neutrality checks for the new files.

- [ ] **Step 7: Commit the persona and skill contracts**

```bash
git add templates/agents/fixer.md templates/skills/core/requirements-discovery/SKILL.md tests/agent_contract_test.bash tests/skill_contract_test.bash
git diff --cached --check
git commit -m "feat: add Fixer requirements discovery contracts"
```

### Task 2: Integrate discovery routing and the committed handoff

**Files:**

- Modify: `templates/.cyberpunk/workflow.md:3-33,112-114`
- Modify: `templates/agents/nexus.md:7-60`
- Modify: `templates/agents/_common-principles.md:35-37`
- Modify: `tests/protocol_contract_test.bash:8-92`

**Interfaces:**

- Consumes: `fixer`, `requirements-discovery`, and the Fixer output vocabulary created in Task 1.
- Produces: canonical `## Requirements Discovery` lifecycle and the exact handoff fields `source`, `discovery_complete`, `prd_path`, `prd_commit`, `branch`, `acceptance_criteria`, `risks`, `deferred_decisions`, and `user_authorized_handoff`.

- [ ] **Step 1: Write the failing canonical discovery protocol test**

Add paths near the existing protocol constants:

```bash
NEXUS="$TEMPLATE_ROOT/agents/nexus.md"
COMMON_PRINCIPLES="$TEMPLATE_ROOT/agents/_common-principles.md"
```

Add this test after the existing workflow lifecycle test:

```bash
test_start "requirements discovery routes safely and hands off a committed PRD"
for value in \
    "## Requirements Discovery" \
    "new product, feature, or architectural" \
    "routine bug fix or maintenance" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "planning-artifact exception" \
    "source: fixer" \
    "discovery_complete: true" \
    "prd_commit:" \
    "user_authorized_handoff: true" \
    "continue sequentially" \
    "does not repeat discovery"; do
    assert_contains "$workflow_content" "$value" "Fixer workflow contract"
done

nexus_content="$(<"$NEXUS")"
for value in \
    "The Fixer" \
    "approved PRD" \
    "discovery_complete: true" \
    "does not repeat completed discovery"; do
    assert_contains "$nexus_content" "$value" "Nexus discovery routing"
done

common_principles="$(<"$COMMON_PRINCIPLES")"
for value in "planning-artifact exception" "approved PRD" "current named branch"; do
    assert_contains "$common_principles" "$value" "PRD worktree exception"
done
```

- [ ] **Step 2: Run the protocol contract and verify the discovery section is absent**

Run:

```bash
bash tests/protocol_contract_test.bash
```

Expected: FAIL because `.cyberpunk/workflow.md` does not contain `## Requirements Discovery`.

- [ ] **Step 3: Add the canonical requirements-discovery lifecycle**

Change the workflow introduction to acknowledge both entry paths:

```markdown
The Nexus is the default entry point for engineering tasks and owns coordination through delivery. The Fixer is the direct entry point for product discovery and may also receive discovery-heavy work from Nexus. Agents exchange explicit artifacts; they do not rely on hidden conversational context.
```

Insert this section between `## Intake` and `## Classification`:

````markdown
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
````

Update `## Worktree Assignment` so its first paragraph reads:

```markdown
Every mutating implementation work unit receives its own branch and Git worktree, including sequential jobs. Read-only planning and review do not require worktrees. The approved PRD planning-artifact exception is defined under Requirements Discovery; it applies only to The Fixer's focused PRD commit on the current named branch.
```

Extend `## Authority` with:

```markdown
An approved Fixer PRD may be committed on the current named branch only through the Requirements Discovery gates. That authority does not include unrelated files or implementation work.
```

- [ ] **Step 4: Add Nexus routing and consumption responsibilities**

Add these bullets under `## Owns` in `templates/agents/nexus.md`:

```markdown
- Routing materially incomplete new-product, feature, and architectural requests to The Fixer.
- Accepting an explicitly authorized, committed Fixer PRD handoff without repeating completed discovery.
```

Add this bullet under `## Does Not Own`:

```markdown
- Reopening an approved PRD without a concrete contradiction or blocking deferred decision.
```

Add this input under `## Inputs`:

```markdown
- An optional approved PRD handoff with `discovery_complete: true`, path, commit, branch, acceptance criteria, risks, and deferred decisions.
```

Replace the first two workflow steps and renumber the rest:

```markdown
1. Route materially incomplete new-product, feature, or architectural work to The Fixer; keep routine and sufficiently specified work in the normal intake flow.
2. When an authorized Fixer handoff is present, validate the approved PRD commit; Nexus does not repeat completed discovery unless a concrete blocker exists.
3. Normalize objective, acceptance criteria, scope, constraints, and authority.
4. Classify the task as quick, standard, or complex.
5. Resolve the integration branch and create local run state.
6. Select roles and the smallest relevant skill set.
7. Give every mutating implementation job an isolated worktree and bounded work packet.
8. Route review findings to the responsible role and force re-diagnosis after repeated failures.
9. Merge only approved result commits in dependency order.
10. Run assembled verification, curate learning, perform safe cleanup, and issue one delivery report.
```

- [ ] **Step 5: Reconcile the shared worktree principle**

Replace the paragraph under `## Worktrees` in `templates/agents/_common-principles.md` with:

```markdown
Every mutating implementation assignment uses its own worker branch and worktree. Commit verified results there, return the commit SHA, and wait for Gatekeeper approval before Nexus integrates it. Read-only roles do not create worktrees unnecessarily. The only planning-artifact exception is an approved PRD that The Fixer commits by itself on the current named branch after design and artifact approval; the exception never includes implementation or unrelated files.
```

- [ ] **Step 6: Run routing and agent contract tests**

Run:

```bash
bash tests/protocol_contract_test.bash
bash tests/agent_contract_test.bash
```

Expected: both commands pass. The workflow, Nexus, and shared principles agree on the same narrow exception and handoff markers.

- [ ] **Step 7: Commit the canonical routing contract**

```bash
git add templates/.cyberpunk/workflow.md templates/agents/nexus.md templates/agents/_common-principles.md tests/protocol_contract_test.bash
git diff --cached --check
git commit -m "feat: route product discovery through Fixer"
```

### Task 3: Distribute and validate The Fixer through the CLI

**Files:**

- Modify: `cyberpunk:7-32`
- Modify: `tests/cli_test.bash:32-83`
- Modify: `tests/integration_test.bash:26-51,76-89`

**Interfaces:**

- Consumes: template paths `agents/fixer.md` and `skills/core/requirements-discovery/SKILL.md` from Task 1.
- Produces: CLI version `0.3.0`, required-file validation for both paths, generated counts `Agents: 11` and `Core skills: 16`, and a scaffold whose Fixer default skill resolves.

- [ ] **Step 1: Extend CLI generation, preservation, validation, count, and version tests**

In the complete-team initialization test, add:

```bash
assert_file "$project/agents/fixer.md"
assert_file "$project/skills/core/requirements-discovery/SKILL.md"
```

In the ordinary-init preservation test, add markers before `init` and assertions after it:

```bash
echo "fixer-user-marker" >> "$project/agents/fixer.md"
echo "discovery-user-marker" >> "$project/skills/core/requirements-discovery/SKILL.md"
assert_exit 0 run_cli "$project" init
assert_contains "$(<"$project/agents/fixer.md")" "fixer-user-marker"
assert_contains "$(<"$project/skills/core/requirements-discovery/SKILL.md")" "discovery-user-marker"
```

In the force-refresh test, add:

```bash
assert_not_contains "$(<"$project/agents/fixer.md")" "fixer-user-marker"
assert_not_contains "$(<"$project/skills/core/requirements-discovery/SKILL.md")" "discovery-user-marker"
```

Add two missing-required-file tests after the existing canonical-file test:

```bash
test_start "validate identifies a missing Fixer persona"
rm "$project/agents/fixer.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "agents/fixer.md"
assert_exit 0 run_cli "$project" init --force

test_start "validate identifies a missing requirements-discovery skill"
rm "$project/skills/core/requirements-discovery/SKILL.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "skills/core/requirements-discovery/SKILL.md"
assert_exit 0 run_cli "$project" init --force
```

Change the expected status counts and version:

```bash
assert_contains "$COMMAND_OUTPUT" "Agents: 11"
assert_contains "$COMMAND_OUTPUT" "Core skills: 16"

assert_contains "$COMMAND_OUTPUT" "0.3.0"
```

- [ ] **Step 2: Add generated-project integration assertions**

In the fresh-project test, add:

```bash
assert_file "$project/agents/fixer.md"
assert_file "$project/skills/core/requirements-discovery/SKILL.md"
```

After the default-skill resolution test, add:

```bash
test_start "generated Fixer exposes the committed PRD handoff"
fixer_contract="$(<"$project/agents/fixer.md")$(<"$project/skills/core/requirements-discovery/SKILL.md")$(<"$project/.cyberpunk/workflow.md")"
for value in \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "discovery_complete: true" \
    "user_authorized_handoff: true"; do
    assert_contains "$fixer_contract" "$value" "generated Fixer handoff"
done
```

- [ ] **Step 3: Run CLI and integration tests and verify required-file validation is missing**

Run:

```bash
bash tests/cli_test.bash
bash tests/integration_test.bash
```

Expected: `cli_test.bash` fails because validation does not yet require the new paths and status/version still report `10`, `15`, and `0.2.0`; the integration test may pass template-copy assertions because `init` already copies the whole template tree, but its handoff contract depends on Tasks 1 and 2.

- [ ] **Step 4: Update the CLI manifest and version**

Change:

```bash
VERSION="0.3.0"
```

Add the Fixer persona beside Nexus and the discovery skill beside the existing required skill:

```bash
    "agents/nexus.md"
    "agents/fixer.md"
```

```bash
    "skills/core/requirements-discovery/SKILL.md"
    "skills/core/worktree-isolation/SKILL.md"
```

No copy logic change is needed: `copy_template_tree` already discovers every template recursively. The manifest change makes both new paths mandatory during `validate`.

- [ ] **Step 5: Run CLI, integration, and smoke tests**

Run:

```bash
bash tests/cli_test.bash
bash tests/integration_test.bash
bash tests/smoke_test.bash
```

Expected: all three commands pass; a fresh scaffold reports 11 agents, 16 core skills, and CLI version 0.3.0.

- [ ] **Step 6: Commit CLI distribution and validation**

```bash
git add cyberpunk tests/cli_test.bash tests/integration_test.bash
git diff --cached --check
git commit -m "feat: distribute and validate Fixer templates"
```

### Task 4: Document The Fixer and close only its todo item

**Files:**

- Modify: `README.md:7-78,104-123`
- Modify: `templates/README.md:12-21`
- Modify: `tests/documentation_contract_test.bash:26-43`
- Modify: `todo.md:1-3`

**Interfaces:**

- Consumes: the finalized persona, skill, routing, path, count, and handoff vocabulary from Tasks 1-3.
- Produces: public documentation for direct Fixer invocation and Nexus routing; a three-entry checklist with only the Fixer complete.

- [ ] **Step 1: Write the failing public documentation contract**

Rename the README test to `README documents discovery and autonomous integration-branch flow`, replace `10 specialized roles` with `11 specialized roles`, and add these values to its assertion loop:

```bash
    "The Fixer" \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "asks whether to hand" \
```

- [ ] **Step 2: Run the documentation contract and verify the README is stale**

Run:

```bash
bash tests/documentation_contract_test.bash
```

Expected: FAIL because the README still says `10 specialized roles` and does not document The Fixer flow.

- [ ] **Step 3: Add the user-facing discovery flow to the root README**

After the Nexus quick-start example, add:

````markdown
For a new product, feature, or architectural idea whose requirements still need discovery, invoke The Fixer directly:

```text
Act as The Fixer. Help me define account recovery before implementation planning.
```

Nexus also routes materially incomplete product work to The Fixer. The Fixer uses `requirements-discovery`, asks one focused question at a time, and writes an approved PRD to `specs/YYYY-MM-DD-<topic>-prd.md`. After the user reviews the file, The Fixer commits only that PRD on the current named branch and asks whether to hand it to Nexus.
````

Before the quick/standard/complex list under Adaptive Workflow, add:

```markdown
Product discovery precedes engineering classification when a new product, feature, or architectural request still lacks material requirements. Routine fixes, sufficiently specified work, and approved PRDs continue directly through Nexus.
```

Change the team count to 11 and add this role after Nexus:

```markdown
- **The Fixer:** product requirements broker for collaborative discovery, approved PRD commits, and explicit Nexus handoff
```

Replace the first paragraph under `## Skills` with:

```markdown
Roles describe ownership; skills describe reusable methods. Core skills cover requirements discovery, task classification, repository discovery, planning, plan review, decomposition, worktree isolation, scoped implementation, test-first development, debugging, backend safety, frontend quality, infrastructure safety, code review, verification, and memory curation.
```

Add this paragraph after the worktree lifecycle:

```markdown
Approved PRD authoring is the sole planning-artifact exception: The Fixer may commit only the reviewed PRD on the current named branch before offering handoff. Implementation assignments still use worker branches and worktrees.
```

- [ ] **Step 4: Update generated-template documentation**

Replace the relevant Main Areas bullets in `templates/README.md` with:

```markdown
- `agents/` — role contracts, including The Fixer for product discovery and The Nexus for engineering delivery
- `skills/core/` — portable framework skills, including `requirements-discovery`
- `skills/project/` — explicitly enabled project skills
- `specs/`, `plans/`, and `tasks/` — durable artifacts; Fixer PRDs use `specs/YYYY-MM-DD-<topic>-prd.md`
```

- [ ] **Step 5: Mark only The Fixer complete in `todo.md`**

Make the complete file exactly:

```markdown
- [x] Add the PRD creator (cyberpunk persona). Should behave like superpowers brainstorming skill. Either use that or make a custom one. The goal is to interact with the user and build requirements which nexus can use.
- [ ] Ability to work across different repositories. Most of the times we have projects that are scattered across different repositories, for example backend, frontend, infrastructure etc... The cyberpunk should be able to work across these and maintain the memory web and how these projects are related.
- [ ] https://github.com/obra/superpowers#codex-cli Lets think of handling multiple ai tools like codex, claude code, cursor etc like superpowers does, in a plugin way. Check if it is possible with our current approach.
```

This preserves the user's previously uncommitted third item and records both deferred projects as open.

- [ ] **Step 6: Run documentation and full regression verification**

Run:

```bash
bash tests/documentation_contract_test.bash
bash tests/run.sh
git diff --check
```

Expected: the documentation contract passes, all seven test files pass, and `git diff --check` reports no whitespace errors.

- [ ] **Step 7: Review the assembled acceptance contract**

Run:

```bash
rg -n "The Fixer|requirements-discovery|discovery_complete: true|user_authorized_handoff: true|specs/YYYY-MM-DD-<topic>-prd.md" README.md templates cyberpunk tests
git status --short
```

Expected: every required term appears in the persona, skill, canonical workflow, generated-project coverage, and public documentation. Only the Task 4 documentation, test, and todo files are uncommitted at this point.

- [ ] **Step 8: Commit documentation and todo closure**

```bash
git add README.md templates/README.md tests/documentation_contract_test.bash todo.md
git diff --cached --check
git diff --cached -- todo.md
git commit -m "docs: document Fixer PRD workflow"
```

Before committing, verify the staged `todo.md` diff marks only the first item complete and preserves both unchecked follow-up items.

## Final Verification

After all four task commits exist, run:

```bash
bash tests/run.sh
git status --short
git log -4 --oneline
```

Expected:

- All seven test files pass.
- The implementation worktree is clean.
- The four most recent implementation commits correspond to persona/skill, routing, CLI distribution, and documentation.
- No push, pull request, deployment, protected-branch merge, or unrelated cleanup has occurred.
