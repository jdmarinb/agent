# Reference: Batch → Streaming

Applies when a pipeline that processes data in batches (daily, hourly, weekly) is migrated to real-time or near-real-time processing.

## Common Tools

| Platform | Streaming Engine |
|---|---|
| AWS | Kinesis Data Streams, MSK (Kafka), Kinesis Firehose |
| GCP | Pub/Sub + Dataflow (Apache Beam) |
| Azure | Event Hubs, Stream Analytics |
| On-prem / Multi-cloud | Apache Kafka + Spark Structured Streaming / Flink |

## Conceptual Differences: Batch vs. Streaming

| Batch | Streaming |
|---|---|
| Processes a historical data block | Processes events as they arrive |
| Runs on a schedule (cron) | Runs continuously |
| Latency: minutes to hours | Latency: milliseconds to seconds |
| Reprocessing is trivial (rerun job) | Reprocessing requires topic replay |
| State: stateless or full in memory | State: requires explicit management (checkpoints) |
| Errors: retry the batch | Errors: dead-letter queue + alerts |

## Migration Patterns

### Lambda Pattern (Recommended for transition)
Maintain the batch pipeline (batch layer) and add a streaming pipeline (speed layer). The consumer merges both layers. Allows validating streaming without disabling batch.

```
Source → Kafka/Kinesis → Streaming Pipeline → Near-real-time table
       → S3/HDFS → Batch Pipeline → Historical table (same table, different latency)
```

### Kappa Pattern (Streaming only)
Eliminate the batch. Everything passes through the streaming pipeline, including reprocessing (topic replay). Requires the topic to have sufficient retention.

```
Source → Kafka/Kinesis → Streaming Pipeline → Table (append + compaction)
```

## Time Windows in Streaming

Replace batch logic with explicit windows:

```python
# Spark Structured Streaming

# Tumbling window (equivalent to hourly batch)
df.groupBy(window(col("event_time"), "1 hour"), col("dimension")) \
  .agg(sum("amount").alias("total"))

# Sliding window
df.groupBy(window(col("event_time"), "1 hour", "15 minutes")) \
  .agg(...)

# Session window (inactivity defines the close)
df.groupBy(session_window(col("event_time"), "10 minutes")) \
  .agg(...)
```

## Checkpointing (Mandatory)

```python
# Fault tolerance requires a checkpoint
query = df.writeStream \
    .option("checkpointLocation", "s3://bucket/checkpoints/pipeline-name/") \
    .outputMode("append") \
    .trigger(processingTime="1 minute") \
    .start()
```

## Late Data Handling (Watermarking)

Batch doesn't have this issue. In streaming, it's critical:

```python
# Define watermark to tolerate late data up to N minutes
df.withWatermark("event_time", "10 minutes") \
  .groupBy(window(col("event_time"), "1 hour")) \
  .agg(...)
```

## Dead-Letter Queue

For events that cannot be processed (invalid schema, deserialization error):

```python
def process_event(event):
    try:
        return transform(event)
    except Exception as e:
        send_to_dlq(event, error=str(e))
        return None
```

## Data Types — Streaming Considerations

- Kafka/Kinesis messages are bytes → define explicit schema (Avro, Protobuf, JSON Schema).
- Timestamps in events: prefer ISO 8601 or epoch ms — never unformatted strings.
- Schema Registry recommended for Avro/Protobuf (Confluent Schema Registry, AWS Glue Schema Registry).

## Monitoring (Different from Batch)

In batch, it's enough to verify the job finished and counts match. In streaming, continuous metrics are monitored:

- **Consumer lag**: Records in the topic not yet processed by the pipeline.
- **Processing latency**: Time between event produced and event processed.
- **Throughput**: Events per second.
- **Error rate**: % of events sent to DLQ.

## Validation when Migrating Batch to Streaming

1. Run batch and streaming in parallel for a period (Lambda pattern).
2. Compare results of both for the same time range.
3. Accept small differences due to late data — define a tolerance threshold.
4. Only disable batch when streaming demonstrates sustained stability (1-2 weeks).

## Reprocessing

```python
# Kafka: reset offset for replay
# --from-beginning to reprocess the entire topic
# --offset to reprocess from a specific point

# Kinesis: use shard iterator with TRIM_HORIZON or AT_TIMESTAMP
kinesis.get_shard_iterator(
    StreamName='stream-name',
    ShardId='shardId-000000000000',
    ShardIteratorType='AT_TIMESTAMP',
    Timestamp=datetime(2024, 1, 1)
)
```
