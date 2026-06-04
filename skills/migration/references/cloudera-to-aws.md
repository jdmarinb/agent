# Reference: Cloudera/Hive → AWS EMR / Iceberg

## Source Verification Commands

```python
# List tables in a schema
spark.sql("SHOW TABLES IN <schema>")

# Full schema of a table
spark.table("catalog.schema.table").printSchema()

# Data sample
spark.table("catalog.schema.table").limit(3).show(truncate=False)

# Count
spark.table("catalog.schema.table").count()
```

## Full Identifier Format

```
catalog.schema.table
# Example:
s3t_alg_dl_dev_data_baz_dv.cd_bdshared_cat.cd_cat_clave_estado_curp
```

## AWS / Iceberg Standards

### Audit Columns (Mandatory)
```python
fcusuariocreacion  STRING    # User or process that generated the record
fdfechacreacion    BIGINT    # Epoch in milliseconds
```

### Naming
- Columns in **lowercase** — Iceberg is case-sensitive.
- Validate names with Data Architecture before creating new tables.

### Spark Optimizations
```python
# Projection pushdown — select only necessary columns
df = spark.table("...").select("col1", "col2")

# Predicate pushdown — filter as early as possible
df = df.filter(col("fifecha") >= start_date)

# Broadcast for tables < 10MB
from pyspark.sql.functions import broadcast
df_joined = df.join(broadcast(df_catalog), "key")

# AQE enabled
spark.conf.set("spark.sql.adaptive.enabled", "true")

# ZSTD compression on write
df.write.option("write.parquet.compression-codec", "zstd")
```

### Handling Optional Columns
```python
# Verify existence before use
available_cols = set(df.columns)
optional_cols = {"col_a", "col_b", "col_c"}
cols_to_select = [c for c in optional_cols if c in available_cols]
```

### Missing Tables
```python
def _try_table(fqn):
    try:
        return spark.table(fqn)
    except Exception:
        return None

df_opt = _try_table("catalog.schema.optional_table")
# If None, the destination field remains NULL
```

## Data Types — Common Differences

| Legacy (Hive) | AWS/Iceberg | Action |
|---|---|---|
| BIGINT epoch ms | TIMESTAMP | `(col / 1000).cast("timestamp")` |
| STRING date `yyyyMMdd` | DATE | `to_date(col, "yyyyMMdd")` |
| STRING numeric | DECIMAL | `.cast(DecimalType(18,2))` |
| `NA` / empty | NULL | `when(col.isin("NA",""), None)` |

## Decryption Transformations

```python
# Voltage encryption — requires UDF approved by the team
# DO NOT use UDFs not registered in the corporate catalog
decrypted = df.withColumn("field", udf_voltage_decrypt(col("field")))
```

## Partitioning

```python
# Monthly format
fifecha_expr = date_format(col("date"), "yyyyMM").alias("fifecha")

# Daily format
fifecha_expr = date_format(col("date"), "yyyyMMdd").alias("fifecha")
```

## Secrets

```python
# NEVER hardcode — use AWS Secrets Manager or Parameter Store
import boto3
secret = boto3.client("secretsmanager").get_secret_value(SecretId="secret/name")
```

## Resource Configuration (%%configure)

```json
{
  "conf": {
    "spark.executor.memory": "8g",
    "spark.executor.cores": "4",
    "spark.executor.instances": "10",
    "spark.sql.shuffle.partitions": "200",
    "spark.sql.adaptive.enabled": "true"
  }
}
```

Adjust based on volume: more data → more memory and partitions.
