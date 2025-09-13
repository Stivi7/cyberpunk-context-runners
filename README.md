# Cyberpunk Context Runners — Agent System & CLI

A structured, composable agent system that turns business requirements into production‑ready software. The agents are stack‑agnostic and can be configured for any language or technology stack while maintaining consistent workflow and quality standards.

## Quick Start

### 1. Install the CLI

```bash
# Clone the repository
git clone https://github.com/Stivi7/cyberpunk-context-runners.git
cd cyberpunk-context-runners

# Install the cyberpunk command (single command setup)
echo "export PATH=\"$(pwd):\$PATH\"" >> ~/.zshrc && source ~/.zshrc

# Verify installation:
cyberpunk --version
```

### 2. Scaffold Your Project

```bash
# Navigate to your project directory
cd /path/to/your/project

# Initialize cyberpunk structure
cyberpunk init
```

This creates:
```
your-project/
├── agents/              # Agent definitions
├── examples/            # Usage examples
├── PRPs/                # Product Requirement Prompts
├── plans/               # Technical plans
├── tasks/               # Task breakdowns
└── .cursor/rules/       # Cursor IDE rules
```

## CLI Usage

```bash
cyberpunk init [OPTIONS]
```

### Options
- `--dry-run`     Preview what will be created without making changes
- `--force`       Overwrite existing files without prompting
- `--help`        Show help message
- `--version`     Show version information

### Examples

```bash
# Basic initialization
cyberpunk init

# Preview what will be created
cyberpunk init --dry-run

# Force overwrite existing files
cyberpunk init --force
```

## The Agent System

The cyberpunk agent system consists of 7 specialized agents that work together to transform business requirements into production-ready code:

### 🔄 **Core Workflow Agents**
- **The Operator** — Analyzes existing projects and generates customized examples and standards
- **The Nexus** — Creates Product Requirement Prompts (PRPs) from business needs
- **The Mind** — Designs technical architecture and phased implementation plans
- **The Interrogator** — Reviews and validates plans for completeness and risk
- **The Fragmenter** — Breaks plans into executable epics, stories, and tasks

### ⚙️ **Implementation Agents**
- **The Coder** — Implements code using functional programming principles
- **The Gatekeeper** — Reviews code quality and enforces standards
- **The Grid Master** — Manages infrastructure and deployment pipelines

### Agent Workflow

```mermaid
graph LR
    A[Business Need] --> B[Nexus]
    B --> C[Mind]
    C --> D[Interrogator]
    D --> E[Fragmenter]
    E --> F[Coder]
    F --> G[Gatekeeper]
    F --> H[Grid Master]
    G --> I[Production]
    H --> I
```

0. **Operator** → Project analysis → generates examples and standards
1. **Nexus** → Creates PRP → save to `PRPs/[feature].md`
2. **Mind** → Technical plan → save to `plans/[feature]-plan.md`
3. **Interrogator** → Validates plan → approves or requests changes
4. **Fragmenter** → Task breakdown → save to `tasks/[feature]/`
5. **Coder** → Implements code + tests
6. **Grid Master** → Infrastructure & deployment
7. **Gatekeeper** → Final review & approval

## Agent Invocation

After scaffolding with `cyberpunk init`, use these commands in your AI editor (e.g., Cursor):

### Quick Commands
- `operator: [scan/analyze project]` → Analyze project and generate standards
- `nexus: [requirements]` → Create Product Requirement Prompt
- `mind: [prp-file]` → Create technical plan from PRP
- `interrogator: [plan-file]` → Review and validate plan
- `fragmenter: [plan-file]` → Break plan into executable tasks
- `coder: [task]` → Implement feature with tests
- `grid-master: [infrastructure-task]` → Handle DevOps and infrastructure
- `gatekeeper: [code/files]` → Review code quality and approve

### Full Command Format
- **"Act as Operator"** → Read `agents/operator.md` → Analyze project and generate examples/standards
- **"Act as Nexus"** → Read `agents/nexus.md` → Create Product Requirement Prompts
- **"Act as Mind"** → Read `agents/mind.md` → Generate technical plans and architecture
- **"Act as Interrogator"** → Read `agents/interrogator.md` → Review and validate plans
- **"Act as Fragmenter"** → Read `agents/fragmenter.md` → Break plans into tasks
- **"Act as Coder"** → Read `agents/coder.md` → Implement features with functional patterns
- **"Act as Grid Master"** → Read `agents/grid-master.md` → Handle infrastructure and DevOps
- **"Act as Gatekeeper"** → Read `agents/gatekeeper.md` → Review code quality and approve

### Example Workflow

```
# Step 0: Analyze project (initial setup)
User: "operator: scan project and generate standards"
AI: [Becomes The Operator, analyzes project structure and creates examples]

# Step 1: Create requirements
User: "nexus: Build a real-time chat application with WebSocket support"
AI: [Becomes The Nexus, creates comprehensive PRP]

# Step 2: Design architecture  
User: "mind: PRPs/chat-app.md"
AI: [Becomes The Mind, creates technical architecture]

# Step 3: Review plan
User: "interrogator: plans/chat-app-plan.md"
AI: [Becomes The Interrogator, reviews plan and provides feedback]

# Step 4: Break into tasks
User: "fragmenter: plans/chat-app-plan.md"
AI: [Becomes The Fragmenter, creates detailed task breakdown]

# Step 5: Implement features
User: "coder: Implement WebSocket connection handler"
AI: [Becomes The Coder, writes functional TypeScript code and tests]

# Step 6: Infrastructure
User: "grid-master: Setup AWS infrastructure for chat app"
AI: [Becomes The Grid Master, creates CloudFormation templates]

# Step 7: Final review
User: "gatekeeper: Review the chat application code"
AI: [Becomes The Gatekeeper, performs quality review]
```

## Project-Specific Setup

After running `cyberpunk init`, the agents are ready to use with their default configuration. For project-specific customization:

### Use The Operator (Recommended)
The system includes The Operator agent that can analyze your project and generate language-specific examples:

```
User: "operator: scan project and generate standards"
# or
User: "Act as Operator" → analyze current project structure and generate customized examples
```

This will:
- Detect your project's language and framework
- Generate relevant code examples in the `examples/` directory
- Customize agent references for your specific stack
- Set up appropriate testing and infrastructure patterns

### Manual Customization
You can also manually edit the agent files in `agents/` to:
- Update technology references (e.g., specify React instead of generic frontend)
- Add project-specific quality standards
- Include custom infrastructure patterns
- Reference your preferred testing frameworks

## Core Principles

All agents follow these functional programming principles:

### 📝 **Code Quality**
- Pure functions and explicit data flow
- Immutability by default
- Function composition over inheritance
- Result/Either types instead of exceptions
- Strong typing where available

### 🔍 **Quality Standards**
- Lint, format, and build gates must pass
- Security scanning in CI/CD
- Test coverage ≥ 95%
- Property-based testing where applicable
- The Gatekeeper enforces these standards

### 📋 **File Organization**
```
project/
├── PRPs/[feature-name].md           # Product requirements
├── plans/[feature-name]-plan.md     # Technical plans
├── tasks/[feature-name]/            # Task breakdowns
├── agents/*.md                      # Agent definitions
└── examples/                        # Examples and references
```

## Advanced Usage

### Cursor IDE Integration
The system includes Cursor IDE rules in `.cursor/rules/rules.mdc` that configures the agent behaviour and how to address them in the cursor chat.

## Troubleshooting

### Common Issues

**"Templates directory not found"**
- Ensure you're running the script from the cyberpunk-context-runners directory
- Or use the full path: `/path/to/cyberpunk-context-runners/cyberpunk init`

**"Permission denied"**
- Make sure the script is executable: `chmod +x cyberpunk`
- Or run with bash: `bash cyberpunk init`

**"Command not found"**
- Check that the directory is in your PATH: `echo $PATH`
- Try using the full path to the script
- Restart your terminal after modifying PATH

## Contributing

When adding or modifying agents:
1. Maintain the cyberpunk naming/theme
2. Keep structured inputs/outputs in each agent file
3. Include validation criteria and interaction patterns
4. Provide example usage or references
5. Preserve functional programming principles
6. Update templates and test the CLI

## License

See [LICENSE](LICENSE) for details.

---

**Ready to build the future? 🤖✨**

`cyberpunk init` and let the agents guide your development journey.
