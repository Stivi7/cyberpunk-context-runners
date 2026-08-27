---
name: systematic-debugging
description: Use when a test fails, behavior is unexpected, or an implementation attempt does not address the observed problem.
---

# Systematic Debugging

## Metadata

- Version: 1.0.0
- Triggers: Bug, failing check, unexplained output, or repeated review finding
- Allowed agents: Operator, Daemon, Neon, Grid Master, Gatekeeper
- Side effects: May add diagnostics, tests, or implementation changes

## When to Use

Use before proposing a fix. Do not repeat an unchanged attempt without a changed hypothesis.

## Inputs

Observed failure, reproduction, relevant code, recent diff, environment, baseline evidence, and prior attempts.

## Procedure

1. Reproduce and preserve the exact failure.
2. Separate regression, baseline failure, environment issue, and incorrect expectation.
3. Trace data and control flow to the earliest incorrect state.
4. Form one falsifiable root-cause hypothesis.
5. Add the smallest test or diagnostic that distinguishes the hypothesis.
6. Change the root cause, then rerun focused and broader verification.
7. After repeated failure, discard the hypothesis and re-diagnose.

## Verification

The reproduction must fail before the fix, pass after it, and leave related verification green.

## Output

Root cause, evidence, regression test, change, verification results, and rejected hypotheses.
