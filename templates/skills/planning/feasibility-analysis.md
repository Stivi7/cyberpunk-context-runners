# Skill: Feasibility Analysis

## PURPOSE
Assess whether a proposed technical solution can be successfully implemented given constraints around time, resources, technology, and complexity.

## WHEN TO USE
- Reviewing architecture proposals
- Evaluating new technology adoption
- Estimating implementation complexity
- Making go/no-go decisions on features

## INPUTS
- `proposal` (required) - Technical proposal or plan to evaluate
- `constraints` (optional) - Time, budget, team capacity limitations
- `alternatives` (optional) - Alternative approaches to compare

## FEASIBILITY DIMENSIONS

### 1. Technical Feasibility
Can we build this with available technology?

**Assessment Criteria:**
- Technology maturity and stability
- Integration complexity
- Performance requirements achievability
- Scalability limits

**Red Flags:**
- Technology in alpha/beta stage
- No production precedent
- Requires significant R&D
- Performance requirements exceed known limits

**Green Flags:**
- Well-established technology
- Team has prior experience
- Clear integration patterns exist
- Proof of concept succeeded

### 2. Resource Feasibility
Do we have the people and skills needed?

**Assessment Criteria:**
- Required skill sets vs. team capabilities
- Learning curve for new technologies
- Availability of key personnel
- Need for external expertise

**Red Flags:**
- Critical skill gaps in team
- Key person dependencies
- Hiring market is tight for required skills
- Training time exceeds project timeline

**Green Flags:**
- Team has relevant experience
- Skills are transferable
- Strong documentation and community support
- External expertise available if needed

### 3. Time Feasibility
Can we deliver within required timeline?

**Assessment Criteria:**
- Estimated effort vs. available time
- Critical path analysis
- Parallelization opportunities
- Buffer for unknowns

**Estimation Approach:**
```
Base Estimate
+ Complexity Factor (1.5x for high complexity)
+ Learning Curve (20% for new tech)
+ Integration Uncertainty (30% for unknown integrations)
+ Buffer (20% for unknown unknowns)
= Realistic Timeline
```

**Red Flags:**
- Timeline < 50% of base estimate
- Critical path has no buffer
- Dependencies on external timelines
- Parallel work has high coordination cost

### 4. Economic Feasibility
Does the cost make sense?

**Assessment Criteria:**
- Development cost vs. value delivered
- Operational cost at scale
- Infrastructure costs (AWS services)
- Maintenance burden

**Cost Categories:**
- **Development**: Person-hours, training, tooling
- **Infrastructure**: Compute, storage, data transfer
- **Operational**: Monitoring, alerts, on-call
- **Maintenance**: Bug fixes, updates, refactoring

## COMPLEXITY ASSESSMENT

Rate complexity on a 1-5 scale for each dimension:

| Dimension | 1 (Simple) | 3 (Moderate) | 5 (Complex) |
|-----------|------------|--------------|-------------|
| **Architecture** | Single Lambda | Multi-service | Distributed system |
| **Data** | Single table | Multiple tables | Complex relationships |
| **Integration** | 0-1 external APIs | 2-3 APIs | 4+ APIs or custom protocols |
| **Logic** | CRUD operations | Business rules | ML/algorithmic complexity |
| **Scale** | < 1000 users/day | 1000-100k/day | > 100k/day or global |

**Complexity Score**: Sum of all dimensions (5-25)
- 5-10: Low complexity
- 11-17: Moderate complexity
- 18-25: High complexity

## ALTERNATIVE ANALYSIS

When evaluating alternatives, compare:

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| Implementation Time | | | |
| Operational Complexity | | | |
| Scalability | | | |
| Team Familiarity | | | |
| Cost (Dev + Ops) | | | |
| Risk Level | | | |
| **Total Score** | | | |

## OUTPUT

### Feasibility Report

```markdown
## Feasibility Assessment

### Executive Summary
- **Status**: [feasible / at-risk / not-feasible]
- **Complexity Score**: [X/25]
- **Confidence**: [high / medium / low]

### Technical Feasibility
- **Status**: [feasible/at-risk/not-feasible]
- **Key Concerns**: [List concerns]
- **Mitigation**: [How to address]

### Resource Feasibility
- **Status**: [feasible/at-risk/not-feasible]
- **Skill Gaps**: [What skills are missing]
- **Training Needed**: [Time/cost to upskill]

### Time Feasibility
- **Status**: [feasible/at-risk/not-feasible]
- **Estimated Effort**: [person-weeks]
- **Critical Path**: [Key milestones]
- **Buffer**: [% contingency]

### Economic Feasibility
- **Development Cost**: [estimate]
- **Monthly Operational Cost**: [at target scale]
- **ROI Timeline**: [when value exceeds cost]

### Alternatives Considered
1. **[Alternative A]**: [Why accepted/rejected]
2. **[Alternative B]**: [Why accepted/rejected]

### Recommendations
- [Specific, actionable recommendations]
- [Go/no-go recommendation with rationale]
```

## DECISION FRAMEWORK

### Go Criteria (All must be true)
- [ ] Technical approach is proven
- [ ] Team has or can acquire necessary skills
- [ ] Timeline is achievable with buffer
- [ ] Cost is justified by value
- [ ] Major risks have mitigation plans

### No-Go Triggers (Any one is sufficient)
- [ ] Technology is unproven in production
- [ ] Critical skill gap with no resolution path
- [ ] Timeline is < 50% of realistic estimate
- [ ] Cost exceeds available budget
- [ ] High-severity risks without mitigation

### At-Risk Conditions
- Proceed with caution and mitigation plans if:
  - One feasibility dimension is marginal
  - New technology with learning curve
  - Tight timeline but clear scope
  - External dependencies with uncertainty
