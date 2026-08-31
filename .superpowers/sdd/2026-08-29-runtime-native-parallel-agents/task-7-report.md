# Task 7 Verification Report

## RED

- `bash tests/documentation_contract_test.bash` initially failed because the runtime-native setup commands and generated-path documentation were absent.
- The first required persistent `bash tests/run.sh` run reached `tests/cli_test.bash` and failed on an outdated assertion. The validator emitted `Missing generated asset: .codex/agents/nexus.toml`; the test expected `Missing expected generated asset: .codex/agents/nexus.toml`.

## GREEN

- The documentation, version, and opt-in smoke-matrix contracts were added before the public documentation and version change.
- The permitted one-line CLI assertion alignment was made to the stable, evidence-bearing validator diagnostic.
- `bash tests/documentation_contract_test.bash` passed after the documentation changes.
- `bash tests/smoke_test.bash` passed after the version bump and optional-smoke guard.

## Exact Final Verification

- Automated test-file count: 10 (`tests/*_test.bash`).
- The final persistent `bash tests/run.sh` run passed `agent_contract_test.bash`, `cli_test.bash`, and `documentation_contract_test.bash`.
- The same final run then failed in `integration_test.bash`: `FAIL: generated Nexus nested delegation boundary (missing 'Never ask a subagent to create sibling or nested Cyberpunk agents')`.
- No vendor runtime or paid model was invoked by these checks.
- Because the full suite was not green, the model-routing line in `todo.md` is intentionally unchanged and no second full-suite run was started.

## Fix Round 1

- RED: `integration_test.bash` required the generated Nexus prohibition to contain `Never ask a subagent to create sibling or nested Cyberpunk agents` contiguously, while `render_native_agent_body` split that exact sentence across two lines.
- GREEN: the smallest renderer change keeps the sentence on one line; one persistent `bash tests/integration_test.bash` run passed.
- Final suite: one persistent `bash tests/run.sh` run passed agent, CLI, documentation, integration, protocol, and the initial runtime-adapter cases. It then exited during the runtime-adapter project-skill normalization case after emitting `awk: newline in string` for a newline-containing fixture value.
- The model-routing todo remains unchanged because that final full suite did not pass. No additional full-suite retry was started.

## Fix Round 2

- RED: `runtime_adapter_test.bash` passed a multiline block-list replacement through `awk -v replacement=...`; BSD awk rejected it with `awk: newline in string` before the CLI ran.
- GREEN: the test helper now writes the replacement bytes to a temporary file, lets awk read that file, and removes it on both success and failure. `bash -n tests/runtime_adapter_test.bash` and one persistent `bash tests/runtime_adapter_test.bash` run passed.
- Remaining-suite gate: `runtime_skill_metadata_byte_test.bash` passed, then `runtime_validation_test.bash` failed on its still-stale expected diagnostic `Missing expected generated asset: .codex/agents/nexus.toml`. The actual stable diagnostic is `Missing generated asset: .codex/agents/nexus.toml`.
- The bounded run stopped there; `skill_contract_test.bash` and `smoke_test.bash` were not rerun. The model-routing todo remains unchanged.

## Fix Round 3

- RED: `runtime_validation_test.bash` contained the sole remaining stale assertion for `Missing expected generated asset: .codex/agents/nexus.toml` while the validator stably emits `Missing generated asset: .codex/agents/nexus.toml`.
- GREEN: the one assertion was aligned. One persistent run each of `runtime_validation_test.bash`, `skill_contract_test.bash`, and `smoke_test.bash` passed.
- Combined with the fresh green agent, CLI, documentation, integration, protocol, runtime-adapter, and runtime-skill-metadata evidence from this bounded sequence, all 10 automated test files have fresh passing evidence without a full-suite restart.
- The model-routing todo line was added exactly once after that evidence gate.
