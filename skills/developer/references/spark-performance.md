---
name: spark_performance
description: Universal Spark/Iceberg performance rules. Apply whenever writing filters, joins, or reads on partitioned tables regardless of project.
inclusion: always
---

# Spark & Iceberg Performance Rules (Universal)

## 1. Filter Ordering: Cheap First, Expensive Last

**CORE RULE:** Order filter predicates from cheapest to most expensive. Defer any transformation/cast on a column until AFTER all cheap filters have reduced the dataset. NEVER remove the expensive filter — just move it to the end.

**Filter cost hierarchy (cheapest → most expensive):**
1. **Stats/partition column (zero-scan):** `col('fifecha').between(...)` — Iceberg skips entire files via min/max metadata without reading a single row
2. **Native column, no transform:** `col('canal') == 'VNT'` — scans only surviving rows, no per-row compute
3. **Column with cast/transform:** `to_date(col('loaddate')).between(...)` — per-row computation, apply ONLY on the smallest possible subset to guarantee precision

**Why:**
- Iceberg data skipping (min/max stats, bloom filters) ONLY works on untransformed column references
- Transformations (`to_date()`, `.cast()`, arithmetic) force row-by-row evaluation — they cannot be pushed down to the storage engine
- By filtering first on metadata-friendly columns, the expensive transforms run on a fraction of the data instead of the entire table
- The expensive filter at the end guarantees the result is IDENTICAL to applying it alone — the cheap filters are an optimization layer, not a replacement

**❌ BAD — Expensive transform first (full scan + per-row compute on entire table):**
```python
# Reads ALL files, transforms EVERY row, then filters
.filter(to_date((col('operacionfecha') / 1000).cast('timestamp')).between(
    lit(date_start).cast('date'), lit(date_end).cast('date')))
.filter(col('canal') == canal_filter)
```

**✅ GOOD — Cheap first, expensive last (data skipping + minimal compute):**
```python
# 1. Data skipping: Iceberg uses file-level min/max stats to skip entire files
.filter(col('fifecha').between(lit(date_start).cast('date'), lit(date_end).cast('date')))
# 2. Cheap equi-filter on native column (no transform, no scan overhead)
.filter(col('canal') == canal_filter)
# 3. Precision: cast/transform ONLY on the surviving rows (guarantees identical result)
.filter(to_date((col('operacionfecha') / 1000).cast('timestamp')).between(
    lit(date_start).cast('date'), lit(date_end).cast('date')))
```

**Rules:**
1. Identify which column has metadata support (partition, sorted, or stats-tracked) — filter on it FIRST with no transformation
2. Add any cheap equi-filters (native type, no function wrapping) SECOND
3. Apply expensive transforms/casts LAST — they guarantee precision but ONLY run on the minimal surviving dataset
4. NEVER omit the expensive filter if it's needed for correctness — just move it to the end
5. The final result MUST be identical to applying the expensive filter alone — the cheap filters are a performance optimization, not a semantic replacement
6. This applies to ALL filter chains: reads, joins conditions, window frame definitions

---

## 2. Projection Before Shuffle

**RULE:** When a downstream operation only needs N columns out of M (where N << M), SELECT those N columns BEFORE any operation that triggers a shuffle (joins, window functions, groupBy, repartition).

```python
# GOOD: project BEFORE the Window shuffle (14 cols instead of 220)
_COLS_NEEDED = ['id', 'name', 'value', 'timestamp']
df_slim = df.select(*_COLS_NEEDED)
df_dedup = df_slim.withColumn('rn', row_number().over(w)).filter(col('rn') == 1)

# BAD: shuffle 200 columns through Window, then select 4
df_dedup = df.withColumn('rn', row_number().over(w)).filter(col('rn') == 1).select(...)
```

---

## 3. Persist/Cache Strategy

**CORE RULE:** Caching is for reuse, not for "simplifying plans". If the plan is complex, fix the plan (better filters, fewer joins). Only cache when the SAME DataFrame is consumed by 2+ actions.

**When to cache:**
- Same filtered table read by 3 different projections (e.g., scripts 14/15/16 reading same source)
- A lookup table used in multiple joins within the same job

**When NOT to cache:**
- Between a UNION and enrichment — if filters are efficient, Spark handles this fine without materialization
- Single-use DataFrames (read once, write once)
- Large DataFrames that exceed executor RAM — `DISK_ONLY` fills local disk and causes "No space left on device"

**Storage level choice:**
- `.cache()` (= `MEMORY_AND_DISK`) — default, uses RAM first, spills to disk if needed
- `MEMORY_ONLY` — fast but drops partitions that don't fit (use for small DFs)
- **NEVER `DISK_ONLY`** on EMR with small local disks — shuffle files + persist files compete for the same ephemeral storage

**Always call `.unpersist()` after the last use.**

```python
# GOOD: same source consumed 3 times (different projections)
src = spark.table(...).filter(col('fifecha') == ...).cache()
df_a = project_a(src)  # action 1
df_b = project_b(src)  # action 2
df_c = project_c(src)  # action 3
src.unpersist()

# BAD: persist between UNION and next step (single-use, wastes disk)
df_union.persist(StorageLevel.DISK_ONLY)
df_union.count()  # unnecessary extra job
result = enrich(df_union)  # only used once
df_union.unpersist()

# GOOD: just let Spark run the plan (efficient with proper filters)
df_union = reduce(lambda a, b: a.unionByName(b, ...), all_dfs)
result = enrich(df_union)
```

---

## 4. Eliminate Redundant Filters on Derived Tables

**RULE:** If a table was PRODUCED by a pipeline that guarantees a column's value (e.g., `fifecha` derived from `operacionfecha`), do NOT re-filter on the source column when reading the output table.

```python
# paso1y2 writes: audit_columns(df, date_format(col('operacionfecha'), 'yyyyMMdd').cast('int'))
# This guarantees fifecha == to_date(operacionfecha) in the Crystal table

# BAD: re-filtering on operacionfecha when reading the Crystal output
.filter(col('fifecha').between(...))
.filter(to_date(col('operacionfecha')).between(...))  # REDUNDANT — fifecha already guarantees this

# GOOD: fifecha alone is sufficient for tables you produced
.filter(col('fifecha').between(lit(ds).cast('date'), lit(de).cast('date')))
```

**When the precision filter IS needed:**
- Reading source/raw tables where `fifecha` might not perfectly align with the business timestamp
- Tables produced by external systems where you cannot guarantee column alignment

---

## 5. No Defensive Code in Data Pipelines

**RULE:** Do not add "safety net" filters that will never filter anything. They add cognitive load, obscure intent, and waste (minimal) compute.

```python
# BAD: pipeline guarantees fifecha is never null (it's derived from a required field)
df = df.filter(col('fifecha').isNotNull())  # DEAD CODE — confuses reviewers

# BAD: dead variables that are never used
_totales = {'14': 0, '15': 0, '16': 0}  # never incremented

# GOOD: if a column CAN be null and that's a problem, handle it at the source
# If it CANNOT be null by construction, don't filter — trust the pipeline
```

---

## 6. Broadcast Joins — Size Threshold

**RULE:** Use `broadcast()` explicitly for dimension/catalog tables under 10MB. Never broadcast fact tables.

```python
# GOOD
from pyspark.sql.functions import broadcast
enriched = fact_df.join(broadcast(dim_df), on='key', how='left')

# BAD: relying on autoBroadcastJoinThreshold without explicit intent
enriched = fact_df.join(dim_df, on='key', how='left')
```

---

## 7. Avoid Python-Side Shadowing of Spark Functions

**RULE:** `from pyspark.sql.functions import *` shadows Python builtins (`min`, `max`, `sum`, `round`, `abs`). When you need the Python builtin, use explicit comparison or import `builtins`.

```python
# BAD: min() is now pyspark.sql.functions.min, takes Column not scalars
from pyspark.sql.functions import *
result = min(date_a, date_b)  # TypeError

# GOOD: ternary or explicit
result = date_a if date_a < date_b else date_b

# GOOD: import builtins
import builtins
result = builtins.min(date_a, date_b)
```


---

## 8. EMR Local Disk Budget Awareness

**RULE:** On EMR clusters, local disk is shared between shuffle files, spill files, and persist(DISK). A job that writes large intermediate data to disk can cause "No space left on device" on the NEXT stage or the next day's iteration.

**Budget:**
- EMR instances have limited ephemeral storage (typically 20-100GB per node depending on instance type)
- Shuffle files from previous stages are NOT immediately cleaned (Spark retains them for fault tolerance)
- `persist(DISK_ONLY)` + `count()` writes the ENTIRE DataFrame to local disk BEFORE the next operation

**Rules:**
1. Prefer `.cache()` (MEMORY_AND_DISK) over `persist(DISK_ONLY)` — RAM first, disk only as spillover
2. NEVER force materialization (`count()`) unless you have confirmed the data volume fits in local disk budget
3. In loops that process multiple days, each iteration's shuffle files accumulate — design for the CUMULATIVE disk usage, not just one iteration
4. If disk space is tight, reduce `spark.sql.shuffle.partitions` to produce fewer (but larger) shuffle files
5. Use `spark.local.dir` pointed to a larger volume if available, or request instances with more local storage

**Anti-pattern that killed our job:**
```python
# Each day: 277K rows × 220 cols persisted to disk + shuffle files from 64 JOINs
# Day 1 fills 60% of disk, Day 2 overflows
while _dia <= _fin:
    df = pipeline(ds, ds)
    df_union.persist(StorageLevel.DISK_ONLY)  # writes ~2GB to local disk
    df_union.count()                          # forces the write NOW
    result = enrich(df_union)                 # shuffle adds another ~1GB
    df_union.unpersist()                      # frees persist, but shuffle files remain
    write(result)                             # more shuffle for write
    _dia += timedelta(days=1)                 # Day 2 starts with leftover shuffle files
```

---

## 9. Eliminate Redundant Precision Filters on Self-Produced Tables

**RULE:** When reading a table that YOUR pipeline produced with a deterministic column derivation, the derived column's filter is sufficient — do not add the source column filter.

**Context:** If `paso1y2` writes `fifecha = date_format(operacionfecha, 'yyyyMMdd')`, then when `paso3` reads that table, filtering by `fifecha` is semantically identical to filtering by `to_date(operacionfecha)`. Adding both is redundant compute.

```python
# paso3 reads from paso1y2's output (Crystal table)
# fifecha was derived FROM operacionfecha — they are aligned by construction

# BAD: double filter (redundant to_date on every row)
.filter(col('fifecha').between(...))
.filter(to_date(col('operacionfecha')).between(...))

# GOOD: fifecha alone (zero-compute, same result)
.filter(col('fifecha').between(lit(ds).cast('date'), lit(de).cast('date')))
```

**Exception:** On SOURCE tables (Data Vault, raw) where `fifecha` may represent ingestion date rather than business date, keep BOTH filters (Rule #1 ordering applies).
