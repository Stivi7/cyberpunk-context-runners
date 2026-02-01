# Skill: Functional Programming

## PURPOSE
Apply functional programming principles to write declarative, composable, and side-effect-free code. Emphasize immutability, pure functions, and function composition for predictable, testable, and maintainable software.

## WHEN TO USE
- Refactoring imperative code to functional style
- Designing state management (Redux, Zustand, etc.)
- Writing data transformation pipelines
- Creating reusable, composable utilities
- Handling asynchronous operations functionally
- Implementing complex business logic with predictable outcomes
- Writing testable code without mocks for external state

## INPUTS
- language (optional) - Target language: `javascript`, `typescript`, `python`, `haskell`, `clojure`, `scala`
- paradigm_blend (optional) - `pure` for strict FP, `pragmatic` for mixed with imperative
- data_structures (optional) - Focus areas: `lists`, `maps`, `trees`, `streams`

---

## CORE PRINCIPLES

### 1. Pure Functions
Functions that given the same inputs, always return the same output without side effects.

```typescript
// Impure - side effect: mutates external state
let total = 0;
function addToTotal(amount: number): void {
  total += amount; // Side effect!
}

// Pure - no side effects, deterministic
function add(a: number, b: number): number {
  return a + b; // Same input → same output, always
}
```

**Benefits:**
- Referential transparency: function call can be replaced with its result
- Easier testing: no need for mocks or state setup
- Thread-safe: no shared mutable state
- Memoization-friendly: results can be cached

### 2. Immutability
Data cannot be modified after creation. Changes create new data structures.

```typescript
// Mutable - avoid
const numbers = [1, 2, 3];
numbers.push(4); // Mutates original

// Immutable - preferred
const numbers = [1, 2, 3];
const newNumbers = [...numbers, 4]; // Creates new array

// Immutable object updates
const user = { name: 'Alice', age: 30 };
const updatedUser = { ...user, age: 31 }; // New object, original unchanged
```

**Techniques by Language:**
- JavaScript/TypeScript: spread operator, `Object.freeze`, libraries (Immer, Immutable.js)
- Python: tuples, frozensets, dataclasses with frozen=True
- Haskell: all data is immutable by default

### 3. First-Class and Higher-Order Functions
Functions are values that can be passed as arguments, returned from functions, and assigned to variables.

```typescript
// Higher-order function: accepts function as argument
function filter<T>(array: T[], predicate: (item: T) => boolean): T[] {
  const result: T[] = [];
  for (const item of array) {
    if (predicate(item)) result.push(item);
  }
  return result;
}

// Higher-order function: returns function
function multiplyBy(factor: number): (n: number) => number {
  return (n: number) => n * factor;
}

const triple = multiplyBy(3);
triple(4); // 12
```

### 4. Function Composition
Building complex operations by combining simpler functions.

```typescript
// Right-to-left composition
const compose = <T>(...fns: Array<(arg: T) => T>) => 
  (value: T) => fns.reduceRight((acc, fn) => fn(acc), value);

// Left-to-right composition (pipe)
const pipe = <T>(...fns: Array<(arg: T) => T>) => 
  (value: T) => fns.reduce((acc, fn) => fn(acc), value);

// Usage
const transform = pipe(
  (x: number) => x * 2,
  (x: number) => x + 1,
  (x: number) => String(x)
);

transform(5); // "11" (5 * 2 + 1 = 11)
```

### 5. Currying and Partial Application
Transforming functions to accept one argument at a time.

```typescript
// Curried function
const add = (a: number) => (b: number) => a + b;

const addFive = add(5); // Partial application
addFive(3); // 8
add(5)(3);  // 8

// Practical currying with array methods
const map = <T, U>(fn: (x: T) => U) => (array: T[]): U[] => array.map(fn);
const filter = <T>(predicate: (x: T) => boolean) => (array: T[]): T[] => 
  array.filter(predicate);

const getNames = map((user: User) => user.name);
const getActive = filter((user: User) => user.isActive);

// Composable pipelines
const getActiveUserNames = pipe(getActive, getNames);
```

---

## FUNCTIONAL PATTERNS

### Declarative Data Transformations
Prefer declarative array methods over imperative loops.

```typescript
// Imperative - how to do it
const evenDoubles: number[] = [];
for (let i = 0; i < numbers.length; i++) {
  if (numbers[i] % 2 === 0) {
    evenDoubles.push(numbers[i] * 2);
  }
}

// Declarative - what to do
const evenDoubles = numbers
  .filter(n => n % 2 === 0)
  .map(n => n * 2);

// Complex pipeline with reduce
const totalScore = users
  .filter(user => user.isActive)
  .map(user => user.score)
  .reduce((sum, score) => sum + score, 0);
```

### Recursion Over Loops
When mutation isn't available, use recursion with tail-call optimization.

```typescript
// Recursive sum
const sum = (numbers: number[]): number => {
  if (numbers.length === 0) return 0;
  return numbers[0] + sum(numbers.slice(1));
};

// Tail-recursive factorial (optimized)
const factorial = (n: number, acc: number = 1): number => {
  if (n <= 1) return acc;
  return factorial(n - 1, n * acc);
};

// Recursive tree traversal
interface TreeNode<T> {
  value: T;
  children: TreeNode<T>[];
}

const findInTree = <T>(
  tree: TreeNode<T>,
  predicate: (value: T) => boolean
): T | undefined => {
  if (predicate(tree.value)) return tree.value;
  for (const child of tree.children) {
    const found = findInTree(child, predicate);
    if (found !== undefined) return found;
  }
  return undefined;
};
```

### Persistent Data Structures
Use structural sharing for efficient immutable updates.

```typescript
// Linked list (simplified)
interface ListNode<T> {
  value: T;
  next: ListNode<T> | null;
}

// Prepending is O(1) and shares structure
const prepend = <T>(value: T, list: ListNode<T> | null): ListNode<T> => ({
  value,
  next: list
});

// Structural sharing: new head, same tail
const list1 = prepend(1, prepend(2, null));
const list2 = prepend(0, list1); // Shares nodes with list1
```

### Maybe/Option Type for Null Safety
Handle absence of values without null checks scattered through code.

```typescript
type Option<T> = { type: 'some'; value: T } | { type: 'none' };

const some = <T>(value: T): Option<T> => ({ type: 'some', value });
const none = <T>(): Option<T> => ({ type: 'none' });

const mapOption = <T, U>(opt: Option<T>, fn: (v: T) => U): Option<U> =>
  opt.type === 'some' ? some(fn(opt.value)) : none();

const flatMapOption = <T, U>(opt: Option<T>, fn: (v: T) => Option<U>): Option<U> =>
  opt.type === 'some' ? fn(opt.value) : none();

// Usage
const findUser = (id: string): Option<User> => {
  const user = database.get(id);
  return user ? some(user) : none();
};

const getUserEmail = (user: User): Option<string> =>
  user.email ? some(user.email) : none();

// Chained operations, no null checks
const email = flatMapOption(
  findUser('123'),
  getUserEmail
);
```

### Either Type for Error Handling
Represent computations that may fail with error context.

```typescript
type Either<L, R> = 
  | { type: 'left'; error: L } 
  | { type: 'right'; value: R };

const left = <L, R>(error: L): Either<L, R> => ({ type: 'left', error });
const right = <L, R>(value: R): Either<L, R> => ({ type: 'right', value });

const mapEither = <L, R, T>(either: Either<L, R>, fn: (v: R) => T): Either<L, T> =>
  either.type === 'right' ? right(fn(either.value)) : either;

const flatMapEither = <L, R, T>(either: Either<L, R>, fn: (v: R) => Either<L, T>): Either<L, T> =>
  either.type === 'right' ? fn(either.value) : either;

// Validation pipeline
const parseJSON = (input: string): Either<Error, unknown> => {
  try {
    return right(JSON.parse(input));
  } catch (e) {
    return left(new Error('Invalid JSON'));
  }
};

const validateUser = (data: unknown): Either<Error, User> => {
  if (typeof data === 'object' && data !== null && 'id' in data) {
    return right(data as User);
  }
  return left(new Error('Invalid user structure'));
};

const result = flatMapEither(parseJSON(jsonString), validateUser);
```

---

## STATE MANAGEMENT

### Immutable State Updates

```typescript
interface State {
  users: User[];
  loading: boolean;
  error: string | null;
}

// Lens pattern for nested updates
interface Lens<S, A> {
  get: (s: S) => A;
  set: (a: A, s: S) => S;
}

const composeLens = <S, A, B>(outer: Lens<S, A>, inner: Lens<A, B>): Lens<S, B> => ({
  get: (s) => inner.get(outer.get(s)),
  set: (b, s) => outer.set(inner.set(b, outer.get(s)), s)
});

const over = <S, A>(lens: Lens<S, A>, fn: (a: A) => A, state: S): S =>
  lens.set(fn(lens.get(state)), state);
```

### Handling Side Effects (IO Monad Pattern)

```typescript
// Encapsulate side effects
interface IO<A> {
  run: () => A;
  map: <B>(fn: (a: A) => B) => IO<B>;
  flatMap: <B>(fn: (a: A) => IO<B>) => IO<B>;
}

const io = <A>(effect: () => A): IO<A> => ({
  run: effect,
  map: (fn) => io(() => fn(effect())),
  flatMap: (fn) => io(() => fn(effect()).run())
});

// Side effects are deferred until run() is called
const fetchUserIO = (id: string): IO<Promise<User>> =>
  io(() => fetch(`/api/users/${id}`).then(r => r.json()));

const logIO = <A>(value: A): IO<void> =>
  io(() => console.log(value));

// Compose effects without executing
const program = fetchUserIO('123')
  .flatMap(user => logIO(user.name));

// Execute at the edge
program.run();
```

---

## BEST PRACTICES

### Avoid
- Mutable shared state
- Functions with side effects (mutating arguments, I/O, randomness)
- Deep nesting of callbacks (callback hell)
- Using `let` when `const` suffices
- Null/undefined without type safety

### Prefer
- Pure functions for business logic
- Immutability for all data structures
- Function composition over method chaining
- Explicit dependencies via parameters
- Total functions (handle all inputs) over partial functions
- Pattern matching or discriminated unions for type variants

### Testing Pure Functions

```typescript
// Pure functions are trivial to test
import { describe, it, expect } from 'vitest';

describe('add', () => {
  it('returns sum of two numbers', () => {
    expect(add(2, 3)).toBe(5);
  });

  it('is commutative', () => {
    expect(add(2, 3)).toBe(add(3, 2));
  });

  it('is associative', () => {
    expect(add(add(1, 2), 3)).toBe(add(1, add(2, 3)));
  });
});

// Property-based testing (fast-check example)
describe('sort', () => {
  it('produces ordered output', () => {
    fc.assert(fc.property(fc.array(fc.integer()), (arr) => {
      const sorted = sort(arr);
      return isOrdered(sorted);
    }));
  });
});
```

---

## LANGUAGE-SPECIFIC NOTES

### JavaScript/TypeScript
- Use `const` by default, `let` only when necessary
- Leverage array methods: `map`, `filter`, `reduce`, `flatMap`
- Use `readonly` arrays and `Readonly<T>` types
- Consider libraries: Ramda, Lodash/fp, fp-ts, Effect

### Python
- Use `tuple`, `frozenset`, `NamedTuple` for immutability
- Leverage `functools`: `reduce`, `partial`, `lru_cache`
- Comprehensions over loops: `[f(x) for x in xs if pred(x)]`
- Consider: `toolz`, `pydantic` for immutable data classes

### Haskell
- Everything is pure by default; use `IO` for effects
- Pattern matching over conditionals
- Type classes for polymorphism
- Lazy evaluation enables infinite data structures

---

## REFERENCES

- [Lambda Calculus](https://en.wikipedia.org/wiki/Lambda_calculus) - Theoretical foundation
- [Category Theory for Programmers](https://bartoszmilewski.com/2014/10/28/category-theory-for-programmers-the-preface/) - Mathematical basis
- [Structure and Interpretation of Computer Programs](https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book.html) - Classic FP text
- [Functional-Light JavaScript](https://github.com/getify/functional-light-js) - Pragmatic FP guide
