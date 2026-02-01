# Skill: Code Security Scanning

## PURPOSE
Identify common security vulnerabilities in code through static analysis and security-focused code review.

## WHEN TO USE
- During code reviews
- In CI/CD pipelines
- Before merging changes
- Security audits

## INPUTS
- `code_diff` (required) - Code to scan
- `language` (required) - Programming language
- `risk_level` (optional) - Minimum severity to report (default: medium)

## COMMON VULNERABILITIES

### Injection Attacks
```typescript
// ❌ Vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ Safe
const query = 'SELECT * FROM users WHERE id = ?';
await db.query(query, [userId]);
```

### Hardcoded Secrets
```typescript
// ❌ Vulnerable
const API_KEY = 'sk-live-abc123';

// ✅ Safe
const API_KEY = process.env.API_KEY;
```

### Insecure Deserialization
```typescript
// ❌ Vulnerable
const obj = eval(userInput);

// ✅ Safe
const obj = JSON.parse(userInput);
validateSchema(obj);
```

## SEVERITY LEVELS

| Level | Description | Examples |
|-------|-------------|----------|
| Critical | Immediate exploit likely | SQL injection, auth bypass |
| High | Significant security risk | XSS, hardcoded secrets |
| Medium | Potential security issue | Weak crypto, verbose errors |
| Low | Best practice violation | Missing headers, comments |

## OUTPUT

```markdown
## Security Scan Results
- **Files Scanned**: [count]
- **Issues Found**: [count by severity]

### Critical Issues
| Issue | Location | Remediation |
|-------|----------|-------------|
| SQL Injection | line 23 | Use parameterized queries |

### Recommendations
1. Add input validation middleware
2. Implement rate limiting
3. Enable security headers
```
