# Task 5 report — native runtime registration validation

## Inherited partial-work audit

Audited against base `bf563b9` before modifying the handoff:

- `cyberpunk`: already added generated-manifest expectation checks, managed-block checks, status fields, and an initial recorded-run validator. The validator used non-schema field names, searched only `run.yml`, carried mutable scopes across separate runs, and did not bind job-level review/evidence fields from the approved run-state schema.
- `lib/config.bash`: already added execution-policy parsing and validation, runtime duplicate/unknown checks, required role/profile checks, and fallback validation. No Task 3 transaction code was changed.
- `lib/generated-assets.bash`: already added duplicate `(runtime, kind, identifier)` detection, runtime/path/extension checks, source-existence checks, and stale-hash reporting. This work was preserved.
- `tests/cli_test.bash`: already added healthy runtime validation/status coverage plus invalid maximum and missing-agent coverage.
- `tests/runtime_validation_test.bash`: existed untracked with the healthy status and basic drift cases; it was retained and extended with binding recorded-run cases.

## Completed behavior

- Status renders configured runtimes as `codex, claude, cursor` portably; BSD `paste -sd ', '` cycles delimiters and was replaced with explicit joining.
- Invalid configuration causes status policy values to report `unknown` and generated state to report `drift detected`; status remains read-only.
- Validation requires expected agents, canonical skills, managed instruction blocks, manifest record consistency, sources, native paths, and hashes without writing.
- Recorded `state.yml` (and legacy `run.yml`) validation rejects:
  - `max_concurrent_agents` outside `1..3`;
  - identical `allowed_scope` values held by different `parallel_safe: true` jobs in one run;
  - `review_status: approved` without a non-null fresh `review_agent_instance` when `fallback.used` is not true;
  - parallel execution/delivery claims without a recorded native agent.

## Evidence

- RED: the focused runtime validation test initially failed its required runtime line because BSD `paste -sd ', '` emits `codex,claude cursor` rather than `codex, claude, cursor`.
- Green controlled run-ledger fixture: a valid native parallel state returned zero. Adding a second `parallel_safe` job with `allowed_scope: [src/shared/**]` returned one and emitted:
  `Recorded parallel-safe jobs overlap mutable scope: src/shared/** (.cyberpunk/runs/overlap/run.yml)`.
- Syntax and diff checks completed successfully after the final edits:
  `/bin/bash -n cyberpunk lib/config.bash lib/generated-assets.bash tests/cli_test.bash tests/runtime_validation_test.bash`
  and `git diff --check bf563b9`.
- The attempted long focused `tests/runtime_validation_test.bash` run reached its first initialized-fixture test but was cut off by the local execution sandbox. A targeted retry had the same cutoff; the sandbox also intermittently removed standard command paths (`mkdir`, `cat`, and `dirname`) from later fixture commands. No production workaround was added for that external issue.
- Bounded one-shot checks then reached these cutoffs without a pass/fail result: `tests/cli_test.bash` reached `init copies the complete team and local-state structure`; `tests/runtime_adapter_test.bash` reached `all enabled runtimes receive the complete native agent matrix`; `tests/integration_test.bash` reached `fresh project initializes and validates`; `tests/run.sh` first completed agent-contract tests and then reached the CLI fixture initialization. Per the task limit, none was retried.

## Self-review

- Validation and status only read project state; no validator calls synchronization or writes a manifest.
- No live runtime or model-capability claim was added.
- The run-state parser keeps scope comparison inside one recorded run and accepts both inline and block `allowed_scope` lists.
- The change is Bash 3.2 compatible: indexed arrays and process substitution already used by the project are retained; no associative arrays, `mapfile`, or Bash 4 case conversion were introduced.
- Scope is restricted to Task 5 implementation/tests/report; no plan, ledger, `todo.md`, canonical protocol, or Task 3 generated-asset transactions were edited.
