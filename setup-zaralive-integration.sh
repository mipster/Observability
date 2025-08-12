#!/bin/bash

# ZaraLive Project Integration Script
# This script helps set up observability instrumentation in your main ZaraLive project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 ZaraLive Observability Integration Setup"
echo "=========================================="
echo

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "This script must be run from the ZaraLive-Observability directory"
    print_error "Please navigate to the observability project directory and run this script"
    exit 1
fi

print_status "Setting up observability integration for your ZaraLive project..."
echo

# Create integration instructions
cat > ZARALIVE_INTEGRATION.md << 'EOF'
# ZaraLive Observability Integration Guide

## Overview
This guide explains how to integrate your main ZaraLive project with the lean observability stack.

## Prerequisites
1. The observability stack is running (use `./start.sh start`)
2. Your ZaraLive application is accessible on the configured ports

## Backend Integration (Node.js)

### 1. Install Dependencies
```bash
cd /path/to/your/zaralive/project
npm install prom-client
```

### 2. Expose Metrics Endpoint
Add a metrics endpoint to your Express app:
```javascript
const prometheus = require('prom-client');
const register = prometheus.register;

// Create some basic metrics
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

### 3. Add Business Metrics (Optional)
```javascript
// Custom business metrics
const activeConnections = new prometheus.Gauge({
  name: 'zaralive_active_connections',
  help: 'Number of active voice connections'
});

const voiceProcessingDuration = new prometheus.Histogram({
  name: 'zaralive_voice_processing_duration_seconds',
  help: 'Duration of voice processing in seconds',
  buckets: [0.1, 0.5, 1, 2, 5, 10]
});

// Use in your business logic
activeConnections.set(5); // Set current active connections
voiceProcessingDuration.observe(2.5); // Record processing time
```

## Frontend Integration (React)

### 1. Create a Simple Metrics Client
Create `metrics.js` in your src directory:

```javascript
// Simple frontend metrics collection
class FrontendMetrics {
  constructor() {
    this.metrics = {
      pageViews: 0,
      userInteractions: 0,
      errors: 0
    };
  }

  recordPageView(page) {
    this.metrics.pageViews++;
    this.sendMetric('page_view', { page });
  }

  recordUserInteraction(action) {
    this.metrics.userInteractions++;
    this.sendMetric('user_interaction', { action });
  }

  recordError(error) {
    this.metrics.errors++;
    this.sendMetric('frontend_error', { error: error.message });
  }

  sendMetric(type, data) {
    // Send to your backend /metrics endpoint or a separate metrics endpoint
    fetch('/api/metrics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type, data, timestamp: Date.now() })
    }).catch(console.error);
  }
}

export const metrics = new FrontendMetrics();
```

### 2. Use in Your App
```javascript
import { metrics } from './metrics';

function MyComponent() {
  useEffect(() => {
    metrics.recordPageView('MyComponent');
  }, []);
  
  const handleClick = () => {
    metrics.recordUserInteraction('button_click');
  };
  
  return <button onClick={handleClick}>Click me</button>;
}
```

## Testing the Integration

### 1. Start the Observability Stack
```bash
./start.sh start
```

### 2. Start Your ZaraLive Application
```bash
# In your main project directory
npm start
```

### 3. Generate Some Traffic
- Make some API calls
- Navigate through your frontend
- Check the metrics endpoint

### 4. Verify in Observability Tools
- **Prometheus**: http://localhost:9090 (check targets)
- **Grafana**: http://localhost:3001 (view dashboards)
- **Alertmanager**: http://localhost:9093 (configure alerts)

## Troubleshooting

### No Metrics Appearing
- Check if `/metrics` endpoint is accessible
- Verify Prometheus targets in http://localhost:9090/targets
- Check application logs for errors

### Port Conflicts
- Check if ports 3000, 3001, 8080, 9090, 9093, 9100 are available
- Use `./start.sh status` to check current services

## Next Steps

1. **Custom Metrics**: Add business-specific metrics
2. **Alerts**: Configure custom alerting rules in Prometheus
3. **Dashboards**: Create custom Grafana dashboards
4. **Log Correlation**: Add request IDs to your logs

## Support

If you encounter issues:
1. Check the logs: `./start.sh logs [service]`
2. Verify service health: `./start.sh health`
3. Check the troubleshooting section above
4. Review the main README.md for more details
EOF

print_success "Integration guide created: ZARALIVE_INTEGRATION.md"
echo

# Create a simple test script
cat > test-integration.sh << 'EOF'
#!/bin/bash

# Test script to verify observability integration

echo "🧪 Testing ZaraLive Observability Integration..."
echo

# Check if observability stack is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Observability stack is not running. Start it with: ./start.sh start"
    exit 1
fi

echo "✅ Observability stack is running"
echo

# Test endpoints
echo "🔍 Testing service endpoints..."

# Test Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
fi

# Test Grafana
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

# Test Alertmanager
if curl -s http://localhost:9093/-/healthy > /dev/null; then
    echo "✅ Alertmanager is healthy"
else
    echo "❌ Alertmanager is not responding"
fi

# Test Node Exporter
if curl -s http://localhost:9100/metrics > /dev/null; then
    echo "✅ Node Exporter is responding"
else
    echo "❌ Node Exporter is not responding"
fi

echo
echo "🎯 Next steps:"
echo "1. Follow the integration guide in ZARALIVE_INTEGRATION.md"
echo "2. Start your ZaraLive application"
echo "3. Check metrics in Prometheus: http://localhost:9090"
echo "4. View dashboards in Grafana: http://localhost:3001"
echo "5. Configure alerts in Alertmanager: http://localhost:9093"
EOF

chmod +x test-integration.sh
print_success "Test script created: test-integration.sh"
echo

print_status "Integration setup complete! Here's what was created:"
echo
echo "📚 ZARALIVE_INTEGRATION.md - Complete integration guide"
echo "🧪 test-integration.sh - Script to test the setup"
echo
echo "🚀 To get started:"
echo "1. Start the observability stack: ./start.sh start"
echo "2. Follow the integration guide: ZARALIVE_INTEGRATION.md"
echo "3. Test the setup: ./test-integration.sh"
echo
print_success "Your ZaraLive observability stack is ready for integration! 🎉"
