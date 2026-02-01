# Skill: Test Coverage Analysis

## PURPOSE
Analyze test coverage reports to identify gaps, ensure 95%+ coverage targets, and prioritize testing efforts.

## WHEN TO USE
- Reviewing test suites
- Meeting coverage thresholds
- Identifying untested code paths
- Prioritizing test additions

## INPUTS
- `coverage_report` (required) - Coverage data (JSON/HTML)
- `threshold` (optional) - Minimum acceptable coverage (default: 95%)
- `exclusions` (optional) - Patterns to exclude from analysis

## COVERAGE METRICS

| Metric | Target | Description |
|--------|--------|-------------|
| Statements | 95% | Lines of code executed |
| Branches | 95% | Decision paths taken |
| Functions | 100% | Functions called |
| Lines | 95% | Individual lines |

## GAP ANALYSIS

### Reading Coverage Reports
```json
{
  "total": {
    "statements": { "covered": 95, "total": 100, "pct": 95 },
    "branches": { "covered": 18, "total": 20, "pct": 90 },
    "functions": { "covered": 10, "total": 10, "pct": 100 }
  },
  "files": {
    "src/utils.ts": {
      "statements": { "pct": 80 },
      "uncovered": [12, 15, 18]
    }
  }
}
```

### Identifying Priorities
1. **Critical paths first**: Core business logic
2. **Branch coverage gaps**: Missing else/edge cases
3. **Complex functions**: High cyclomatic complexity
4. **Recently changed**: New code with low coverage

## OUTPUT

```markdown
## Coverage Summary
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Statements | 94% | 95% | ❌ |

## Gaps Identified
| File | Line | Issue | Priority |
|------|------|-------|----------|
| utils.ts | 45 | Missing error branch | High |

## Recommendations
- Add tests for error handling in utils.ts
- Focus on branch coverage in validation.ts
```
