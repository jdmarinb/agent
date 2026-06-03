# Referencia: Cloudera/Hive → AWS EMR / Iceberg

## Comandos de Verificación de Fuentes

```python
# Listar tablas en un schema
spark.sql("SHOW TABLES IN <schema>")

# Schema completo de una tabla
spark.table("catalogo.esquema.tabla").printSchema()

# Muestra de datos
spark.table("catalogo.esquema.tabla").limit(3).show(truncate=False)

# Conteo
spark.table("catalogo.esquema.tabla").count()
```

## Formato de Identificador Completo

```
catalogo.esquema.tabla
# Ejemplo:
s3t_alg_dl_dev_data_baz_dv.cd_bdshared_cat.cd_cat_clave_estado_curp
```

## Estándares AWS / Iceberg

### Columnas de Auditoría (obligatorias)
```python
fcusuariocreacion  STRING    # usuario o proceso que generó el registro
fdfechacreacion    BIGINT    # epoch en milisegundos
```

### Naming
- Columnas en **minúsculas** — Iceberg es case-sensitive
- Validar nombres con Data Architecture antes de crear tablas nuevas

### Optimizaciones Spark
```python
# Projection pushdown — seleccionar solo columnas necesarias
df = spark.table("...").select("col1", "col2")

# Predicate pushdown — filtrar lo antes posible
df = df.filter(col("fifecha") >= fecha_inicio)

# Broadcast para tablas < 10MB
from pyspark.sql.functions import broadcast
df_joined = df.join(broadcast(df_catalogo), "key")

# AQE habilitado
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Compresión ZSTD en escritura
df.write.option("write.parquet.compression-codec", "zstd")
```

### Manejo de Columnas Opcionales
```python
# Verificar existencia antes de usar
available_cols = set(df.columns)
optional_cols = {"col_a", "col_b", "col_c"}
cols_to_select = [c for c in optional_cols if c in available_cols]
```

### Tablas Faltantes
```python
def _try_table(fqn):
    try:
        return spark.table(fqn)
    except Exception:
        return None

df_opt = _try_table("catalogo.esquema.tabla_opcional")
# Si es None, el campo destino queda como NULL
```

## Tipos de Datos — Diferencias Comunes

| Legacy (Hive) | AWS/Iceberg | Acción |
|---|---|---|
| BIGINT epoch ms | TIMESTAMP | `(col / 1000).cast("timestamp")` |
| STRING fecha `yyyyMMdd` | DATE | `to_date(col, "yyyyMMdd")` |
| STRING numérico | DECIMAL | `.cast(DecimalType(18,2))` |
| `NA` / vacío | NULL | `when(col.isin("NA",""), None)` |

## Transformaciones de Desencriptación

```python
# Voltage encryption — requiere UDF aprobada por el equipo
# NO usar UDFs no registradas en el catálogo corporativo
decrypted = df.withColumn("campo", udf_voltage_decrypt(col("campo")))
```

## Partición

```python
# Formato mensual
fifecha_expr = date_format(col("fecha"), "yyyyMM").alias("fifecha")

# Formato diario
fifecha_expr = date_format(col("fecha"), "yyyyMMdd").alias("fifecha")
```

## Secrets

```python
# NUNCA hardcodear — usar AWS Secrets Manager o Parameter Store
import boto3
secret = boto3.client("secretsmanager").get_secret_value(SecretId="nombre/secret")
```

## Configuración de Recursos (%%configure)

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

Ajustar según volumen: más datos → más memoria y particiones.
