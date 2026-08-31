# Optional Live Runtime Smoke Matrix

This manual, opt-in, account-dependent, usage-consuming matrix consumes model usage. It is not part of `tests/run.sh`, must not be run by automated checks, and requires an account with the selected runtime available. Record observations in the fixture's local run state and delivery report; do not infer them from configuration.

Use an isolated disposable fixture for each runtime. The same seven observations apply in every section: native delegation may be unavailable, and that outcome is evidence for recorded sequential fallback rather than a failed automated test.

## Codex

1. Initialize a Codex-only fixture with `cyberpunk init --runtime codex`.
2. Start Codex normally and give Nexus four independent packets with distinct safe scopes.
3. Observe three native subagents active and one queued packet; the queue waits rather than becoming fallback.
4. Confirm mutating worktree/branch isolation, including recorded worker branch, base, and allowed scope.
5. Confirm a fresh Gatekeeper identity reviews each result before integration and a fresh identity reviews the assembled change.
6. Disable or block native delegation, then confirm the local run state records sequential fallback and its observed reason.
7. Configure an unavailable preferred model, then confirm exactly one `inherit` retry and record preferred, effective, and fallback evidence.

## Claude Code

1. Initialize a Claude Code-only fixture with `cyberpunk init --runtime claude`.
2. Start Claude Code normally and give Nexus four independent packets with distinct safe scopes.
3. Observe three native subagents active and one queued packet; the queue waits rather than becoming fallback.
4. Confirm mutating worktree/branch isolation, including recorded worker branch, base, and allowed scope.
5. Confirm a fresh Gatekeeper identity reviews each result before integration and a fresh identity reviews the assembled change.
6. Disable or block native delegation, then confirm the local run state records sequential fallback and its observed reason.
7. Configure an unavailable preferred model, then confirm exactly one `inherit` retry and record preferred, effective, and fallback evidence.

## Cursor

1. Initialize a Cursor-only fixture with `cyberpunk init --runtime cursor`.
2. Start Cursor normally and give Nexus four independent packets with distinct safe scopes.
3. Observe three native subagents active and one queued packet; the queue waits rather than becoming fallback.
4. Confirm mutating worktree/branch isolation, including recorded worker branch, base, and allowed scope.
5. Confirm a fresh Gatekeeper identity reviews each result before integration and a fresh identity reviews the assembled change.
6. Disable or block native delegation, then confirm the local run state records sequential fallback and its observed reason.
7. Configure an unavailable preferred model, then confirm exactly one `inherit` retry and record preferred, effective, and fallback evidence.

## Record the Result

Record the active runtime, native-agent identities, execution mode, queue waits, worktree and branch evidence, Gatekeeper identities, preferred and effective models, `inherit` retry evidence, fallback category, verification, result commits, and integration result. A configured registration or `cyberpunk status` output does not prove live capability.
