# Skill: REST API Design

## PURPOSE
Design clean, consistent, and intuitive RESTful APIs that follow industry best practices and are easy to consume.

## WHEN TO USE
- Defining API contracts
- Creating endpoint specifications
- Designing request/response schemas
- Establishing versioning strategies
- Documenting APIs with OpenAPI

## INPUTS
- `resources` (required) - Domain resources to expose
- `operations` (required) - CRUD operations needed per resource
- `versioning_strategy` (optional) - `URL`, `HEADER`, or `MEDIA_TYPE`

## REST PRINCIPLES

### Resource-Based URLs
Use nouns (resources), not verbs (actions):

```yaml
# ❌ Bad - Verbs in URL
GET /getUser?id=123
POST /createOrder
DELETE /deleteProduct/456

# ✅ Good - Resource-based
GET /users/123
POST /orders
DELETE /products/456
```

### HTTP Methods

| Method | Action | Idempotent | Safe |
|--------|--------|------------|------|
| GET | Read resource | Yes | Yes |
| POST | Create resource | No | No |
| PUT | Replace resource | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove resource | Yes | No |

### URL Structure

```
/collections/{id}/subcollections/{subId}

Examples:
/users                    # Collection
/users/123                # Single resource
/users/123/orders         # Sub-collection
/users/123/orders/456     # Sub-resource
```

## REQUEST/RESPONSE PATTERNS

### GET (Read)

**Collection**
```http
GET /users?page=1&limit=20&sort=name&order=asc

Response 200:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

**Single Resource**
```http
GET /users/123

Response 200:
{
  "id": "123",
  "name": "Alice",
  "email": "alice@example.com",
  "createdAt": "2024-01-15T10:30:00Z"
}

Response 404:
{
  "error": "User not found",
  "code": "USER_NOT_FOUND"
}
```

### POST (Create)

```http
POST /users
Content-Type: application/json

Request:
{
  "name": "Alice",
  "email": "alice@example.com"
}

Response 201:
{
  "id": "123",
  "name": "Alice",
  "email": "alice@example.com",
  "createdAt": "2024-01-15T10:30:00Z"
}

Response 400:
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "details": [
    { "field": "email", "message": "Invalid email format" }
  ]
}
```

### PUT (Replace)

```http
PUT /users/123
Content-Type: application/json

Request:
{
  "name": "Alice Smith",
  "email": "alice.smith@example.com"
}

Response 200:
{
  "id": "123",
  "name": "Alice Smith",
  "email": "alice.smith@example.com",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-16T14:20:00Z"
}
```

### PATCH (Partial Update)

```http
PATCH /users/123
Content-Type: application/json

Request:
{
  "name": "Alice Smith"
}

Response 200:
{
  "id": "123",
  "name": "Alice Smith",
  "email": "alice@example.com",
  "updatedAt": "2024-01-16T14:20:00Z"
}
```

### DELETE

```http
DELETE /users/123

Response 204: (No Content)

Response 404:
{
  "error": "User not found",
  "code": "USER_NOT_FOUND"
}
```

## STATUS CODES

### Success (2xx)
- **200 OK**: Standard success
- **201 Created**: Resource created
- **202 Accepted**: Request accepted for async processing
- **204 No Content**: Success, no body (DELETE, empty PUT)

### Client Errors (4xx)
- **400 Bad Request**: Validation error, malformed request
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Authenticated but not authorized
- **404 Not Found**: Resource doesn't exist
- **409 Conflict**: Resource conflict (duplicate, stale data)
- **422 Unprocessable Entity**: Semantic errors

### Server Errors (5xx)
- **500 Internal Server Error**: Unexpected error
- **502 Bad Gateway**: Upstream error
- **503 Service Unavailable**: Temporary outage

## ERROR RESPONSE FORMAT

Standard error structure:

```json
{
  "error": "Human-readable message",
  "code": "MACHINE_READABLE_CODE",
  "details": [
    {
      "field": "fieldName",
      "message": "Specific error for this field"
    }
  ],
  "requestId": "uuid-for-tracing",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## VERSIONING STRATEGIES

### 1. URL Path (Recommended)
```
/v1/users
/v2/users
```

Pros: Simple, explicit, cache-friendly
Cons: URL changes between versions

### 2. Header
```
GET /users
API-Version: 2
```

Pros: Clean URLs
Cons: Harder to test in browser

### 3. Content-Type (Media Type)
```
GET /users
Accept: application/vnd.api.v2+json
```

Pros: HTTP spec compliant
Cons: Verbose, less intuitive

## FILTERING, SORTING, PAGINATION

### Filtering
```
GET /users?status=active&role=admin
GET /orders?createdAfter=2024-01-01&minAmount=100
```

### Sorting
```
GET /users?sort=name&order=asc
GET /users?sort=-createdAt (descending)
```

### Pagination
```
# Offset-based (simple)
GET /users?page=2&limit=20

# Cursor-based (better for large datasets)
GET /users?cursor=eyJpZCI6MTIzfQ&limit=20
```

## NAMING CONVENTIONS

### Resources
- Plural nouns: `/users`, `/orders`
- Lowercase: `/user-profiles` (not `/userProfiles`)
- Hyphens for multi-word: `/order-items`

### Fields
- camelCase: `firstName`, `createdAt`
- Consistent abbreviations: `id` (not `ID` or `Id`)

### Dates
- ISO 8601 format: `2024-01-15T10:30:00Z`
- Always UTC: Include Z suffix

## IDEMPOTENCY

For non-idempotent operations (POST, PATCH), support idempotency keys:

```http
POST /orders
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000

# Same request with same key returns same response
# without creating duplicate resource
```

## OPENAPI SPEC EXAMPLE

```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
    post:
      summary: Create user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
        createdAt:
          type: string
          format: date-time
```

## OUTPUT

### API Specification

```markdown
## Resources
| Resource | URL Pattern | Description |
|----------|-------------|-------------|
| User | /users/{id} | User entity |

## Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v1/users | List users |

## Request/Response Examples
[Examples for each endpoint]

## Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| USER_NOT_FOUND | 404 | User doesn't exist |

## OpenAPI Spec
[Link to spec file]
```
