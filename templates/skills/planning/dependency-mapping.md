# Skill: Dependency Mapping

## PURPOSE
Identify and visualize dependencies between tasks, components, or phases to enable optimal sequencing, risk mitigation, and parallelization of work.

## WHEN TO USE
- Creating project timelines
- Breaking work into phases
- Identifying critical paths
- Planning sprint capacity
- Assessing release readiness

## INPUTS
- `tasks` (required) - List of work items with basic descriptions
- `known_dependencies` (optional) - Explicitly known dependencies
- `resources` (optional) - Available resources and capacity

## DEPENDENCY TYPES

### 1. Finish-to-Start (FS)
Task B cannot start until Task A finishes.
**Example**: Deploy API → Run integration tests

```
[A: Build API] ──▶ [B: Deploy API] ──▶ [C: Test API]
```

### 2. Start-to-Start (SS)
Task B cannot start until Task A starts.
**Example**: Frontend development starts when API design starts

```
[A: API Design] ──┐
                  ├──► (parallel work)
[B: Frontend] ◀───┘
```

### 3. Finish-to-Finish (FF)
Task B cannot finish until Task A finishes.
**Example**: Documentation cannot be finalized until feature is complete

```
[A: Feature Dev] ───────────┐
                            ├──► [Complete]
[B: Documentation] ─────────┘
```

### 4. Resource Dependencies
Tasks share the same person/team and cannot run in parallel.
**Example**: One developer assigned to multiple tasks

```
[Dev A: Task 1] ──▶ [Dev A: Task 2] ──▶ [Dev A: Task 3]
```

### 5. External Dependencies
Dependencies on external teams, vendors, or events.
**Example**: Waiting for third-party API access

```
[External: Grant Access] ──▶ [Our Work: Integrate API]
```

## MAPPING TECHNIQUES

### Dependency Matrix

Create a matrix showing which tasks depend on which:

| Task | T1 | T2 | T3 | T4 | T5 |
|------|----|----|----|----|----|
| T1: Design | - | FS | FS | - | - |
| T2: API | - | - | FS | SS | - |
| T3: Backend | - | - | - | - | FS |
| T4: Frontend | - | - | - | - | FS |
| T5: Integration | - | - | - | - | - |

**Legend**:
- FS: Finish-to-Start
- SS: Start-to-Start
- FF: Finish-to-Finish
- Ext: External

### Network Diagram

Visual representation of dependencies:

```
                    ┌──────────────┐
                    │   Design     │
                    │    (T1)      │
                    └──────┬───────┘
                           │
           ┌───────────────┴───────────────┐
           │                               │
           ▼                               ▼
    ┌──────────────┐              ┌──────────────┐
    │  API Spec    │              │ UI Mockups   │
    │    (T2)      │              │   (T4)       │
    └──────┬───────┘              └──────┬───────┘
           │                             │
           ▼                             │
    ┌──────────────┐                     │
    │   Backend    │◀────────────────────┘
    │    (T3)      │      (SS: parallel)
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │  Integration │
    │    (T5)      │
    └──────────────┘
```

## CRITICAL PATH ANALYSIS

The critical path is the longest sequence of dependent tasks that determines minimum project duration.

### Steps to Identify:

1. **List all tasks** with durations
2. **Map dependencies** between tasks
3. **Calculate Early Start (ES)** and **Early Finish (EF)**
   - ES = Max(EF of all predecessors)
   - EF = ES + Duration
4. **Calculate Late Start (LS)** and **Late Finish (LF)**
   - LF = Min(LS of all successors)
   - LS = LF - Duration
5. **Identify Slack** = LS - ES (or LF - EF)
   - Zero slack = Critical path

### Example:

| Task | Duration | Dependencies | ES | EF | LS | LF | Slack | Critical? |
|------|----------|--------------|----|----|----|----|-------|-----------|
| T1 | 3d | - | 0 | 3 | 0 | 3 | 0 | **Yes** |
| T2 | 5d | T1 | 3 | 8 | 3 | 8 | 0 | **Yes** |
| T3 | 2d | T1 | 3 | 5 | 6 | 8 | 3 | No |
| T4 | 4d | T2,T3 | 8 | 12 | 8 | 12 | 0 | **Yes** |

**Critical Path**: T1 → T2 → T4 (12 days)
**Float Path**: T1 → T3 (5 days, 3 days slack)

## PARALLELIZATION OPPORTUNITIES

### What Can Run in Parallel?

Look for:
1. Tasks with no dependency relationship
2. Tasks on different critical paths
3. Tasks using different resources
4. Independent feature work

### Example:

```
Sequential (10 days):
[Backend: 5d] ──▶ [Frontend: 3d] ──▶ [Tests: 2d]

Parallel (5 days):
[Backend: 5d] ──┐
                ├──▶ [Tests: 2d]
[Frontend: 3d] ─┘
```

### Parallelization Risks

- **Integration complexity**: More moving parts
- **Merge conflicts**: Concurrent code changes
- **Coordination overhead**: Communication costs
- **Resource contention**: Shared resources

## OUTPUT

### Dependency Map

```markdown
## Dependency Map

### Task List
| ID | Task | Duration | Dependencies |
|----|------|----------|--------------|
| T1 | [Name] | [X days] | [None/T#] |

### Dependency Graph
```
[Visual or text representation]
```

### Critical Path
**Path**: T1 → T2 → T4 → T6
**Duration**: [X days]
**Key Milestones**:
- M1: [Task completion] - [Date]
- M2: [Task completion] - [Date]

### Parallel Workstreams
**Stream A**: [Tasks that can run together]
**Stream B**: [Tasks that can run together]

### External Dependencies
| Dependency | Source | Expected Date | Risk |
|------------|--------|---------------|------|
| [What we need] | [From whom] | [When] | [Level] |

### Resource Constraints
| Resource | Tasks Assigned | Overallocation? |
|----------|----------------|-----------------|
| [Dev/Team] | [Task list] | [Yes/No] |
```

## BEST PRACTICES

1. **Validate Dependencies**: Ask "Is this really a hard dependency or just convenient sequencing?"
2. **Minimize Critical Path**: Break critical tasks into parallelizable pieces
3. **Buffer External Dependencies**: External work often takes longer than expected
4. **Review Regularly**: Dependencies change as work progresses
5. **Document Rationale**: Why does T2 depend on T1? Future you will thank present you.
