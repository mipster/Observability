# ZaraLive Observability Stack

A comprehensive observability solution for the ZaraLive project, featuring Prometheus, Jaeger, Grafana, and Loki for metrics, tracing, visualization, and log aggregation.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ZaraLive App  │    │  ZaraLive      │    │   System        │
│   (Node.js)     │    │  Frontend      │    │   Resources     │
│                 │    │  (React)        │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Observability Stack                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐  │
│  │ Prometheus  │ │   Jaeger    │ │   Grafana   │ │  Loki   │  │
│  │ (Metrics)   │ │ (Tracing)   │ │(Dashboard)  │ │(Logs)   │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘  │
│  ┌─────────────┐ ┌─────────────┐                              │
│  │Alertmanager │ │  Promtail   │                              │
│  │ (Alerts)    │ │(Log Agent)  │                              │
│  └─────────────┘ └─────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- At least 4GB of available RAM
- Ports 3000, 9090, 16686, 9093, 3100 available

### 1. Start the Observability Stack
```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

### 2. Access the Services
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **Alertmanager**: http://localhost:9093
- **Loki**: http://localhost:3100

### 3. Verify Setup
```bash
# Check if all containers are running
docker-compose ps

# View logs for a specific service
docker-compose logs prometheus
docker-compose logs grafana
docker-compose logs jaeger
```

## 📊 Service Details

### Prometheus
- **Port**: 9090
- **Purpose**: Metrics collection and storage
- **Targets**: ZaraLive app, frontend, system metrics
- **Retention**: 15 days
- **Alerts**: CPU, memory, disk, application errors

### Jaeger
- **Port**: 16686 (UI), 4317 (gRPC), 4318 (HTTP)
- **Purpose**: Distributed tracing
- **Features**: OTLP support, search, dependency analysis

### Grafana
- **Port**: 3000
- **Credentials**: admin/admin
- **Dashboards**: Pre-configured ZaraLive overview
- **Datasources**: Auto-configured Prometheus, Jaeger, Loki

### Alertmanager
- **Port**: 9093
- **Purpose**: Alert routing and notification
- **Features**: Grouping, inhibition, webhook support

### Loki
- **Port**: 3100
- **Purpose**: Log aggregation
- **Features**: LogQL query language, efficient storage

### Promtail
- **Purpose**: Log shipping agent
- **Targets**: Application logs, system logs, Docker logs

## 🔧 Configuration

### Adding New Metrics Targets
Edit `prometheus/prometheus.yml`:
```yaml
- job_name: 'new-service'
  static_configs:
    - targets: ['host.docker.internal:8080']
  metrics_path: '/metrics'
```

### Customizing Alerts
Edit `prometheus/rules/alerts.yml`:
```yaml
- alert: CustomAlert
  expr: your_promql_expression
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Custom alert description"
```

### Grafana Dashboards
- **Location**: `grafana/dashboards/`
- **Auto-provisioning**: Enabled via `grafana/provisioning/`
- **Customization**: Edit JSON files or use Grafana UI

## 📈 Instrumenting Your Application

### Node.js Backend
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces',
  }),
  metricExporter: new OTLPMetricExporter({
    url: 'http://localhost:4318/v1/metrics',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

### React Frontend
```javascript
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';

const provider = new WebTracerProvider();
const exporter = new OTLPTraceExporter({
  url: 'http://localhost:4318/v1/traces',
});

provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();
```

## 🚨 Monitoring & Alerts

### Key Metrics to Monitor
- **Application**: Request rate, response time, error rate
- **System**: CPU, memory, disk usage
- **Infrastructure**: Container health, network connectivity

### Alert Severity Levels
- **Critical**: Service down, high error rates
- **Warning**: High resource usage, performance degradation
- **Info**: Service restarts, configuration changes

### Alert Channels
- Webhook endpoints
- Email notifications
- Slack/Teams integration (configurable)

## 🔍 Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check container logs
docker-compose logs [service-name]

# Verify port availability
netstat -tulpn | grep :[port]

# Check Docker resources
docker system df
```

#### Metrics Not Appearing
- Verify target endpoints are accessible
- Check Prometheus target status
- Ensure metrics endpoint is exposed (`/metrics`)

#### Traces Not Showing
- Verify OTLP endpoint configuration
- Check Jaeger collector logs
- Ensure application instrumentation is correct

### Performance Tuning
- **Prometheus**: Adjust scrape intervals for high-traffic services
- **Grafana**: Optimize dashboard queries and refresh rates
- **Loki**: Configure log retention and storage policies

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `docker-compose up -d`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Monitoring! 🎉**
