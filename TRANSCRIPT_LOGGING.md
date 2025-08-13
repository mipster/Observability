# ZaraLive Transcript Logging with Loki + MinIO

This document describes the complete transcript logging setup for ZaraLive using Loki for log aggregation and MinIO for object storage.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ZaraLive      │    │      Loki       │    │     MinIO       │
│   Server        │───▶│   (Log Store)   │───▶│  (Object Store) │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │     Grafana     │    │   MinIO Console │
│   (Metrics)     │    │   (Dashboards)  │    │   (Web UI)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│ Blackbox        │    │   Endpoint      │
│ Exporter        │    │   Monitoring    │
│ (Health Checks) │    │   Dashboard     │
└─────────────────┘    └─────────────────┘
```

## Services Added

### 1. Loki (Log Aggregation)

- **Port**: 3100
- **Purpose**: Stores and indexes transcript logs
- **Storage**: Local filesystem with persistent volume mapping
- **Features**:
  - Log querying and filtering
  - Label-based indexing
  - Integration with Grafana

### 2. MinIO (Object Storage)

- **Ports**: 9000 (API), 9001 (Console)
- **Purpose**: Stores transcript data, audio files, and other assets
- **Credentials**: minioadmin/minioadmin (default)
- **Features**:
  - S3-compatible API
  - Web-based management console
  - Persistent storage

### 3. Blackbox Exporter (Endpoint Monitoring)

- **Port**: 9115
- **Purpose**: Monitors HTTP endpoint health and availability
- **Features**:
  - HTTP/HTTPS endpoint probing
  - Response time monitoring
  - Status code validation
  - Custom probe configurations

## Getting Started

### 1. Start the Observability Stack

```bash
# Make the script executable (first time only)
chmod +x start-observability.sh

# Start all services
./start-observability.sh
```

### 2. Verify Services

```bash
# Check service status
docker-compose ps

# View logs for a specific service
docker-compose logs -f loki
docker-compose logs -f minio
docker-compose logs -f blackbox-exporter
```

### 3. Access the Services

- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **MinIO API**: http://localhost:9000
- **Blackbox Exporter**: http://localhost:9115

## Transcript Logging

### How It Works

1. **Transcript Endpoint**: Your `/api/transcripts` endpoint receives transcript data
2. **Log Generation**: Transcripts are logged with structured labels
3. **Loki Storage**: Logs are stored in Loki with full-text search capabilities
4. **Metrics**: Prometheus metrics are generated for analytics
5. **Dashboard**: Grafana displays real-time transcript insights

### Log Structure

Each transcript log entry includes:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "info",
  "message": "Transcript recorded",
  "labels": {
    "job": "zaralive-transcripts",
    "session_id": "sess_123",
    "message_type": "user",
    "turn_number": "1",
    "content_length": "25",
    "safety_flags": "none",
    "vocabulary_complexity": "intermediate",
    "grammar_complexity": "basic"
  },
  "metadata": {
    "sessionId": "sess_123",
    "turnNumber": 1,
    "messageType": "user",
    "content": "Hello, how are you today?",
    "timestamp": 1705312200000,
    "metadata": { ... },
    "context": { ... }
  }
}
```

## Endpoint Monitoring

### What Gets Monitored

The Blackbox Exporter automatically monitors:

1. **Transcript Endpoint**: `/api/transcripts` (POST)
2. **Metrics Endpoint**: `/metrics` (GET)
3. **Health Endpoint**: `/health` (GET)
4. **Provider Info**: `/api/realtime/provider-info` (GET)

### Monitoring Metrics

For each endpoint, Prometheus collects:

- **`probe_success`**: 1 if endpoint is up, 0 if down
- **`probe_duration_seconds`**: Response time in seconds
- **`probe_http_status_code`**: HTTP status code returned
- **`probe_http_version`**: HTTP version used
- **`probe_ssl_earliest_cert_expiry`**: SSL certificate expiry (if HTTPS)

### Querying Endpoint Metrics

#### Basic Health Queries

```promql
# Check if transcript endpoint is up
probe_success{job="blackbox-transcript-endpoint"}

# Check response time
probe_duration_seconds{job="blackbox-transcript-endpoint"}

# Check HTTP status codes
probe_http_status_code{job="blackbox-transcript-endpoint"}
```

#### Advanced Monitoring Queries

```promql
# Success rate over time
rate(probe_success{job="blackbox-transcript-endpoint"}[5m])

# Average response time
rate(probe_duration_seconds_sum{job="blackbox-transcript-endpoint"}[5m]) /
rate(probe_duration_seconds_count{job="blackbox-transcript-endpoint"}[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(probe_duration_seconds_bucket{job="blackbox-transcript-endpoint"}[5m]))
```

## Grafana Dashboards

### 1. ZaraLive Transcripts Dashboard

The transcript dashboard provides:

1. **Recent Transcripts**: Live log stream from Loki
2. **Transcript Entry Rate**: Prometheus metrics for throughput
3. **Total Entries**: Cumulative count by message type
4. **Turn Duration**: 95th percentile response times
5. **Safety Flag Rate**: Monitoring for flagged content
6. **Complexity Score Distribution**: Language analysis metrics

### 2. ZaraLive Endpoint Monitoring Dashboard

The endpoint monitoring dashboard provides:

1. **Endpoint Status**: UP/DOWN status for all monitored endpoints
2. **Response Time**: Real-time response time graphs
3. **HTTP Status Codes**: Current status codes for each endpoint
4. **Success Rate**: Success rate trends over time
5. **Blackbox Exporter Status**: Monitoring system health

### Dashboard Features

- **Real-time Updates**: 5-10 second refresh intervals
- **Interactive Metrics**: Click on metrics to see detailed views
- **Alert Integration**: Visual indicators for alert conditions
- **Time Range Selection**: Flexible time windows for analysis

## MinIO Object Storage

### Use Cases

1. **Transcript Archives**: Long-term storage of conversation logs
2. **Audio Files**: Store voice recordings and TTS outputs
3. **Analytics Exports**: Export conversation data for analysis
4. **Compliance**: Store data for regulatory requirements

### Bucket Structure

```
zaralive/
├── transcripts/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 15/
│   │   │   └── 16/
│   │   └── 02/
│   └── sessions/
│       ├── sess_123/
│       └── sess_124/
├── audio/
│   ├── recordings/
│   └── tts/
└── exports/
    ├── analytics/
    └── compliance/
```

### S3 API Access

```bash
# Using AWS CLI (configure with MinIO endpoint)
aws s3 ls s3://zaralive/transcripts/ --endpoint-url http://localhost:9000

# Using curl
curl -X GET "http://localhost:9000/zaralive/transcripts/" \
  -H "Authorization: AWS4-HMAC-SHA256 ..."
```

## Testing

### Run the Test Scripts

```bash
# Test transcript logging
node test-transcript-logging.js

# Test endpoint monitoring
node test-endpoint-monitoring.js
```

These scripts:

1. Send sample transcripts to your endpoint
2. Verify logs appear in Loki
3. Test endpoint health monitoring
4. Verify Blackbox Exporter functionality
5. Provide troubleshooting guidance

### Manual Testing

```bash
# Test transcript endpoint
curl -X POST http://localhost:8080/api/transcripts \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "test-123",
    "turnNumber": 1,
    "timestamp": 1705312200000,
    "messageType": "user",
    "content": "Hello, world!",
    "metadata": {
      "messageId": "msg_123",
      "turnDuration": 1000
    },
    "context": {
      "conversationFlow": "start",
      "userIntent": "greeting"
    }
  }'

# Test Blackbox Exporter
curl "http://localhost:9115/probe?module=http_transcript_endpoint&target=http://localhost:8080/api/transcripts"

# Check Loki for logs
curl "http://localhost:3100/loki/api/v1/query_range?query={job=\"zaralive-transcripts\"}&start=1705312200000&end=1705312260000"
```

## Monitoring and Alerting

### Key Metrics to Monitor

1. **Transcript Volume**: `rate(zaralive_transcript_entries_total[5m])`
2. **Error Rate**: `rate(zaralive_transcript_entries_total{status="error"}[5m])`
3. **Safety Flags**: `rate(zaralive_transcript_entries_total{metadata_safetyFlags!=""}[5m])`
4. **Turn Duration**: `histogram_quantile(0.95, rate(zaralive_transcript_turn_duration_seconds_bucket[5m]))`
5. **Endpoint Health**: `probe_success{job="blackbox-transcript-endpoint"}`
6. **Response Time**: `probe_duration_seconds{job="blackbox-transcript-endpoint"}`

### Recommended Alerts

```yaml
# High error rate
- alert: HighTranscriptErrorRate
  expr: rate(zaralive_transcript_entries_total{status="error"}[5m]) > 0.1
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: 'High transcript error rate detected'

# Safety flag threshold
- alert: HighSafetyFlagRate
  expr: rate(zaralive_transcript_entries_total{metadata_safetyFlags!=""}[5m]) > 0.05
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: 'High rate of safety-flagged content'

# Transcript endpoint down
- alert: TranscriptEndpointDown
  expr: probe_success{job="blackbox-transcript-endpoint"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: 'Transcript endpoint is down'

# Slow response time
- alert: TranscriptEndpointSlow
  expr: probe_duration_seconds{job="blackbox-transcript-endpoint"} > 2
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: 'Transcript endpoint is slow'
```

## Troubleshooting

### Common Issues

1. **Loki not receiving logs**

   - Check if Loki service is running: `docker-compose ps loki`
   - Verify network connectivity: `docker-compose exec loki ping grafana`
   - Check Loki logs: `docker-compose logs -f loki`

2. **MinIO access issues**

   - Verify credentials: minioadmin/minioadmin
   - Check if MinIO is running: `docker-compose ps minio`
   - Access console at http://localhost:9001

3. **Dashboard not showing data**

   - Verify Loki datasource in Grafana
   - Check if logs are being generated
   - Verify time range selection

4. **Endpoint monitoring not working**

   - Check if Blackbox Exporter is running: `docker-compose ps blackbox-exporter`
   - Verify Prometheus targets at http://localhost:9090/targets
   - Check Blackbox Exporter logs: `docker-compose logs -f blackbox-exporter`

### Log Locations

- **Loki Data**: `./loki-data/`
- **MinIO Data**: `./minio-data/`
- **Prometheus Data**: `./prometheus-data/`
- **Grafana Data**: `./grafana-data/`

### Performance Tuning

1. **Loki Retention**: Adjust in `loki/local-config.yaml`
2. **MinIO Storage**: Monitor disk usage in persistent volumes
3. **Grafana Refresh**: Adjust dashboard refresh intervals
4. **Blackbox Exporter**: Adjust probe intervals in Prometheus config

## Next Steps

1. **Custom Logging**: Integrate transcript logging into your server code
2. **Alerting**: Set up Prometheus alerts for transcript and endpoint issues
3. **Retention Policies**: Configure log retention based on compliance needs
4. **Backup Strategy**: Implement backup for persistent data volumes
5. **Scaling**: Consider distributed Loki setup for production
6. **Custom Endpoints**: Add monitoring for additional API endpoints

## Support

For issues or questions:

1. Check service logs: `docker-compose logs -f [service]`
2. Verify network connectivity between services
3. Check persistent volume permissions
4. Review configuration files for syntax errors
5. Test individual components with the provided test scripts
