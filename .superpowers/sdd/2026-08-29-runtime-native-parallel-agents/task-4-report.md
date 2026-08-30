# Task 4 implementation report

## Scope

Registered strict, runtime-native skill wrappers for all canonical core skills
and explicitly enabled project skills. The implementation calls the existing
transactional `write_generated_asset` writer for all three runtime roots.

## RED evidence

Before production changes, ran:

```bash
bash tests/runtime_adapter_test.bash
```

It failed at the new real temporary-project contract as expected:

```text
TEST: all enabled runtimes receive thin wrappers for every canonical core skill
FAIL: codex native core skill count (expected '16', got '0')
```

The failure named the intended missing behavior: no Codex native core-skill
wrappers existed.

## GREEN and verification evidence

- `bash -n cyberpunk`
- `bash -n lib/config.bash`
- `bash -n lib/generated-assets.bash`
- `bash -n tests/runtime_adapter_test.bash`
- `bash -n tests/skill_contract_test.bash`
- `bash -n tests/integration_test.bash`
- `git diff --check`
- `bash tests/skill_contract_test.bash` passed (`PASS: skill contract tests`).
- A real temporary-project `cyberpunk init` created 48 wrappers across the
  three native roots, and `.cyberpunk/generated.yml` recorded 48 `skill`
  assets. The inspected wrapper had canonical `name` and `description`, a
  `../../../skills/core/.../SKILL.md` pointer, and no copied procedure body.

The requested longer-running commands were started once, with one targeted
local-environment retry:

```bash
bash tests/runtime_adapter_test.bash
bash tests/integration_test.bash
bash tests/run.sh
```

This environment terminates test processes at about 30 seconds without an
exit code or assertion message. The runtime suite reached the new matrix,
enabled-project, validation, and collision/drift test sections before that
cutoff; the integration suite reached its existing generated-manifest section.
No product assertion failed. Per the user constraint, no further harness
retries were made.

## Self-review

- Discovery reads only `skills/core/*/SKILL.md` plus the configured project
  list, sorts project identifiers lexically, checks exactly one frontmatter
  name/description pair, rejects missing project files, duplicate identifiers,
  and directory/name drift before opening the generated-manifest transaction.
- All wrappers are thin relative pointers, preserve canonical metadata, and
  contain no canonical procedure content.
- Codex, Claude, and Cursor destinations are distinct and use the existing
  manifest writer, preserving Task 3 collision, drift, force, rollback, and
  manifest transaction behavior.
- Tests cover the core matrix, enabled-only project skills, missing/mismatched
  and colliding identifiers, unowned collisions, owned drift, and force
  replacement through real CLI temporary projects.

## Files changed

- `cyberpunk`
- `lib/config.bash`
- `tests/runtime_adapter_test.bash`
- `tests/skill_contract_test.bash`
- `tests/integration_test.bash`
- `.superpowers/sdd/2026-08-29-runtime-native-parallel-agents/task-4-report.md`

## Concerns

The only unresolved concern is the local execution harness's approximately
30-second hard cutoff for the requested long Bash suites. It prevented a
complete suite exit status, not a test assertion. Run the three commands above
in a normal terminal before integration if that host does not have the cutoff.
