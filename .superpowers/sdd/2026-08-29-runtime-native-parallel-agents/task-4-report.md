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

## Fix Round 2

### Review findings addressed

1. Project skills now undergo physical path resolution before discovery. Both
   a symlinked skill directory and a symlinked `SKILL.md` that resolve outside
   the physical `skills/project` root are rejected before the manifest starts.
2. Native wrapper `name` and `description` are always serialized as escaped
   double-quoted YAML strings. The strict parser accepts safe plain text or
   correctly escaped quoted strings, rejects ambiguous YAML scalar forms, and
   decodes/re-encodes `\"` and `\\` without changing the logical value.
3. Retirement now reconciles the desired native-skill destination set before
   mutation. An obsolete project ownership record is not retired when a
   current core or project skill will generate the same destination; the normal
   generated-asset writer then atomically replaces that record and file.

### RED evidence

The new runtime contract initially failed against the prior implementation:

```text
TEST: all enabled runtimes receive thin wrappers for every canonical core skill
FAIL: codex backend-safety wrapper name (missing 'name: "backend-safety"')
```

This proved the former wrapper metadata was not unconditionally YAML-string
serialized. The same test additions also cover the previously missing physical
symlink and project-to-core takeover behaviors.

### GREEN and verification evidence

- A fresh Codex project rendered core wrapper descriptions as quoted strings:

  ```text
  CORE_SERIALIZATION_GREEN=1
  ```

- A real symlink-escape project returned status 1 with:

  ```text
  [ERROR] Enabled project skill resolves outside skills/project: symlink-policy
  ```

- A real quoted-description fixture round-tripped through the generated
  wrapper as `Release "quoted" from C:\workspace`, with serialized YAML:

  ```text
  description: "Release \"quoted\" from C:\\workspace"
  ```

- A real project-to-core takeover left the wrapper present and pointing at
  `../../../skills/core/release-policy/SKILL.md`, and the manifest recorded
  `skills/core/release-policy/SKILL.md` only.
- `bash -n cyberpunk`, `bash -n lib/generated-assets.bash`, and test syntax
  checks passed. `git diff --check` passed.
- `bash tests/skill_contract_test.bash` passed.

The one runtime-suite attempt reached the new disabled-project-skill lifecycle
section before the environment's 30-second process cutoff. The one
integration/full-suite attempt reached its existing generated-Cursor-drift
section after the passing skill suite, then hit the same cutoff. Neither emitted
an assertion failure or exit status; per the user constraint, no retry was
made.

### Fix Round 2 files changed

- `cyberpunk`
- `tests/runtime_adapter_test.bash`
- `.superpowers/sdd/2026-08-29-runtime-native-parallel-agents/task-4-report.md`

### Fix Round 2 concern

The only unresolved concern is the repeatable local test-harness cutoff. Run
the runtime, integration, and aggregate Bash commands in an unrestricted
terminal for complete exit-status evidence.

## Fix Round 3

### Finding addressed

Canonical skill metadata is now rejected if its decoded value contains any
control character. This prevents raw C0 bytes—including backspace, vertical
tab, form feed, escape, and the remaining control range—from reaching the
double-quoted YAML wrapper serializer. The behavior preserves exact string
semantics by rejecting unsafe input rather than silently dropping or changing
it.

### RED evidence

Before the parser hardening, a real project skill containing a raw vertical
tab in its quoted description produced:

```text
CONTROL_RED_STATUS=0
CONTROL_WRAPPER_CREATED=true
```

That demonstrated invalid YAML could be emitted from canonical metadata.

### GREEN and verification evidence

- A raw ESC description now fails before wrapper generation:

  ```text
  CONTROL_GREEN_STATUS=1
  [ERROR] Invalid canonical skill frontmatter: skills/project/release-policy/SKILL.md
  CONTROL_WRAPPER_ABSENT=true
  ```

- A deterministic real-CLI loop verified rejection of every C0 byte that can
  be represented in a Bash variable (`0x01..0x08`, `0x0B`, `0x0C`, and
  `0x0E..0x1F`):

  ```text
  ALL_REPRESENTABLE_C0_REJECTED=true
  ```

- A raw NUL metadata fixture also returned status 1 with the same invalid
  frontmatter error and emitted no wrapper.
- `bash tests/skill_contract_test.bash` passed.
- `bash -n cyberpunk`, `bash -n lib/config.bash`,
  `bash -n lib/generated-assets.bash`, and test syntax checks passed.
- `git diff --check` passed.

Per the narrow-scope instruction, the known long-cutoff runtime, integration,
and aggregate suites were not rerun.

### Fix Round 3 files changed

- `cyberpunk`
- `tests/runtime_adapter_test.bash`
- `.superpowers/sdd/2026-08-29-runtime-native-parallel-agents/task-4-report.md`

### Fix Round 3 concern

The existing local long-suite cutoff remains the only concern; it is unchanged
and was intentionally not retried for this focused parser correction.

## Fix Round 4

### Finding addressed

The former post-parse `[[:cntrl:]]` check was not a safe input boundary. Its
classification is locale-dependent, and Bash `read` cannot retain a NUL in a
line variable. A NUL or malformed byte outside the two fields the parser
consumes could therefore be ignored before the wrapper writer ran. The prior
name/value arrays also had different lengths, so their loop did not exercise
`0x1F`; they omitted DEL and valid UTF-8 representations of the C1 range.

Canonical `SKILL.md` files now receive a locale-independent byte preflight
before frontmatter is read. It decodes UTF-8 from `od`'s numeric byte stream
and accepts YAML 1.2 `c-printable`: TAB, LF, CR, printable ASCII, U+0085,
U+00A0--U+D7FF, U+E000--U+FFFD, and U+10000--U+10FFFF. It rejects the other
C0 controls, DEL, C1 except U+0085, invalid/overlong/truncated UTF-8,
surrogates, U+FFFE, and U+FFFF. The line parser now uses explicit ASCII space
and TAB handling rather than locale character classes and accepts CRLF input.

### RED evidence

With the focused byte regression added but before production changes, running
it against `46abe3e` failed as expected:

```text
TEST: canonical skill byte validation is locale-independent and follows YAML c-printable
FAIL: C rejected YAML-prohibited C0 byte 0x00 (expected '1', got '0')
```

The raw NUL fixture followed otherwise valid canonical frontmatter and the old
`sync` wrote a wrapper, proving the validation had happened too late.

### GREEN and verification evidence

The focused regression now passes in 17.6 seconds:

```text
TEST: sync rejects raw NUL, DEL, and prohibited C1 bytes before creating a wrapper
TEST: canonical skill byte validation is locale-independent and follows YAML c-printable
TEST: YAML-permitted UTF-8 metadata and CRLF frontmatter remain discoverable
PASS: runtime skill metadata byte tests
```

- The real CLI contract verifies that NUL, DEL, and U+0080 reject `sync`
  before the project-skill wrapper exists.
- Deterministic fixtures run under both `LC_ALL=C` and `LC_ALL=C.UTF-8`.
  They exhaustively cover all 30 YAML-prohibited ASCII bytes (including
  `0x1F` and DEL), all 31 prohibited C1 code points while preserving U+0085,
  malformed UTF-8, overlong forms, surrogates, U+FFFE/U+FFFF, and accepted
  TAB, NEL, non-breaking space, supplementary-plane UTF-8, and CRLF input.
- `bash -n cyberpunk`, `bash -n tests/runtime_adapter_test.bash`, and
  `bash -n tests/runtime_skill_metadata_byte_test.bash` passed.
- `bash tests/skill_contract_test.bash` passed (`PASS: skill contract tests`).
- `git diff --check` passed.

### Self-review

- The byte decoder has no locale-sensitive character classes: it consumes only
  decimal output from `LC_ALL=C od`, validates continuation structure and
  scalar range before any frontmatter bytes enter Bash variables, and makes no
  attempt to treat isolated C1 bytes as UTF-8 characters.
- The generated wrapper still receives only validated UTF-8 text. The NEL
  exception is specifically retained because YAML permits U+0085; the test
  exercises it separately from the rejected C1 loop.
- The incomplete parallel-array regression was removed from the long runtime
  adapter suite and replaced by the focused, independently runnable test file
  that the aggregate runner will discover by name.
- Mutating the preflight call, the DEL/C1 exclusions, or the U+0085 exception
  makes the focused integration or byte-table assertions fail.

### Fix Round 4 files changed

- `cyberpunk`
- `tests/runtime_adapter_test.bash`
- `tests/runtime_skill_metadata_byte_test.bash`
- `.superpowers/sdd/2026-08-29-runtime-native-parallel-agents/task-4-report.md`

### Fix Round 4 concern

Per the narrow-scope instruction, the known long-cutoff runtime, integration,
and aggregate suites were not rerun. The focused byte regression and skill
contract both have fresh, complete passing exit-status evidence.
