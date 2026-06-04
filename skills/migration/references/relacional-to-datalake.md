# Reference: Relational DB → Data Lake

Applies when the origin is a relational database (Oracle, SQL Server, MySQL, PostgreSQL, DB2) and the destination is a Data Lake (S3, GCS, ADLS, HDFS + Hive/Iceberg).

## Source Schema Exploration

```sql
-- Oracle
SELECT table_name, column_name, data_type, nullable
FROM all_tab_columns
WHERE owner = 'SCHEMA_NAME'
ORDER BY table_name, column_id;

-- SQL Server / Azure SQL
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- PostgreSQL / MySQL
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
```

## Key Structural Differences

| Relational Concept | Data Lake Equivalent |
|---|---|
| PRIMARY KEY | Business field as key + potentially a hash |
| FOREIGN KEY | Explicit JOIN — no automatic enforcement |
| INDEX | Partitioning + Z-order / clustering |
| VIEW | Materialized query or derived table |
| STORED PROCEDURE | Pipeline job/notebook |
| TRIGGER | Orchestrator pipeline event |
| SEQUENCE / IDENTITY | UUID or business hash |
| CONSTRAINT NOT NULL | Explicit validation in the pipeline |

## Data Types — Relational → Parquet/Iceberg

| Oracle | SQL Server | PostgreSQL | Parquet/Iceberg |
|---|---|---|---|
| NUMBER(p,0) | INT / BIGINT | INTEGER | INT / LONG |
| NUMBER(p,s) | DECIMAL(p,s) | NUMERIC(p,s) | DECIMAL(p,s) |
| VARCHAR2(n) | NVARCHAR(n) | VARCHAR(n) | STRING |
| CLOB / TEXT | TEXT | TEXT | STRING (verify size) |
| DATE | DATETIME | TIMESTAMP | TIMESTAMP |
| TIMESTAMP | DATETIME2 | TIMESTAMPTZ | TIMESTAMP |
| BLOB | VARBINARY | BYTEA | BINARY (evaluate migration) |
| CHAR(1) boolean | BIT | BOOLEAN | BOOLEAN |

## Extraction Strategy

### Full Load
- Use when the table is small or has no change-control field.
- Truncate and reload on each execution.

### Incremental by Timestamp
```sql
-- Extract only new/modified records
SELECT * FROM table
WHERE modification_date >= :last_load
  AND modification_date < :now
```

### Incremental by ID
```sql
SELECT * FROM table
WHERE id > :last_processed_id
ORDER BY id
```

### CDC (Change Data Capture)
- Use when capturing deletes is required.
- Tools: Debezium, AWS DMS, Striim, GoldenGate.
- Result is a stream of events (INSERT/UPDATE/DELETE) to process in the pipeline.

## Relationship Handling

In Data Lakes, there are no foreign keys. Relationships are materialized in two ways:

1. **Denormalization at Ingestion**: Join related tables and write a wide table.
2. **Maintain Normalization**: Write each table separately and JOIN during consumption.

Decision Criteria:
- If the relationship is stable and always queried together → Denormalize.
- If each table has independent queries → Keep separate.

## Historicity Management

Relational databases usually only have the current state. In Data Lakes, history is common. Options:

- **SCD Type 2**: Add `start_date`, `end_date`, `is_current`.
- **Daily Snapshot**: Write a complete copy per process date.
- **Append Only**: Add records with load timestamp, never update.

## Validation

```sql
-- At Relational Origin
SELECT COUNT(*), SUM(numeric_field) FROM table WHERE condition;

-- In Data Lake after Ingestion
SELECT COUNT(*), SUM(numeric_field) FROM lake_table WHERE fifecha = 'X';
```

Also verify:
- Records with NULL in fields that were NOT NULL in origin.
- Truncation of long strings.
- Loss of precision in decimals.
- Timestamps converted correctly with timezones.
