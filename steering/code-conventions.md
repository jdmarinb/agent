---
inclusion: always
---

# Engineering Principles

## Project Structure

### Brevity
- Short is better. Fewer lines = lower maintenance.
- Duplicate trivial code (<10 lines) rather than fragmenting.

### Classes as Containers
- Use classes exclusively as containers for vectorized/functional methods.
- No internal state complexity.
- No deep inheritance.

### Iterators
- Use Iterators/Generators and List/Dict Comprehensions.
- Avoid `for` loops for data transformations.

### Anti-SOLID
- No abstractions of abstractions.
- No interfaces, factories, or deep inheritance.
- No premature abstractions.

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
- Use [Logging Skill](../skills/logging/SKILL.md).
- One unit = One structured JSON event upon completion.
- Accumulate metadata in memory and flush once.

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