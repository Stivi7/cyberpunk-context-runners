# Skill: Risk Assessment

## PURPOSE
Systematically identify, analyze, and document technical risks to enable informed decision-making and proactive mitigation planning.

## WHEN TO USE
- Before committing to technical decisions
- During architecture and planning phases
- When evaluating third-party dependencies
- Before major technology changes

## INPUTS
- `technical_plan` (required) - Plan, design, or architecture to assess
- `risk_categories` (optional) - Specific areas to focus on: [security, scalability, complexity, dependencies, performance]

## RISK CATEGORIES

### 1. Technical Implementation Risks
Risks related to building and maintaining the solution.

**Examples:**
- Unproven technology or framework
- Complex integration requirements
- Resource/skill gaps in team
- Technical debt accumulation

**Assessment Questions:**
- Has this technology been used in production before?
- Does the team have experience with this stack?
- Are there clear integration patterns documented?

### 2. Scalability Risks
Risks related to handling growth in users, data, or traffic.

**Examples:**
- Database bottleneck at scale
- Lambda concurrency limits
- API Gateway throttling
- Data retention cost explosion

**Assessment Questions:**
- What happens at 10x current scale?
- Are there hard limits in any service?
- What's the cost curve as we scale?

### 3. Dependency Risks
Risks related to external services, teams, or vendors.

**Examples:**
- Third-party API availability
- Vendor lock-in
- Cross-team coordination
- Open source maintenance

**Assessment Questions:**
- What if this service goes down?
- Can we migrate away if needed?
- What's the SLA and support level?

### 4. Security Risks
Risks related to data protection and system security.

**Examples:**
- Data exposure vulnerabilities
- Authentication/authorization gaps
- Compliance violations (GDPR, HIPAA, etc.)
- Supply chain attacks

**Assessment Questions:**
- What data is sensitive?
- Who has access to what?
- Are we compliant with regulations?

### 5. Operational Risks
Risks related to running and monitoring the system.

**Examples:**
- Lack of observability
- Difficult deployment process
- Complex rollback procedures
- Alert fatigue

**Assessment Questions:**
- Can we detect when things go wrong?
- How long to recover from failure?
- How complex is the deployment?

## RISK SEVERITY MATRIX

Assess each risk on two dimensions:

| Probability \ Impact | Low | Medium | High |
|---------------------|-----|--------|------|
| **High** | Medium | High | Critical |
| **Medium** | Low | Medium | High |
| **Low** | Low | Low | Medium |

### Severity Definitions

**Critical (P0)**
- System failure or data loss likely
- Immediate action required
- Blocks release

**High (P1)**
- Significant impact on functionality or security
- Mitigation needed before release
- Contingency plan required

**Medium (P2)**
- Moderate impact, manageable
- Mitigation can be post-release
- Monitor closely

**Low (P3)**
- Minimal impact
- Accept or monitor
- Document for awareness

## MITIGATION STRATEGIES

### Avoid
Eliminate the risk by changing approach:
- Use proven technology instead of experimental
- Simplify architecture to remove complexity
- Remove unnecessary features

### Transfer
Shift risk to another party:
- Use managed services (AWS handles scaling)
- Insurance or warranties
- Contracts with SLA penalties

### Mitigate
Reduce probability or impact:
- Add redundancy
- Implement circuit breakers
- Increase testing coverage
- Document runbooks

### Accept
Acknowledge and monitor:
- Low probability AND low impact
- Cost of mitigation exceeds risk
- Document in risk register

## OUTPUT

### Risk Register

```markdown
## Risk Register

| ID | Risk | Category | Probability | Impact | Severity | Mitigation | Owner |
|----|------|----------|-------------|--------|----------|------------|-------|
| R1 | [Description] | [Category] | High/Med/Low | High/Med/Low | Critical/High/Med/Low | [Strategy] | [Role] |

## Critical Risks (P0)
- **R1**: [Risk description]
  - Impact: [What happens]
  - Mitigation: [What we'll do]
  - Fallback: [If mitigation fails]

## High Risks (P1)
...

## Assumptions Requiring Validation
- [Assumption]: [How we'll validate]
```

## BEST PRACTICES

1. **Assess Early**: Identify risks during design, not after implementation
2. **Be Specific**: Vague risks can't be mitigated ("something might break" → "DynamoDB hot partition at 1000 WCU")
3. **Revisit Regularly**: Risks change as system evolves
4. **Assign Owners**: Someone must be responsible for monitoring each risk
5. **Document Assumptions**: Every assumption is a potential risk
