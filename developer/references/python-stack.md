# Python Stack — Tool-Specific Patterns

## Polars (Single Node — Batch)
- `calamine` (Excel), `orjson` (JSON), `msgspec` (validation).
- Define `schema`/`dtypes` in `pl.read_*()` for Rust-level validation.
- Use `pandera` only for complex cross-column rules.
- **NEVER** use Pydantic or row-based loops on DataFrames.
- **DLQ Pattern:** Use `pl.when().then().otherwise()` for error columns.

## PySpark (Distributed)
- **DataFrame API Only.** Avoid RDDs.
- `broadcast()` small dimension tables.
- Enforce schemas with `StructType`.
- **Optimization:** Repartition/coalesce before writes or after heavy filtering.
- **Anti-UDF:** Every UDF causes Python serialization overhead. Use native functions.

## DuckDB (Analytics)
- In-process SQL directly on Parquet/CSV in object storage.
- Ideal for AQE (Analytical Query Engine).

## Common Libraries
| Library | Purpose |
|:---|:---|
| `pytest` | Testing framework |
| `hypothesis` | Property-based testing |
| `memray` | Memory profiling |
| `structlog` | Structured logging |
