---
inclusion: always
---

# Engineering Principles

## Skills Activation

| When... | Use Skill... |
|:--------|:------------|
| Writing code | [Code Implementation](../skills/code-implementation/SKILL.md) |
| Designing architecture | [Architectural Decisions](../skills/architect-decisions/SKILL.md) |
| Initializing project | [Project Setup](../skills/project-setup/SKILL.md) |
| Creating skills | [Skill Designer](../skills/skill-design/SKILL.md) |

## 1. Vectorized > Functional
- Always prefer vectorized/columnar operations over iteration.
- Use engine-native expressions (Polars, Spark SQL, DuckDB).
- Only use functional when vectorized is not available.

```python
# DO: Engine-native
df.select(pl.col("x") * 2)

# DON'T: UDF
df.select(udf_multiply("x"))
```

## 2. Minimalism
- Short is better. Fewer lines = lower maintenance.
- YAGNI: Do not implement features until strictly required.
- KISS: Avoid cleverness.
- DRY (3+ Rule): Do not abstract until logic is repeated 3 times.

```python
# DO: Duplicate <10 lines
df.select([...])  # repeated 2x is fine

# DON'T: Premature abstraction
class MyProcessor:  # create wrapper before 3 uses
```

## 3. Always Optimize Resources
- Memory and speed are always priorities.
- Prefer packages/libraries over running services.
- Reduce technical debt whenever possible.

## 4. Wide Logs
- One unit = One structured JSON event upon completion.
- Accumulate metadata in memory and flush once.
- Include: trace_id, duration_ms, context, event_type.

```python
logger.info(json.dumps({
    "trace_id": trace_id,
    "duration_ms": elapsed,
    "event_type": "task_complete",
    "context": {"rows": count}
}))
```

## 5. Cross-Cutting Optimizations
- Lazy Evaluation: Prefer lazy execution for query optimization.
- Predicate/Filter Pushdown: Filter -> Project -> Join (late).
- Filter Before Cast: Always apply filters before type casts.
- Cast Filter to Column Type: Adjust filter value to match column type, not the reverse.
- Shuffle Reduction: Limit or eliminate operations that trigger data shuffling across the network.
- Broadcast Joins: When one side fits in memory.
- Caching: Surgical use only when recomputation > storage cost.
- Anti-UDF: UDFs are a failure of design.

```python
# DO: Filter -> Project -> Join
df.lazy().filter(col("status") == "active").select("id", "name").join(other, on="id")

# DON'T: Collect early
df.collect().filter(...)
```