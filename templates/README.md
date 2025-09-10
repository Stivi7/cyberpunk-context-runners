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
- `tasks/` - Task definition templates
- `.cursor/rules/rules.mdc` - Cursor IDE rules (copied verbatim)

## Usage

These templates are used by the `cyberpunk init` command to scaffold new projects with the standard cyberpunk agent structure.
