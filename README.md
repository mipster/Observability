# ZaraLive Observability Stack

A lean observability solution for the ZaraLive project, featuring Prometheus, Grafana, and Alertmanager for metrics, visualization, and alerting.

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
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │ Prometheus  │ │   Grafana   │ │Alertmanager │              │
│  │ (Metrics)   │ │(Dashboard)  │ │ (Alerts)    │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
│  ┌─────────────┐                                              │
│  │Node Exporter│                                              │
│  │(System)     │                                              │
│  └─────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- At least 2GB of available RAM
- Ports 3000, 3001, 8080, 9090, 9093, 9100 available

### 1. Start the Observability Stack

```bash
# Start all services
./start.sh start

# Check service status
./start.sh status
```

### 2. Access the Services

- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **Node Exporter**: http://localhost:9100

### 3. Verify Setup

```bash
# Check if all containers are running
docker-compose ps

# View logs for a specific service
docker-compose logs prometheus
docker-compose logs grafana

# Check service health
./start.sh health
```

## 📊 Service Details

### Prometheus

- **Port**: 9090
- **Purpose**: Metrics collection and storage
- **Targets**: ZaraLive app, system metrics
- **Retention**: 15 days
- **Alerts**: CPU, memory, disk, application errors

### Grafana

- **Port**: 3001
- **Credentials**: admin/admin
- **Dashboards**: Pre-configured ZaraLive overview
- **Datasources**: Auto-configured Prometheus

### Alertmanager

- **Port**: 9093
- **Purpose**: Alert routing and notification
- **Features**: Grouping, inhibition, webhook support

### Node Exporter

- **Port**: 9100
- **Purpose**: System metrics collection
- **Metrics**: CPU, memory, disk, network usage

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
    summary: 'Custom alert description'
```

### Grafana Dashboards

- **Location**: `grafana/dashboards/`
- **Auto-provisioning**: Enabled via `grafana/provisioning/`
- **Customization**: Edit JSON files or use Grafana UI

## 📈 Instrumenting Your Application

### Node.js Backend

```javascript
const prometheus = require('prom-client');
const register = prometheus.register;

// Create metrics
const httpRequestDurationMicroseconds = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

// Middleware to collect metrics
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDurationMicroseconds
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
  });
  
  next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### React Frontend

```javascript
// Simple frontend metrics collection
class FrontendMetrics {
  recordPageView(page) {
    // Send to your backend /metrics endpoint
    fetch('/api/metrics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'page_view', page, timestamp: Date.now() })
    });
  }
}

export const metrics = new FrontendMetrics();
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
./start.sh logs [service-name]

# Verify port availability
./start.sh status

# Check Docker resources
docker system df
```

#### Metrics Not Appearing

- Verify target endpoints are accessible
- Check Prometheus target status
- Ensure metrics endpoint is exposed (`/metrics`)

### Performance Tuning

- **Prometheus**: Adjust scrape intervals for high-traffic services
- **Grafana**: Optimize dashboard queries and refresh rates

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node.js Prometheus Client](https://github.com/siimon/prom-client)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./start.sh start`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Monitoring! 🎉**
