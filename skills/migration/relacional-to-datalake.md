# Referencia: DB Relacional → Data Lake

Aplica cuando el origen es una base de datos relacional (Oracle, SQL Server, MySQL,
PostgreSQL, DB2) y el destino es un Data Lake (S3, GCS, ADLS, HDFS + Hive/Iceberg).

## Exploración del Schema Origen

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

## Diferencias Estructurales Clave

| Concepto Relacional | Equivalente Data Lake |
|---|---|
| PRIMARY KEY | Campo de negocio como clave + posiblemente hash |
| FOREIGN KEY | JOIN explícito — no hay enforcement automático |
| INDEX | Partición + Z-order / clustering |
| VIEW | Query materializada o tabla derivada |
| STORED PROCEDURE | Job/notebook del pipeline |
| TRIGGER | Evento en pipeline orquestador |
| SEQUENCE / IDENTITY | UUID o hash de negocio |
| CONSTRAINT NOT NULL | Validación explícita en el pipeline |

## Tipos de Datos — Relacional → Parquet/Iceberg

| Oracle | SQL Server | PostgreSQL | Parquet/Iceberg |
|---|---|---|---|
| NUMBER(p,0) | INT / BIGINT | INTEGER | INT / LONG |
| NUMBER(p,s) | DECIMAL(p,s) | NUMERIC(p,s) | DECIMAL(p,s) |
| VARCHAR2(n) | NVARCHAR(n) | VARCHAR(n) | STRING |
| CLOB / TEXT | TEXT | TEXT | STRING (verificar tamaño) |
| DATE | DATETIME | TIMESTAMP | TIMESTAMP |
| TIMESTAMP | DATETIME2 | TIMESTAMPTZ | TIMESTAMP |
| BLOB | VARBINARY | BYTEA | BINARY (evaluar si migrar) |
| CHAR(1) booleano | BIT | BOOLEAN | BOOLEAN |

## Estrategia de Extracción

### Full Load (carga completa)
- Usar cuando la tabla es pequeña o no tiene campo de control de cambios
- Truncar y recargar en cada ejecución

### Incremental por Timestamp
```sql
-- Extraer solo registros nuevos/modificados
SELECT * FROM tabla
WHERE fecha_modificacion >= :ultima_carga
  AND fecha_modificacion < :ahora
```

### Incremental por ID
```sql
SELECT * FROM tabla
WHERE id > :ultimo_id_procesado
ORDER BY id
```

### CDC (Change Data Capture)
- Usar cuando se requiere capturar deletes
- Herramientas: Debezium, AWS DMS, Striim, GoldenGate
- El resultado es un stream de eventos (INSERT/UPDATE/DELETE) a procesar en el pipeline

## Manejo de Relaciones

En Data Lake no hay foreign keys. Las relaciones se materializan de dos formas:

1. **Desnormalización en ingestión**: unir tablas relacionadas y escribir una tabla ancha
2. **Mantener normalización**: escribir cada tabla por separado y hacer JOIN en consumo

Criterio de decisión:
- Si la relación es estable y siempre se consulta junta → desnormalizar
- Si cada tabla tiene consultas independientes → mantener separadas

## Manejo de Historicidad

Las bases relacionales suelen tener solo el estado actual. En Data Lake es común
querer historial. Opciones:

- **SCD Tipo 2**: agregar `fecha_inicio`, `fecha_fin`, `es_vigente`
- **Snapshot diario**: escribir una copia completa por fecha de proceso
- **Append only**: agregar registros con timestamp de carga, nunca actualizar

## Validación

```sql
-- En origen relacional
SELECT COUNT(*), SUM(campo_numerico) FROM tabla WHERE condicion;

-- En Data Lake después de ingestión
SELECT COUNT(*), SUM(campo_numerico) FROM tabla_lake WHERE fifecha = 'X';
```

Verificar también:
- Registros con NULL en campos que eran NOT NULL en origen
- Truncamiento de strings largos
- Pérdida de precisión en decimales
- Fechas con timezone convertidas correctamente
