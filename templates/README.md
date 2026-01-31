# Cyberpunk Templates

This directory contains immutable templates for the Cyberpunk CLI scaffolding tool.

## Important Notes

- **Templates are immutable** and must not be modified by the CLI
- Users should edit generated files in their projects, not these templates
- The CLI only reads from this directory and copies content to target projects
- No token substitution is performed - templates are copied exactly as-is

## Structure

- `agents/` - Agent definition files with roles, inputs, and outputs
- `examples/` - Example documents and use cases (copied verbatim)
- `PRPs/` - Product Requirement Prompt templates
- `plans/` - Planning document templates
- `skills/` - Specialized context snippets for specific technical tasks
- `tasks/` - Task definition templates
- `.cursor/rules/rules.mdc` - Cursor IDE rules (copied verbatim)

### Skills Directory

The `skills/` directory contains focused, reusable context for specific technical domains:

- **Purpose**: Provide concise, actionable guidance for common infrastructure and coding patterns
- **Scope**: Each skill covers one specific technology or pattern (e.g., Lambda, API Gateway, DynamoDB)
- **Format**: Consistent structure with inputs, configuration examples, and best practices
- **Usage**: Reference these when implementing or reviewing code in the specific domain

Skills are designed to be quick reference guides that ensure consistent, minimal, and well-configured implementations.

## Usage

These templates are used by the `cyberpunk init` command to scaffold new projects with the standard cyberpunk agent structure.
