# Referencia: On-Prem → Cloud (Genérico)

Aplica cuando el origen es infraestructura propia (Hadoop, servidores físicos, VMs,
bases de datos on-prem) y el destino es cualquier proveedor cloud.

## Verificación de Fuentes en Destino

Depende del servicio destino. Identificar primero:

- ¿El destino es un Data Warehouse? (BigQuery, Redshift, Synapse) → usar SQL estándar
- ¿El destino es un Data Lake? (S3, GCS, ADLS) → verificar paths y formatos
- ¿El destino es un motor de procesamiento? (Spark, Dataflow, Databricks) → verificar catálogo

```sql
-- Para Data Warehouses
SHOW TABLES IN <dataset_o_schema>;
DESCRIBE <tabla>;
SELECT * FROM <tabla> LIMIT 5;
```

## Consideraciones de Red y Conectividad

- Verificar latencia entre origen y destino antes de diseñar el pipeline
- Definir si la migración es lift-and-shift o re-arquitectura
- Evaluar si procesar en origen y transferir resultado, o transferir datos y procesar en destino
- Considerar costos de egress de red al dimensionar lotes

## Autenticación y Secretos

Nunca hardcodear credenciales. Usar el gestor nativo del proveedor:

| Cloud | Servicio |
|---|---|
| AWS | Secrets Manager / Parameter Store |
| GCP | Secret Manager |
| Azure | Key Vault |

## Estrategia de Transferencia Inicial

Para volúmenes grandes (>1TB), considerar:
- AWS: Snowball / DataSync
- GCP: Transfer Appliance / Storage Transfer Service
- Azure: Data Box / ADF

Para volúmenes medianos (<1TB) con conectividad directa:
- Procesar en lotes por fecha
- Validar cada lote antes de continuar

## Tipos de Datos — Mapeo Genérico

| On-prem común | Equivalente cloud | Notas |
|---|---|---|
| DATE / DATETIME | DATE / TIMESTAMP | Verificar timezone |
| NUMBER(p,s) | DECIMAL(p,s) / NUMERIC | Verificar precisión |
| VARCHAR2 / CLOB | STRING / TEXT | Verificar encoding |
| BLOB | BYTES / BINARY | Evaluar si migrar o referenciar |
| Epoch seconds | TIMESTAMP | `FROM_UNIXTIME(col)` |
| Epoch milliseconds | TIMESTAMP | `FROM_UNIXTIME(col / 1000)` |

## Columnas de Auditoría Recomendadas

Aunque el estándar varía por organización, incluir mínimo:

```
fecha_carga        TIMESTAMP   -- momento en que el registro llegó al destino
fuente_origen      STRING      -- identificador del sistema fuente
proceso_carga      STRING      -- nombre del job/pipeline
```

## Validación de Integridad Post-Migración

```sql
-- Comparar conteos
SELECT COUNT(*) FROM origen.tabla;   -- ejecutar en origen
SELECT COUNT(*) FROM destino.tabla;  -- ejecutar en destino

-- Comparar sumas de control en campos clave
SELECT SUM(monto), COUNT(DISTINCT id) FROM origen.tabla WHERE fecha = 'X';
SELECT SUM(monto), COUNT(DISTINCT id) FROM destino.tabla WHERE fecha = 'X';
```

## Partición en Destino

Definir estrategia según patrón de consulta más común:

- Consultas por fecha → particionar por `año/mes/dia`
- Consultas por región → particionar por `pais/region`
- Consultas mixtas → particionar por fecha + región

Evitar particiones con cardinalidad muy alta (ej. por ID de transacción).
