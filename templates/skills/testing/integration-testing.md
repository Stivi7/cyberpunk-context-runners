# Skill: Integration Testing

## PURPOSE
Design integration tests that verify external service interactions, API contracts, and data layer integrations in isolation from production systems.

## WHEN TO USE
- Testing database integrations
- Testing API client interactions
- Testing message queue handlers
- Verifying service contracts

## INPUTS
- `integration_point` (required) - External service to test (DB, API, Queue)
- `test_scopes` (optional) - Test boundaries: [happy-path, errors, edge-cases]
- `mock_strategy` (optional) - LocalStack, testcontainers, or mocks

## INTEGRATION TEST STRATEGIES

### Database Integration
```typescript
// Test with real DynamoDB (LocalStack)
describe('UserRepository', () => {
  beforeAll(async () => {
    // Start LocalStack or connect to test table
    await setupTestTable();
  });
  
  afterEach(async () => {
    await cleanupTable();
  });
  
  it('persists and retrieves user', async () => {
    const user = { id: '123', name: 'Alice' };
    
    await repository.save(user);
    const retrieved = await repository.findById('123');
    
    expect(retrieved).toEqual(user);
  });
});
```

### API Integration
```typescript
describe('PaymentAPI', () => {
  it('processes payment successfully', async () => {
    nock('https://api.payment.com')
      .post('/charges', { amount: 100, currency: 'USD' })
      .reply(200, { id: 'charge_123', status: 'succeeded' });
    
    const result = await paymentApi.charge({ amount: 100 });
    
    expect(result.status).toBe('succeeded');
  });
});
```

## TEST BOUNDARIES

| Type | Scope | Tools |
|------|-------|-------|
| In-memory | Fast, no I/O | Mock implementations |
| Testcontainers | Real services in Docker | LocalStack, Postgres container |
| Staging | Real services, isolated data | Staging environment |

## OUTPUT

```markdown
## Integration: [Service]
- **Type**: [Database/API/Queue]
- **Strategy**: [Mock/Testcontainer/Staging]

## Test Scenarios
| Scenario | Setup | Verification |
|----------|-------|--------------|
| Happy path | [Setup] | [Expected result] |
| Timeout | [Delay mock] | [Error handling] |
| Error response | [Error mock] | [Recovery] |
```
