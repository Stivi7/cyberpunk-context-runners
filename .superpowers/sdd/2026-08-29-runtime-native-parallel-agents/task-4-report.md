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

## Fix Round 1

### Review findings addressed

1. Enabled project skills now accept only simple identifiers
   (`[A-Za-z0-9][A-Za-z0-9_-]*`) before canonical path construction. This
   prevents traversal and path fragments from resolving outside
   `skills/project`.
2. Canonical frontmatter now requires exactly one `name:` and `description:`
   with whitespace after the colon and a genuine single-line string scalar.
   The parser rejects block, collection, alias, tag, comment-sensitive,
   boolean, numeric, malformed-quote, and control-character forms. Quoted
   scalar values are decoded and safely re-rendered as YAML strings; safe plain
   values retain the canonical plain form.
3. Disabled project skills now retire their prior native wrapper files and
   manifest entries transactionally. Retirement uses the generated-asset
   transaction's ownership, drift, `--force`, atomic claim, rollback, and
   manifest-commit protections. Unowned wrappers without a manifest record are
   untouched.

### RED evidence

Before the production fix, a real temporary project with
`enabled_project: [../escape]` and a crafted `skills/escape/SKILL.md` produced:

```text
RED_STATUS=0
TRAVERSAL_WRAPPER_CREATED=true
```

This demonstrated that the old implementation resolved a configured project
skill outside `skills/project` and generated a native wrapper.

### GREEN and verification evidence

- The same traversal fixture after the fix produced:

  ```text
  GREEN_STATUS=1
  [ERROR] Invalid enabled project skill identifier: ../escape
  ```

- A real Codex-only project enabled then disabled `release-policy`; after
  `sync`, its wrapper and manifest source record were gone:

  ```text
  RETIREMENT_GREEN=true
  ```

- `bash tests/skill_contract_test.bash` passed.
- `bash -n cyberpunk lib/config.bash lib/generated-assets.bash`
  and syntax checks for the three edited test files passed.
- `git diff --check` passed.
- The new runtime contracts cover force-preservation of the canonical project
  source, disable lifecycle including drift and unowned wrappers, inline and
  block project lists with deterministic lexical ordering, traversal, and
  malformed scalar frontmatter.

The requested integration/runtime/full-suite invocation was attempted once.
The integration suite reached its existing generated-Cursor-drift section
without an assertion failure before the environment's 30-second hard cutoff.
One targeted runtime retry reached the new disabled-project-skill lifecycle
section, likewise without an assertion failure or exit status. Per the user
constraint, no further harness retries were made.

### Fix Round 1 files changed

- `cyberpunk`
- `lib/generated-assets.bash`
- `tests/runtime_adapter_test.bash`
- `.superpowers/sdd/2026-08-29-runtime-native-parallel-agents/task-4-report.md`

### Fix Round 1 concern

The only unresolved concern remains the local harness cutoff; it prevents a
complete result from the long runtime, integration, and aggregate suites. No
assertion failure was observed before either cutoff.
