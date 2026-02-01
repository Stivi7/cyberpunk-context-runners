# Skill: Code Review Checklist

## PURPOSE
Perform systematic code reviews ensuring functional correctness, type safety, test quality, security, and performance standards.

## WHEN TO USE
- Reviewing code submissions
- Enforcing standards
- Gatekeeping merges
- Mentoring team members

## INPUTS
- `code_diff` (required) - Code to review (PR diff)
- `standards` (optional) - Project-specific standards
- `checklist_focus` (optional) - Areas to prioritize

## REVIEW CATEGORIES

### 1. Functional Correctness
- [ ] Logic matches requirements
- [ ] Edge cases handled
- [ ] Error paths covered
- [ ] No obvious bugs or race conditions

### 2. Type Safety
- [ ] Types are precise (no `any`)
- [ ] Return types declared
- [ ] Generic constraints used appropriately
- [ ] Null/undefined handled

### 3. Tests
- [ ] 95%+ coverage maintained
- [ ] Edge cases tested
- [ ] Error paths tested
- [ ] Tests are readable and maintainable

### 4. Security
- [ ] No hardcoded secrets
- [ ] Input validated
- [ ] Output encoded
- [ ] Proper auth checks

### 5. Performance
- [ ] No N+1 queries
- [ ] No unnecessary computations
- [ ] Memory leaks considered
- [ ] Async patterns correct

### 6. Maintainability
- [ ] Functions are focused
- [ ] Naming is clear
- [ ] Comments explain why, not what
- [ ] Complexity is reasonable

## REVIEW OUTPUT

```markdown
## Review Summary
- **Status**: [approved / changes_requested]
- **Risk Level**: [low/medium/high]

### Findings
| Category | Severity | Issue | Location |
|----------|----------|-------|----------|
| Security | High | Missing input validation | line 45 |

### Required Changes
1. [ ] Add validation for user input
2. [ ] Add test for error case

### Suggestions (Optional)
- Consider extracting helper function
```
