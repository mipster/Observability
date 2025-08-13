#!/bin/bash

# ZaraLive Observability Stack Startup Script
# This script starts the complete observability stack including Loki and MinIO

echo "🚀 Starting ZaraLive Observability Stack..."

# Create data directories if they don't exist
echo "📁 Creating persistent data directories..."
mkdir -p loki-data minio-data prometheus-data grafana-data alertmanager-data

# Set proper permissions for data directories
echo "🔐 Setting permissions for data directories..."
chmod 755 loki-data minio-data prometheus-data grafana-data alertmanager-data

# Start the stack
echo "🐳 Starting Docker Compose services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service status
echo "📊 Checking service status..."
docker-compose ps

echo ""
echo "✅ ZaraLive Observability Stack is starting up!"
echo ""
echo "🌐 Access URLs:"
echo "   Grafana:        http://localhost:3001 (admin/admin)"
echo "   Prometheus:     http://localhost:9090"
echo "   Alertmanager:   http://localhost:9093"
echo "   Loki:          http://localhost:3100"
echo "   MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
echo "   MinIO API:     http://localhost:9000"
echo "   Blackbox Exporter: http://localhost:9115"
echo ""
echo "📊 Dashboards available in Grafana:"
echo "   - ZaraLive Overview"
echo "   - ZaraLive Voice AI"
echo "   - ZaraLive Transcripts (NEW!)"
echo "   - ZaraLive Endpoint Monitoring (NEW!)"
echo ""
echo "🔍 To view logs: docker-compose logs -f [service-name]"
echo "🛑 To stop: docker-compose down"
echo "🔄 To restart: docker-compose restart"
