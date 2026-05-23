# Observability: Wide Logs & Trace Aggregation

## Core Philosophy: Logs are Data, Not Diaries
- **Canonical Logging (Wide Events):** Emit ONE structured log event per unit of work upon completion.
- **Context Accumulation:** Do not log intermediate steps. Accumulate metadata in memory, flush once.
- **Structured ONLY:** All logs must be JSON. No plain text.

## Log Schema (Flat JSON)
| Field | Type | Notes |
|:---|:---|:---|
| `timestamp` | ISO8601 UTC (µs) | Required |
| `trace_id` | String (UUID v4) | Required |
| `span_id` | String | Required |
| `level` | `INFO\|WARN\|ERROR` | Required |
| `event` | String (snake_case) | e.g. `etl_pipeline_success` |
| `duration_ms` | Float | Closing events only |
| `context.*` | Mixed | `user_id`, `org_id`, `version`, etc. |

## Wide Event Example
```json
{
  "timestamp": "2026-01-21T14:30:00Z",
  "event": "etl_pipeline_success",
  "status": "success",
  "total_duration_ms": 5200,
  "context": {
    "pipeline": "daily_sales_ingest",
    "run_id": "exec-abc-123",
    "environment": "production"
  },
  "metrics": {
    "input_rows": 10000,
    "output_rows": 9850,
    "quality_score": 0.98
  },
  "steps": {
    "extraction": { "duration_ms": 1500, "source": "s3://raw-data/sales/2026-01-21.csv" },
    "cleaning": { "duration_ms": 500, "actions": { "nulls_dropped": 50 } },
    "processing": { "duration_ms": 2000, "logic": "currency_conversion_usd" },
    "loading": { "duration_ms": 1200, "target": "snowflake:dw.sales_fact" }
  }
}
```

## Aggregation Pipeline: Log Folding
1. `[Span emitted]` -> Local WAL (Avro/SQLite).
2. `[Read all spans for trace]` on completion.
3. `Master Wide Log { steps: [...spans] }`.
4. `Object Storage` -> Optimized Parquet.
