#!/bin/bash

# ZaraLive Project Integration Script
# This script helps set up OpenTelemetry instrumentation in your main ZaraLive project

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
This guide explains how to integrate your main ZaraLive project with the observability stack.

## Prerequisites
1. The observability stack is running (use `./start.sh start`)
2. Your ZaraLive application is accessible on the configured ports

## Backend Integration (Node.js)

### 1. Install Dependencies
```bash
cd /path/to/your/zaralive/project
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-otlp-http
```

### 2. Create Telemetry Configuration
Create `telemetry.js` in your project root:

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');

// Initialize OpenTelemetry
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

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

### 3. Import in Your Main File
Add this line at the very top of your main server file:
```javascript
require('./telemetry');
```

### 4. Expose Metrics Endpoint
Add a metrics endpoint to your Express app:
```javascript
const prometheus = require('prom-client');
const register = prometheus.register;

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

## Frontend Integration (React)

### 1. Install Dependencies
```bash
npm install @opentelemetry/sdk-trace-web @opentelemetry/exporter-otlp-http
```

### 2. Create Telemetry Configuration
Create `telemetry.js` in your src directory:

```javascript
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';

const provider = new WebTracerProvider();
const exporter = new OTLPTraceExporter({
  url: 'http://localhost:4318/v1/traces',
});

provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

// Create a tracer
export const tracer = provider.getTracer('zaralive-frontend');
```

### 3. Import in Your App
Add this import to your main App.js or index.js:
```javascript
import './telemetry';
```

### 4. Use Tracing in Components
```javascript
import { tracer } from './telemetry';

function MyComponent() {
  const span = tracer.startSpan('MyComponent.render');
  
  // Your component logic here
  
  span.end();
  return <div>...</div>;
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
- Check the metrics and traces

### 4. Verify in Observability Tools
- **Prometheus**: http://localhost:9090 (check targets)
- **Jaeger**: http://localhost:16686 (look for traces)
- **Grafana**: http://localhost:3000 (view dashboards)

## Troubleshooting

### No Metrics Appearing
- Check if `/metrics` endpoint is accessible
- Verify Prometheus targets in http://localhost:9090/targets
- Check application logs for telemetry errors

### No Traces Appearing
- Verify OTLP endpoint is accessible
- Check Jaeger collector logs: `./start.sh logs jaeger`
- Ensure telemetry is imported before other modules

### Port Conflicts
- Check if ports 3000, 3001 are available
- Modify config.env if needed
- Use `./start.sh status` to check current services

## Next Steps

1. **Custom Metrics**: Add business-specific metrics
2. **Custom Traces**: Instrument key business flows
3. **Alerts**: Configure custom alerting rules
4. **Dashboards**: Create custom Grafana dashboards
5. **Log Correlation**: Add trace IDs to your logs

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

# Test Jaeger
if curl -s http://localhost:16686/ > /dev/null; then
    echo "✅ Jaeger UI is accessible"
else
    echo "❌ Jaeger UI is not responding"
fi

# Test Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

echo
echo "🎯 Next steps:"
echo "1. Follow the integration guide in ZARALIVE_INTEGRATION.md"
echo "2. Start your ZaraLive application"
echo "3. Check metrics in Prometheus: http://localhost:9090"
echo "4. View dashboards in Grafana: http://localhost:3000"
echo "5. Search traces in Jaeger: http://localhost:16686"
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
