# Skill: Unit Testing Patterns

## PURPOSE
Write effective unit tests for pure functions with proper structure, coverage, and mocking strategies following functional programming principles.

## WHEN TO USE
- Writing tests for pure functions
- Testing business logic
- Creating testable code structures
- Ensuring 95%+ coverage target

## INPUTS
- `function_signature` (required) - Function to test
- `test_framework` (optional) - Jest, Vitest, pytest (default: Jest)
- `coverage_target` (optional) - Target coverage percentage (default: 95%)

## TEST STRUCTURE

### AAA Pattern
```typescript
// Arrange - Set up test data
const input = { name: 'Alice', age: 30 };

// Act - Execute function
const result = processUser(input);

// Assert - Verify results
expect(result.isOk()).toBe(true);
expect(result.value.fullName).toBe('Alice');
```

### Test File Organization
```typescript
describe('processUser', () => {
  describe('happy path', () => {
    it('should process valid user', () => {});
  });
  
  describe('edge cases', () => {
    it('should handle empty name', () => {});
    it('should handle negative age', () => {});
  });
  
  describe('error cases', () => {
    it('should return error for null input', () => {});
  });
});
```

## PURE FUNCTION TESTING

### Testing Business Logic
```typescript
// Function under test
const calculateTotal = (
  items: Item[],
  discountCode?: string
): Result<number, Error> => {
  if (items.length === 0) {
    return err(new Error('No items'));
  }
  
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const discount = discountCode === 'SAVE10' ? subtotal * 0.1 : 0;
  
  return ok(subtotal - discount);
};

// Tests
describe('calculateTotal', () => {
  it('calculates total for multiple items', () => {
    const items = [
      { price: 10, quantity: 2 },
      { price: 5, quantity: 1 }
    ];
    
    const result = calculateTotal(items);
    
    expect(result.isOk()).toBe(true);
    expect(result.value).toBe(25);
  });
  
  it('applies discount code', () => {
    const items = [{ price: 100, quantity: 1 }];
    
    const result = calculateTotal(items, 'SAVE10');
    
    expect(result.value).toBe(90);
  });
  
  it('returns error for empty items', () => {
    const result = calculateTotal([]);
    
    expect(result.isErr()).toBe(true);
    expect(result.error.message).toBe('No items');
  });
});
```

## MOCKING STRATEGIES

### Mock External Dependencies
```typescript
// Repository pattern allows mocking
const createUserService = (deps: { db: DbClient; logger: Logger }) => {
  return {
    async createUser(data: UserData): Promise<Result<User, Error>> {
      deps.logger.info('Creating user', { email: data.email });
      
      const existing = await deps.db.findByEmail(data.email);
      if (existing) {
        return err(new Error('Email exists'));
      }
      
      return await deps.db.create(data);
    }
  };
};

// Test with mocks
describe('createUser', () => {
  it('creates new user', async () => {
    const mockDb = {
      findByEmail: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue(ok({ id: '123', ... }))
    };
    const mockLogger = { info: jest.fn() };
    
    const service = createUserService({ db: mockDb, logger: mockLogger });
    const result = await service.createUser({ email: 'test@test.com' });
    
    expect(result.isOk()).toBe(true);
    expect(mockDb.create).toHaveBeenCalledWith({ email: 'test@test.com' });
  });
});
```

## COVERAGE TARGETS

| Metric | Target | Minimum |
|--------|--------|---------|
| Statements | 95% | 90% |
| Branches | 95% | 90% |
| Functions | 100% | 95% |
| Lines | 95% | 90% |

## OUTPUT

### Test Plan
```markdown
## Function: [name]
- **Purpose**: [what it does]
- **Pure**: [Yes/No]

## Test Cases
| Case | Input | Expected Output |
|------|-------|-----------------|
| Happy path | [input] | [output] |
| Empty input | [] | Error |

## Coverage
- [ ] All branches tested
- [ ] Error paths tested
- [ ] Edge cases covered
```
