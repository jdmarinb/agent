# Reference: Cloud → Cloud (e.g., AWS → GCP, GCP → Azure, etc.)

## Source Verification

Identify the native catalog of origin and destination:

| Origin | Exploration Command |
|---|---|
| AWS Glue / Athena | `SHOW TABLES IN <database>` in Athena |
| BigQuery | `SELECT * FROM <dataset>.INFORMATION_SCHEMA.TABLES` |
| Azure Synapse | `SELECT * FROM INFORMATION_SCHEMA.TABLES` |
| Databricks | `SHOW TABLES IN <schema>` |
| Snowflake | `SHOW TABLES IN SCHEMA <db>.<schema>` |

## SQL Dialect Differences per Pair

### AWS (Athena/Glue) → GCP (BigQuery)
```sql
-- Athena
DATE_FORMAT(col, '%Y%m')
REGEXP_EXTRACT(col, 'pattern', 1)
CAST(col AS DECIMAL(18,2))

-- BigQuery Equivalent
FORMAT_DATE('%Y%m', col)
REGEXP_EXTRACT(col, r'pattern')
CAST(col AS NUMERIC)   -- or BIGNUMERIC for higher precision
```

### AWS (Spark/EMR) → Azure (Synapse/Databricks)
```sql
-- Spark
from_unixtime(col / 1000)
date_format(col, 'yyyyMM')

-- Synapse Equivalent
DATEADD(second, col / 1000, '1970-01-01')
FORMAT(col, 'yyyyMM')
```

### GCP (BigQuery) → AWS (Redshift)
```sql
-- BigQuery
TIMESTAMP_MILLIS(col)
ARRAY_AGG(col)

-- Redshift Equivalent
TIMESTAMP 'epoch' + col/1000 * INTERVAL '1 second'
LISTAGG(col, ',')   -- No native ARRAY
```

## File Format in Transfer

When transferring data between clouds via storage, use efficient intermediate formats:

- **Parquet** — Recommended for structured data (columnar, compressible).
- **Avro** — Recommended for streaming or evolving schemas.
- **ORC** — Compatible with Hive/Hadoop ecosystem if applicable.
- Avoid CSV for large volumes (no types, no efficient compression).

## Egress Costs

Providers charge for outgoing data transfer. Estimate before migrating:

- AWS → GCP/Azure: ~$0.08/GB (varies by region).
- GCP → AWS/Azure: ~$0.08/GB.
- Azure → AWS/GCP: ~$0.08/GB.

For volumes >10TB, evaluate direct transfer services (AWS Direct Connect, Google Dedicated Interconnect, Azure ExpressRoute).

## Cross-Cloud Authentication

Never use long-lived credentials in code. Options:

- **AWS → GCP**: Workload Identity Federation (no service account keys).
- **GCP → AWS**: AWS IAM roles with OIDC from GCP.
- **Azure → AWS**: AWS IAM roles with Azure AD federation.

## Data Type Differences

| AWS/Spark | BigQuery | Azure Synapse | Snowflake |
|---|---|---|---|
| STRING | STRING | NVARCHAR | VARCHAR |
| BIGINT | INT64 | BIGINT | NUMBER(38,0) |
| DECIMAL(18,2) | NUMERIC | DECIMAL(18,2) | NUMBER(18,2) |
| TIMESTAMP | TIMESTAMP | DATETIME2 | TIMESTAMP_NTZ |
| BOOLEAN | BOOL | BIT | BOOLEAN |
| ARRAY | ARRAY | (Not Native) | ARRAY |
| MAP/STRUCT | STRUCT | (JSON) | VARIANT |

## Audit Columns

Maintain audit columns from the origin and add destination ones if the team standard requires. Do not remove traceability from the source system.

## Post-Migration Validation

```sql
-- At Origin (before migrating)
SELECT
  COUNT(*) as total_records,
  COUNT(DISTINCT key_id) as unique_ids,
  SUM(numeric_field) as control_sum,
  MIN(date_field) as min_date,
  MAX(date_field) as max_date
FROM origin_table;

-- Repeat at Destination and compare
```
