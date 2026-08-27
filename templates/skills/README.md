# Agent Skills

Skills define reusable methods; agents define ownership. Agents inspect skill descriptions first and load the full `SKILL.md` only when its trigger applies.

- `core/` contains framework-owned skills and may be refreshed by an explicit framework update.
- `project/` contains user-owned skills and is never overwritten or deleted by initialization.
- Project skills must be explicitly enabled in `.cyberpunk/config.yml`.
- A project skill cannot silently shadow a core skill name.

Instruction precedence is: user authority, project policy, work packet, role contract, then selected skill. A learned lesson may recommend a skill change, but skill changes require review and validation.
