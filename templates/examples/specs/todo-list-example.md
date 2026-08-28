# Shared Todo List — Example Specification

This example demonstrates a proportional, runtime-neutral specification. The Operator discovers the target project's stack and verification commands before implementation.

## Objective

Allow a signed-in user to create, view, complete, and reopen personal todo items so unfinished work remains visible across sessions.

## Scope

### Included

- Create a todo with a required title.
- List the current user's todos.
- Mark a todo complete or incomplete.
- Persist state using the project's established data patterns.
- Present loading, empty, error, and populated states when a user interface is in scope.

### Excluded

- Shared lists, assignments, notifications, recurring tasks, and file attachments.
- New deployment infrastructure unless the existing project requires a scoped configuration change.
- Changes to authentication beyond using the current user identity.

## Acceptance Criteria

1. A valid title creates one todo owned by the current user.
2. Blank or invalid titles are rejected using established project error conventions.
3. Users cannot read or change another user's todos.
4. Completion can be toggled without losing the original title.
5. Refreshing or restarting through the project's normal lifecycle preserves saved state.
6. Existing behavior outside the todo feature remains unchanged.

## Interface Contract

Mind must define the shared data shape, validation rules, ownership semantics, and error states before Daemon and Neon work independently. The exact transport and storage mechanisms follow repository conventions.

## Verification Categories

- `format_check` when available
- `lint` when available
- `static_analysis` when available
- `unit_test` for validation and state transitions
- `integration_test` for ownership and persistence boundaries
- `build` when the affected project defines it
- Accessible interaction and browser evidence when a user interface is included

Operator resolves these categories to real project commands. Unavailable categories are reported rather than invented.

## Risks

- Incorrect ownership filtering could expose another user's data.
- Concurrent updates could overwrite newer state if the project requires conflict handling.
- Frontend and backend validation could diverge without one shared contract.

## Delivery

Nexus resolves the integration branch, gives every mutating work unit an isolated worker branch and worktree, requires Gatekeeper approval, merges in dependency order, runs assembled verification, and returns the final branch and evidence without pushing or opening a pull request by default.
