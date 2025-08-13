#!/usr/bin/env node

/**
 * Test script for ZaraLive transcript logging
 * This script tests the transcript endpoint and verifies logs are being sent
 */

const http = require('http');

const TRANSCRIPT_ENDPOINT = 'http://localhost:8080/api/transcripts';
const LOKI_ENDPOINT = 'http://localhost:3100';

// Sample transcript data
const sampleTranscripts = [
  {
    sessionId: 'test-session-123',
    turnNumber: 1,
    timestamp: Date.now(),
    messageType: 'user',
    content: 'Hello, how are you today?',
    metadata: {
      messageId: 'msg_123',
      turnDuration: 1500,
    },
    context: {
      conversationFlow: 'start',
      userIntent: 'greeting',
    },
  },
  {
    sessionId: 'test-session-123',
    turnNumber: 2,
    timestamp: Date.now() + 1000,
    messageType: 'zara',
    content: 'Hi there! I am doing great, thank you for asking.',
    metadata: {
      messageId: 'msg_124',
      turnDuration: 2000,
      safetyFlags: [],
      vocabularyComplexity: {
        level: 'intermediate',
        complexity: 4,
      },
      grammarComplexity: {
        level: 'basic',
        complexity: 2,
      },
    },
    context: {
      conversationFlow: 'question_response',
      userIntent: 'greeting',
    },
  },
];

function sendTranscript(transcript) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(transcript);

    const options = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/transcripts',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = http.request(options, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`✅ Transcript sent successfully (${res.statusCode})`);
        console.log(
          `   Session: ${transcript.sessionId}, Turn: ${transcript.turnNumber}`
        );
        resolve(data);
      });
    });

    req.on('error', err => {
      console.error(`❌ Error sending transcript: ${err.message}`);
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

function checkLokiLogs() {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent('{job="zaralive-transcripts"}');
    const url = `${LOKI_ENDPOINT}/loki/api/v1/query_range?query=${query}&start=${
      Date.now() - 60000
    }&end=${Date.now()}`;

    const options = {
      hostname: 'localhost',
      port: 3100,
      path: `/loki/api/v1/query_range?query=${query}&start=${
        Date.now() - 60000
      }&end=${Date.now()}`,
      method: 'GET',
    };

    const req = http.request(options, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (
            response.data &&
            response.data.result &&
            response.data.result.length > 0
          ) {
            console.log(
              `📊 Found ${response.data.result.length} log streams in Loki`
            );
            response.data.result.forEach((stream, index) => {
              console.log(
                `   Stream ${index + 1}: ${stream.stream.job || 'unknown'}`
              );
              console.log(`   Values: ${stream.values.length} log entries`);
            });
          } else {
            console.log(
              '📊 No logs found in Loki yet (this is normal for first run)'
            );
          }
          resolve(response);
        } catch (err) {
          console.error('❌ Error parsing Loki response:', err.message);
          reject(err);
        }
      });
    });

    req.on('error', err => {
      console.error(`❌ Error checking Loki: ${err.message}`);
      reject(err);
    });

    req.end();
  });
}

async function runTest() {
  console.log('🧪 Testing ZaraLive Transcript Logging...\n');

  try {
    // Send sample transcripts
    console.log('📤 Sending sample transcripts...');
    for (const transcript of sampleTranscripts) {
      await sendTranscript(transcript);
      // Small delay between requests
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n⏳ Waiting for logs to be processed...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check if logs appear in Loki
    console.log('\n🔍 Checking Loki for logs...');
    await checkLokiLogs();

    console.log('\n✅ Test completed!');
    console.log('\n📋 Next steps:');
    console.log('   1. Check Grafana at http://localhost:3001');
    console.log('   2. View the "ZaraLive Transcripts" dashboard');
    console.log('   3. Query logs in Loki using: {job="zaralive-transcripts"}');
    console.log('   4. Check MinIO console at http://localhost:9001');
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   - Ensure your ZaraLive server is running on port 8080');
    console.log(
      '   - Ensure the observability stack is running (./start-observability.sh)'
    );
    console.log('   - Check Docker Compose logs: docker-compose logs -f');
  }
}

// Run the test
runTest();
