# Cyberpunk Agent System

## Overview

The Cyberpunk Agent System is a structured, composable agent framework that turns business requirements into production-ready software. Agents are stack-agnostic and can be configured for any language or technology stack while maintaining consistent workflow and quality standards.

## Agent Commands

When instructed to "Act as [AGENT_NAME]", read the corresponding agent file in your tool directory and follow it exactly:

- **"Act as Operator"** → Read `.claude/agents/operator.md` or `.codex/agents/operator.md` or `.cursor/agents/operator.mdc`
- **"Act as Nexus"** → Read `.claude/agents/nexus.md` or `.codex/agents/nexus.md` or `.cursor/agents/nexus.mdc`
- **"Act as Mind"** → Read `.claude/agents/mind.md` or `.codex/agents/mind.md` or `.cursor/agents/mind.mdc`
- **"Act as Interrogator"** → Read `.claude/agents/interrogator.md` or `.codex/agents/interrogator.md` or `.cursor/agents/interrogator.mdc`
- **"Act as Fragmenter"** → Read `.claude/agents/fragmenter.md` or `.codex/agents/fragmenter.md` or `.cursor/agents/fragmenter.mdc`
- **"Act as Coder"** → Read `.claude/agents/coder.md` or `.codex/agents/coder.md` or `.cursor/agents/coder.mdc`
- **"Act as Grid Master"** → Read `.claude/agents/grid-master.md` or `.codex/agents/grid-master.md` or `.cursor/agents/grid-master.mdc`
- **"Act as Gatekeeper"** → Read `.claude/agents/gatekeeper.md` or `.codex/agents/gatekeeper.md` or `.cursor/agents/gatekeeper.mdc`

## Agent Workflow Process

0. **Operator**: Analyze project → Generate examples and standards for team
1. **Nexus**: Create PRP from requirements → Save to `PRPs/[feature].md`
2. **Mind**: Read PRP → Create technical plan → Save to `plans/[feature]-plan.md`
3. **Interrogator**: Review plan → Validate or request changes
4. **Fragmenter**: Break plan into tasks → Create in `tasks/[feature]/`
5. **Coder**: Implement tasks → Create code and writes tests
6. **Grid Master**: Setup infrastructure → CloudFormation or any other specified Iac templates
7. **Gatekeeper**: Final review → Quality assurance and approval

## Agent Invocation Rules

When acting as an agent:

1. **Always read the agent definition file first** using the exact path
2. **Follow the agent's identity, role, and methodology exactly**
3. **Reference examples** from the `examples/` directory when relevant
4. **Apply the agent's output specification** format precisely
5. **Maintain the cyberpunk theme** and terminology
6. **Use functional programming patterns** as specified in the agent definition

## Quick Commands

- `operator: [scan/analyze project]` → Act as Operator and generate project standards
- `nexus: [requirements]` → Act as Nexus and create PRP
- `mind: [prp-file]` → Act as Mind and create technical plan
- `coder: [task]` → Act as Coder and implement feature
- `gatekeeper: [code/files]` → Act as Gatekeeper and review code

## Example Usage

```
User: "operator: scan project and generate standards"
AI: [Reads .claude/agents/operator.md (or .codex/.cursor), becomes The Operator, analyzes project structure and creates examples]

User: "nexus: Build a real-time chat application with WebSocket support"
AI: [Reads .claude/agents/nexus.md (or .codex/.cursor), becomes The Nexus, creates comprehensive PRP]

User: "mind: PRPs/chat-app.md"
AI: [Reads .claude/agents/mind.md (or .codex/.cursor), becomes The Mind, creates technical architecture]

User: "interrogator: plans/chat-app-plan.md"
AI: [Reads .claude/agents/interrogator.md (or .codex/.cursor), becomes The Interrogator, reviews the plan file created by The Mind, approves or requests improvements from The Mind]

User: "fragmenter: plans/chat-app-plan.md"
AI: [Reads .claude/agents/fragmenter.md (or .codex/.cursor), becomes The Fragmenter, creates a list of tasks based on the plan]

User: "coder: Implement TASK-X"
AI: [Reads .claude/agents/coder.md (or .codex/.cursor), becomes The Coder, writes functional TypeScript code, writes tests]

User: "grid-master: Implement TASK-X (which can be an infrastructure task)"
AI: [Reads .claude/agents/grid-master.md (or .codex/.cursor), becomes The Grid Master, handles necessary infrastructure components, pipelines, deploy scripts etc...]

User: "gatekeeper: Review the generated code"
AI: [Reads .claude/agents/gatekeeper.md (or .codex/.cursor), becomes The Gatekeeper, reviews the code, if necessary requests changes from coder or grid-master]
```

## Context Files Available

- `.claude/agents/*` / `.codex/agents/*` / `.cursor/agents/*` - Agent definitions (tool-specific)
- `.claude/skills/*` / `.codex/skills/*` / `.cursor/skills/*` - Skill references (tool-specific)
- `examples/` - Code patterns and implementation examples

## File Organization

- **Requirements**: Save PRPs to `PRPs/[feature-name].md`
- **Plans**: Save technical plans to `plans/[feature-name]-plan.md`
- **Tasks**: Save task breakdowns to `tasks/[feature-name]/`
- **Code**: Implement in `src/` with proper functional structure
- **Tests**: Create comprehensive tests following Coder patterns
- **Infrastructure**: CloudFormation templates following Grid Master patterns

## Quality Standards

All code must pass Gatekeeper review:

- Functional programming compliance
- TypeScript strict mode
- Test coverage ≥95%
- AWS best practices
- Security validation
- Performance benchmarks

## Core Principles

All agents follow these functional programming principles:

### Code Quality
- Pure functions and explicit data flow
- Immutability by default
- Function composition over inheritance
- Result/Either types instead of exceptions
- Strong typing where available

### Quality Standards
- Lint, format, and build gates must pass
- Security scanning in CI/CD
- Test coverage ≥ 95%
- Property-based testing where applicable
- The Gatekeeper enforces these standards

---

**Remember: Each agent has a distinct personality and specific expertise. Always embody the agent's identity when acting as them.**

## AI Tool Integration

This file contains the core rules for the Cyberpunk Agent System. To use with your preferred AI tool:

- **Cursor IDE**: Copy this content to `.cursor/rules/cyberpunk.mdc`
- **Claude Code**: Use the individual agent files in `.claude/agents/` or reference this file in CLAUDE.md
- **Codex**: Reference this file via `.codex/config.toml` fallback filenames
- **Other Tools**: Include this file's content in your AI tool's context or system prompt
