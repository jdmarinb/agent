# Reference: On-Prem → Cloud (Generic)

Applies when the origin is own infrastructure (Hadoop, physical servers, VMs, on-prem databases) and the destination is any cloud provider.

## Source Verification at Destination

Depends on the destination service. First, identify:

- Is the destination a Data Warehouse? (BigQuery, Redshift, Synapse) → Use standard SQL.
- Is the destination a Data Lake? (S3, GCS, ADLS) → Verify paths and formats.
- Is the destination a processing engine? (Spark, Dataflow, Databricks) → Verify catalog.

```sql
-- For Data Warehouses
SHOW TABLES IN <dataset_or_schema>;
DESCRIBE <table_name>;
SELECT * FROM <table_name> LIMIT 5;
```

## Network and Connectivity Considerations

- Verify latency between origin and destination before designing the pipeline.
- Define if migration is lift-and-shift or re-architecture.
- Evaluate whether to process at origin and transfer result, or transfer data and process at destination.
- Consider network egress costs when sizing batches.

## Authentication and Secrets

Never hardcode credentials. Use the provider's native manager:

| Cloud | Service |
|---|---|
| AWS | Secrets Manager / Parameter Store |
| GCP | Secret Manager |
| Azure | Key Vault |

## Initial Transfer Strategy

For large volumes (>1TB), consider:
- AWS: Snowball / DataSync.
- GCP: Transfer Appliance / Storage Transfer Service.
- Azure: Data Box / ADF.

For medium volumes (<1TB) with direct connectivity:
- Process in batches by date.
- Validate each batch before continuing.

## Data Types — Generic Mapping

| Common On-prem | Cloud Equivalent | Notes |
|---|---|---|
| DATE / DATETIME | DATE / TIMESTAMP | Verify timezone. |
| NUMBER(p,s) | DECIMAL(p,s) / NUMERIC | Verify precision. |
| VARCHAR2 / CLOB | STRING / TEXT | Verify encoding. |
| BLOB | BYTES / BINARY | Evaluate whether to migrate or reference. |
| Epoch seconds | TIMESTAMP | `FROM_UNIXTIME(col)` |
| Epoch milliseconds | TIMESTAMP | `FROM_UNIXTIME(col / 1000)` |

## Recommended Audit Columns

While standards vary by organization, include at least:

```
load_date          TIMESTAMP   -- When the record arrived at the destination
source_origin      STRING      -- Identifier of the source system
load_process       STRING      -- Name of the job/pipeline
```

## Post-Migration Integrity Validation

```sql
-- Compare counts
SELECT COUNT(*) FROM origin.table;   -- Run at origin
SELECT COUNT(*) FROM destination.table;  -- Run at destination

-- Compare control sums on key fields
SELECT SUM(amount), COUNT(DISTINCT id) FROM origin.table WHERE date = 'X';
SELECT SUM(amount), COUNT(DISTINCT id) FROM destination.table WHERE date = 'X';
```

## Partitioning at Destination

Define strategy based on the most common query pattern:

- Queries by date → partition by `year/month/day`.
- Queries by region → partition by `country/region`.
- Mixed queries → partition by date + region.

Avoid partitions with very high cardinality (e.g., by transaction ID).
