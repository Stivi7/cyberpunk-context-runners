---
name: backend-safety
description: Use when backend work affects APIs, domain invariants, persistence, migrations, authorization, concurrency, or compatibility.
---

# Backend Safety

## Metadata

- Version: 1.0.0
- Triggers: Backend behavior or data-boundary change
- Allowed agents: Daemon, Gatekeeper
- Side effects: May change services, schemas, migrations, or contracts

## When to Use

Use for backend work beyond mechanical documentation. Apply only checks relevant to the affected boundary.

## Inputs

Work packet, interface contract, domain invariants, data model, compatibility requirements, and project verification commands.

## Procedure

1. Identify trust boundaries, invariants, validation, authorization, and failure semantics.
2. Preserve compatibility or document the approved migration path.
3. Make data changes reversible where practical and protect partial-failure paths.
4. Consider concurrency, idempotency, and resource limits when relevant.
5. Test success and meaningful failure paths at the lowest useful layer.

## Verification

Confirm contract behavior, data integrity, access control, migration safety, and relevant integration evidence.

## Output

Affected contracts and data, safeguards applied, compatibility notes, verification, and residual backend risks.
