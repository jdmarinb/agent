# Referencia: Cloud → Cloud (ej. AWS → GCP, GCP → Azure, etc.)

## Verificación de Fuentes

Identificar el catálogo nativo del origen y del destino:

| Origen | Comando de exploración |
|---|---|
| AWS Glue / Athena | `SHOW TABLES IN <database>` en Athena |
| BigQuery | `SELECT * FROM <dataset>.INFORMATION_SCHEMA.TABLES` |
| Azure Synapse | `SELECT * FROM INFORMATION_SCHEMA.TABLES` |
| Databricks | `SHOW TABLES IN <schema>` |
| Snowflake | `SHOW TABLES IN SCHEMA <db>.<schema>` |

## Diferencias de Dialecto SQL por Par

### AWS (Athena/Glue) → GCP (BigQuery)
```sql
-- Athena
DATE_FORMAT(col, '%Y%m')
REGEXP_EXTRACT(col, 'patron', 1)
CAST(col AS DECIMAL(18,2))

-- BigQuery equivalente
FORMAT_DATE('%Y%m', col)
REGEXP_EXTRACT(col, r'patron')
CAST(col AS NUMERIC)   -- o BIGNUMERIC para mayor precisión
```

### AWS (Spark/EMR) → Azure (Synapse/Databricks)
```sql
-- Spark
from_unixtime(col / 1000)
date_format(col, 'yyyyMM')

-- Synapse equivalente
DATEADD(second, col / 1000, '1970-01-01')
FORMAT(col, 'yyyyMM')
```

### GCP (BigQuery) → AWS (Redshift)
```sql
-- BigQuery
TIMESTAMP_MILLIS(col)
ARRAY_AGG(col)

-- Redshift equivalente
TIMESTAMP 'epoch' + col/1000 * INTERVAL '1 second'
LISTAGG(col, ',')   -- no hay ARRAY nativo
```

## Formato de Archivo en Transferencia

Al transferir datos entre nubes vía storage, usar formatos intermedios eficientes:

- **Parquet** — recomendado para datos estructurados (columnar, comprimible)
- **Avro** — recomendado para streaming o schemas evolutivos
- **ORC** — compatible con ecosistema Hive/Hadoop si aplica
- Evitar CSV para volúmenes grandes (sin tipos, sin compresión eficiente)

## Costos de Egress

Los proveedores cobran por transferencia de datos saliente. Estimar antes de migrar:

- AWS → GCP/Azure: ~$0.08/GB (varía por región)
- GCP → AWS/Azure: ~$0.08/GB
- Azure → AWS/GCP: ~$0.08/GB

Para volúmenes >10TB, evaluar servicios de transferencia directa (AWS Direct Connect,
Google Dedicated Interconnect, Azure ExpressRoute).

## Autenticación Cross-Cloud

Nunca usar credenciales de larga duración en el código. Opciones:

- **AWS → GCP**: Workload Identity Federation (sin service account keys)
- **GCP → AWS**: AWS IAM roles con OIDC desde GCP
- **Azure → AWS**: AWS IAM roles con Azure AD federation

## Diferencias de Tipos de Datos

| AWS/Spark | BigQuery | Azure Synapse | Snowflake |
|---|---|---|---|
| STRING | STRING | NVARCHAR | VARCHAR |
| BIGINT | INT64 | BIGINT | NUMBER(38,0) |
| DECIMAL(18,2) | NUMERIC | DECIMAL(18,2) | NUMBER(18,2) |
| TIMESTAMP | TIMESTAMP | DATETIME2 | TIMESTAMP_NTZ |
| BOOLEAN | BOOL | BIT | BOOLEAN |
| ARRAY | ARRAY | (no nativo) | ARRAY |
| MAP/STRUCT | STRUCT | (JSON) | VARIANT |

## Columnas de Auditoría

Mantener las columnas de auditoría del origen y agregar las del destino si el estándar
del equipo las requiere. No eliminar trazabilidad del sistema fuente.

## Validación Post-Migración

```sql
-- En origen (antes de migrar)
SELECT
  COUNT(*) as total_registros,
  COUNT(DISTINCT id_clave) as ids_unicos,
  SUM(campo_numerico) as suma_control,
  MIN(fecha_campo) as fecha_min,
  MAX(fecha_campo) as fecha_max
FROM tabla_origen;

-- Repetir en destino y comparar
```
