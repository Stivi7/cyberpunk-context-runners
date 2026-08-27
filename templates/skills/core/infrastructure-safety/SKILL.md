---
name: infrastructure-safety
description: Use when work changes infrastructure, delivery automation, permissions, observability, environments, or operational configuration.
---

# Infrastructure Safety

## Metadata

- Version: 1.0.0
- Triggers: Platform, automation, environment, or operational change
- Allowed agents: Grid Master, Gatekeeper
- Side effects: May change local infrastructure definitions; external mutation requires approval

## When to Use

Use for operational changes. Do not assume a provider or execute an external mutation without authority.

## Inputs

Work packet, environments, state model, permission boundaries, deployment process, rollback expectations, and project commands.

## Procedure

1. Identify blast radius, state ownership, credentials, dependencies, and affected environments.
2. Apply least privilege and avoid embedding secrets.
3. Define rollback and failure detection before rollout.
4. Prefer static validation and non-mutating previews.
5. Separate local code completion from external execution requiring approval.

## Verification

Confirm syntax, plan or preview evidence, permission impact, rollback, observability, and external actions not performed.

## Output

Resource changes, environments, permission impact, validation, rollback, observability, approvals needed, and residual risk.
