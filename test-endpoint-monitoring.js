#!/usr/bin/env node

/**
 * Test script for ZaraLive Endpoint Monitoring
 * This script tests the Blackbox Exporter and endpoint health checks
 */

const http = require('http');

const BLACKBOX_ENDPOINT = 'http://localhost:9115';
const ZARALIVE_ENDPOINT = 'http://localhost:8080';

// Test endpoints to monitor
const testEndpoints = [
  {
    name: 'Transcript Endpoint',
    url: 'http://localhost:8080/api/transcripts',
    method: 'POST',
    body: JSON.stringify({
      sessionId: 'health-check',
      turnNumber: 0,
      timestamp: Date.now(),
      messageType: 'system',
      content: 'health_check',
      metadata: {},
      context: {},
    }),
  },
  {
    name: 'Metrics Endpoint',
    url: 'http://localhost:8080/metrics',
    method: 'GET',
  },
  {
    name: 'Health Endpoint',
    url: 'http://localhost:8080/health',
    method: 'GET',
  },
];

function testEndpoint(endpoint) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint.url);

    const options = {
      hostname: url.hostname,
      port: url.port || 80,
      path: url.pathname,
      method: endpoint.method,
      headers: {
        'User-Agent': 'Prometheus/Blackbox Exporter',
        'Content-Type': 'application/json',
      },
    };

    if (endpoint.body) {
      options.headers['Content-Length'] = Buffer.byteLength(endpoint.body);
    }

    const req = http.request(options, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        const success = res.statusCode >= 200 && res.statusCode < 300;
        resolve({
          name: endpoint.name,
          url: endpoint.url,
          statusCode: res.statusCode,
          success,
          responseTime: Date.now() - startTime,
        });
      });
    });

    req.on('error', err => {
      resolve({
        name: endpoint.name,
        url: endpoint.url,
        statusCode: 0,
        success: false,
        error: err.message,
        responseTime: Date.now() - startTime,
      });
    });

    const startTime = Date.now();

    if (endpoint.body) {
      req.write(endpoint.body);
    }

    req.end();
  });
}

function checkBlackboxExporter() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 9115,
      path: '/probe?module=http_2xx&target=http://localhost:8080/health',
      method: 'GET',
    };

    const req = http.request(options, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          // Parse the response to check if it contains metrics
          if (data.includes('probe_success')) {
            resolve(true);
          } else {
            resolve(false);
          }
        } else {
          resolve(false);
        }
      });
    });

    req.on('error', err => {
      resolve(false);
    });

    req.end();
  });
}

async function runTests() {
  console.log('🧪 Testing ZaraLive Endpoint Monitoring...\n');

  try {
    // Test direct endpoint health
    console.log('📡 Testing direct endpoint health...');
    const results = await Promise.all(testEndpoints.map(testEndpoint));

    results.forEach(result => {
      if (result.success) {
        console.log(
          `✅ ${result.name}: UP (${result.statusCode}) - ${result.responseTime}ms`
        );
      } else {
        console.log(
          `❌ ${result.name}: DOWN - ${
            result.error || `Status ${result.statusCode}`
          }`
        );
      }
    });

    console.log('\n🔍 Testing Blackbox Exporter...');
    const blackboxWorking = await checkBlackboxExporter();

    if (blackboxWorking) {
      console.log('✅ Blackbox Exporter is working and returning metrics');
    } else {
      console.log('❌ Blackbox Exporter is not responding correctly');
    }

    console.log('\n📊 Checking Prometheus targets...');
    console.log(
      '   Visit http://localhost:9090/targets to see all monitored endpoints'
    );
    console.log(
      '   Look for jobs: "blackbox" and "blackbox-transcript-endpoint"'
    );

    console.log('\n📈 Checking Grafana dashboards...');
    console.log(
      '   - ZaraLive Endpoint Monitoring: http://localhost:3001/d/zaralive-endpoints'
    );
    console.log(
      '   - ZaraLive Transcripts: http://localhost:3001/d/zaralive-transcripts'
    );

    console.log('\n✅ Endpoint monitoring test completed!');
    console.log('\n📋 What you should see:');
    console.log(
      '   1. All endpoints showing as UP in the Endpoint Monitoring dashboard'
    );
    console.log('   2. Response time graphs for each endpoint');
    console.log('   3. HTTP status codes and success rates');
    console.log('   4. Alerts if endpoints go down or become slow');
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   - Ensure your ZaraLive server is running on port 8080');
    console.log(
      '   - Ensure the observability stack is running (./start-observability.sh)'
    );
    console.log(
      '   - Check if Blackbox Exporter is running: docker-compose ps blackbox-exporter'
    );
    console.log(
      '   - Check Blackbox Exporter logs: docker-compose logs -f blackbox-exporter'
    );
  }
}

// Run the tests
runTests();
