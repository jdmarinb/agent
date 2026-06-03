---
id: "dev:core"
name: "Developer Master Skill"
description: "Core standards for minimalist data engineering: Vectorized > Functional paradigms."
scope: "Code implementation, optimization, and quality automation"
activation: "Active during any coding, refactoring, or testing task"
tags: [python, polars, spark, functional, vectorized, minimalism]
---

# Developer Master Skill

## 1. Absolute Mandates: Strict Compliance
- **Paradigm Strictness:** Always, absolutely always, adhere to vectorized and functional paradigms.
- **Class Usage:** Use classes exclusively as containers for vectorized or functional methods. No internal state complexity.
- **Iteration:** Use Iterators/Generators and List/Dict Comprehensions. Avoid `for` loops for data transformations.
- **Efficiency:** Always optimize for memory and time.
- **Foundational Principles:** Strictly follow Minimalism, YAGNI, KISS, and DRY.

## 2. Core Philosophy: Minimalism & Brevity
- **Brevity:** Short is better. Fewer lines = lower maintenance.
- **YAGNI & KISS:** Do not implement features until strictly required. Avoid cleverness.
- **DRY (3+ Rule):** Do not abstract until the logic is repeated 3 times. Duplicate trivial code (<10 lines) rather than fragmenting into modules.
- **Anti-SOLID:** No abstractions of abstractions. No interfaces, factories, or deep inheritance.

## 3. Paradigm Hierarchy (Order of Implementation)
1. **Vectorized/Columnar:** Use engine-native expressions (Polars, Spark SQL, DuckDB). Stay in the optimized core.
2. **Functional:** Pure functions, composition, and `map`/`reduce`.
3. **Classes as Containers:** Use classes only as namespaces for vectorized/functional methods. No internal state complexity.

## 3. Implementation & Performance Rules
- **Lazy Evaluation:** Always prefer lazy execution (e.g., `.lazy()` in Polars) to enable query optimization.
- **Optimization (Filter Early):** 
    - Leverage **Predicate Pushdown** and **Filter Pushdown** to reduce data volume at the source.
    - 1. Filter -> 2. Project (Select columns) -> 3. Join (Late).
- **Shuffle & Joins:** 
    - Limit or eliminate operations that cause **Shuffle**.
    - Use **Broadcast Joins** whenever one side of the join is small enough to fit in memory.
- **Caching:** Use `cache()` or `persist()` surgically. Only use it when the same data is accessed multiple times AND the cost of recomputation outweighs the memory/storage cost.
- **Iteration:** Use **Iterators/Generators** and **List/Dict Comprehensions**. Avoid `for` loops.
- **Anti-UDF Policy:** UDFs are a failure of design in Spark/Polars. Avoid at all costs due to serialization overhead.
- **Error Handling:** Use Monadic/Railway patterns (Success, Failure) in functional flows. Avoid `try-except` inside processing loops; use engine-native null handling.

## 4. Observability: Wide Events
- **One Unit = One Log:** Emit a single structured JSON event upon task completion.
- **Trace-as-a-Log:** Accumulate metadata in memory and flush once. Include `trace_id`, `duration_ms`, and `context`.

## 5. Tool-Specific Patterns
- **Polars:** Use `schema` in `read_*`. Use `pl.when().then().otherwise()` for DLQ patterns.
- **Spark:** Always use DataFrame API. Use `broadcast()` for small tables.
- **DuckDB:** Use for ad-hoc SQL on Parquet files.

## 6. Detailed Technical Blueprints (References)
For deep implementation details, schemas, and specific tool patterns, refer to:
- **[Observability Blueprint](./references/observability.md):** Full Wide Log JSON schemas and aggregation logic.
- **[Python Stack Patterns](./references/python-stack.md):** Specific rules for Polars, PySpark, and DuckDB optimization.
- **[Spark & Iceberg Performance Rules](./references/spark-performance.md):** Universal Spark/Iceberg performance rules for filters, joins, and caching.
- **[Quality & Testing Engine](./references/quality.md):** Detailed "Engine Pattern" code and testing philosophy.
- **[Pipeline Migration Skill](../migration/SKILL.md):** Standalone skill for legacy to modern migrations (Hive, Cloud, Relational, etc.).

## 7. Templates & Assets
Standard configuration and boilerplate files available in `./assets/`:
- `Makefile`, `pyproject.toml`, `pre-commit-config.yaml`, `logger.py` (Wide Event Logger).
