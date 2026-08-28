---
name: verification-before-delivery
description: Use when a worker or integration branch is about to be claimed complete, correct, or ready to deliver.
---

# Verification Before Delivery

## Metadata

- Version: 1.0.0
- Triggers: Completion, approval, integration, or delivery claim
- Allowed agents: Nexus, Gatekeeper
- Side effects: Runs project commands and may block delivery

## When to Use

Use at the last responsible moment. Prior results do not replace fresh verification after relevant changes or merges.

## Inputs

Acceptance criteria, current branch and commit, changed scope, command registry, baseline failures, review state, and integration state.

## Procedure

1. Confirm the branch, commit, diff, and merge state being claimed.
2. Select relevant discovered project commands based on affected areas and risk.
3. Run them freshly and inspect exit status plus meaningful output.
4. Confirm acceptance criteria and required reviews.
5. Record unavailable checks, pre-existing failures, and residual risk without disguising them as success.
6. Make only the claim supported by current evidence.

## Verification

Evidence must identify commands, observed results, branch, commit, and time relative to the final change.

## Output

Delivery status, acceptance results, fresh verification, omitted checks, baseline failures, branch, commit, and remaining risks.
