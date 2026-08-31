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
