---
name: frontend-quality
description: Use when frontend work changes user interactions, visual states, accessibility, responsiveness, or browser-facing behavior.
---

# Frontend Quality

## Metadata

- Version: 1.0.0
- Triggers: User-interface or client behavior change
- Allowed agents: Neon, Gatekeeper
- Side effects: May change interface code, styles, assets, or browser tests

## When to Use

Use for user-facing behavior. Do not invent a redesign when the task supplies an existing system or reference.

## Inputs

Work packet, interface contract, design references, project components, supported environments, and verification commands.

## Procedure

1. Enumerate loading, empty, error, success, disabled, and permission states that apply.
2. Preserve accessible names, semantics, focus order, keyboard behavior, and readable contrast.
3. Reuse established components and responsive conventions.
4. Keep client state and server contracts explicit.
5. Verify behavior at relevant viewports and with the project's browser or visual tools when available.

## Verification

Confirm acceptance, interaction states, accessibility, responsive behavior, console health, and visual evidence appropriate to the change.

## Output

Affected flows, states covered, accessibility evidence, visual or browser evidence, omitted checks, and frontend risks.
