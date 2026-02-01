# Skill: User Story Writing

## PURPOSE
Write clear, actionable user stories with acceptance criteria that align development work with user needs and business value.

## WHEN TO USE
- Breaking epics into stories
- Defining requirements
- Creating backlog items
- Sprint planning

## INPUTS
- `feature_description` (required) - Feature to implement
- `user_type` (required) - Target user persona
- `value_proposition` (required) - Business value delivered

## STORY FORMAT

### Standard Template
```
As a [type of user],
I want [some goal],
So that [some reason/benefit].
```

### Example
```
As a registered user,
I want to reset my password via email,
So that I can regain access to my account if I forget my password.
```

## ACCEPTANCE CRITERIA

### Given/When/Then Format
```gherkin
Given [precondition]
When [action]
Then [expected result]
```

### Example
```gherkin
Given a user with email "user@example.com" exists
When they click "Forgot Password" and submit their email
Then they receive a password reset email within 5 minutes
And the email contains a secure, time-limited reset link
And the link expires after 24 hours
```

## DEFINITION OF DONE

- [ ] Code implemented
- [ ] Unit tests passing (95%+ coverage)
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] QA validated
- [ ] No critical bugs

## STORY QUALITY CHECKLIST

- [ ] Independent: Can be developed separately
- [ ] Negotiable: Details can be discussed
- [ ] Valuable: Delivers business value
- [ ] Estimable: Team can estimate effort
- [ ] Small: Fits in a sprint (ideally 3-5 days)
- [ ] Testable: Has clear acceptance criteria

## OUTPUT

```markdown
## Story: [Title]
**As a** [user]
**I want** [feature]
**So that** [benefit]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Definition of Done
- [ ] [Item 1]

## Notes
- [Technical notes]
- [Dependencies]
- [Open questions]
```
