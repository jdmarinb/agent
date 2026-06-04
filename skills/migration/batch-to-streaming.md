# Referencia: Batch → Streaming

Aplica cuando un pipeline que procesa datos en lotes (diario, horario, semanal)
se migra a procesamiento en tiempo real o near-real-time.

## Herramientas Comunes

| Plataforma | Motor de Streaming |
|---|---|
| AWS | Kinesis Data Streams, MSK (Kafka), Kinesis Firehose |
| GCP | Pub/Sub + Dataflow (Apache Beam) |
| Azure | Event Hubs, Stream Analytics |
| On-prem / Multi-cloud | Apache Kafka + Spark Structured Streaming / Flink |

## Diferencias Conceptuales Batch vs Streaming

| Batch | Streaming |
|---|---|
| Procesa un bloque de datos histórico | Procesa eventos a medida que llegan |
| Se ejecuta según schedule (cron) | Corre continuamente |
| Latencia: minutos a horas | Latencia: milisegundos a segundos |
| Re-procesar es trivial (re-ejecutar el job) | Re-procesar requiere replay del topic |
| Estado: sin estado o completo en memoria | Estado: requiere gestión explícita (checkpoints) |
| Errores: reintentar el batch | Errores: dead-letter queue + alertas |

## Patrones de Migración

### Patrón Lambda (recomendado para transición)
Mantener el pipeline batch (capa batch) y agregar pipeline streaming (capa speed).
El consumidor fusiona ambas capas. Permite validar el streaming sin desactivar el batch.

```
Fuente → Kafka/Kinesis → Pipeline Streaming → Tabla near-real-time
       → S3/HDFS → Pipeline Batch → Tabla histórica (misma tabla, diferente latencia)
```

### Patrón Kappa (solo streaming)
Eliminar el batch. Todo pasa por el pipeline de streaming, incluyendo re-procesos
(replay del topic). Requiere que el topic tenga retención suficiente.

```
Fuente → Kafka/Kinesis → Pipeline Streaming → Tabla (append + compaction)
```

## Ventanas de Tiempo en Streaming

Reemplazar lógica batch por ventanas explícitas:

```python
# Spark Structured Streaming

# Tumbling window (equivalente a batch horario)
df.groupBy(window(col("event_time"), "1 hour"), col("dimension")) \
  .agg(sum("monto").alias("total"))

# Sliding window
df.groupBy(window(col("event_time"), "1 hour", "15 minutes")) \
  .agg(...)

# Session window (inactividad define el cierre)
df.groupBy(session_window(col("event_time"), "10 minutes")) \
  .agg(...)
```

## Checkpointing (obligatorio)

```python
# Sin checkpoint no hay tolerancia a fallos
query = df.writeStream \
    .option("checkpointLocation", "s3://bucket/checkpoints/pipeline-name/") \
    .outputMode("append") \
    .trigger(processingTime="1 minute") \
    .start()
```

## Manejo de Late Data (datos tardíos)

En batch no existe este problema. En streaming es crítico:

```python
# Definir watermark para tolerar datos tardíos hasta N minutos
df.withWatermark("event_time", "10 minutes") \
  .groupBy(window(col("event_time"), "1 hour")) \
  .agg(...)
```

## Dead-Letter Queue

Para eventos que no pueden procesarse (schema inválido, error de deserialización):

```python
def process_event(event):
    try:
        return transform(event)
    except Exception as e:
        send_to_dlq(event, error=str(e))
        return None
```

## Tipos de Datos — Consideraciones Streaming

- Los mensajes en Kafka/Kinesis son bytes → definir schema explícito (Avro, Protobuf, JSON Schema)
- Timestamps en eventos: preferir ISO 8601 o epoch ms — nunca strings sin formato definido
- Schema Registry recomendado para Avro/Protobuf (Confluent Schema Registry, AWS Glue Schema Registry)

## Monitoreo (diferente al batch)

En batch basta con verificar que el job terminó y el conteo cuadra.
En streaming se monitorean métricas continuas:

- **Consumer lag**: registros en el topic que aún no procesó el pipeline
- **Processing latency**: tiempo entre evento producido y evento procesado
- **Throughput**: eventos/segundo
- **Error rate**: % de eventos enviados a DLQ

## Validación al Migrar de Batch a Streaming

1. Ejecutar batch y streaming en paralelo durante un periodo (Lambda pattern)
2. Comparar resultados de ambos para el mismo rango de tiempo
3. Aceptar diferencia pequeña por late data — definir umbral de tolerancia
4. Solo desactivar batch cuando streaming demuestre estabilidad sostenida (1-2 semanas)

## Re-procesamiento

```python
# Kafka: resetear offset para replay
# --from-beginning para reprocesar todo el topic
# --offset para reprocesar desde un punto específico

# Kinesis: usar shard iterator con TRIM_HORIZON o AT_TIMESTAMP
kinesis.get_shard_iterator(
    StreamName='nombre-stream',
    ShardId='shardId-000000000000',
    ShardIteratorType='AT_TIMESTAMP',
    Timestamp=datetime(2024, 1, 1)
)
```
