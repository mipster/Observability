/**
 * ZaraLive Transcript Logger
 *
 * This module provides utilities for logging transcripts to Loki
 * and generating Prometheus metrics for transcript analysis.
 */

const http = require('http');

class TranscriptLogger {
  constructor(options = {}) {
    this.lokiEndpoint = options.lokiEndpoint || 'http://localhost:3100';
    this.serviceName = options.serviceName || 'zaralive-transcripts';
    this.enabled = options.enabled !== false;

    // Prometheus metrics (these would be integrated with your existing metrics)
    this.metrics = {
      transcriptEntriesTotal: 0,
      transcriptErrorsTotal: 0,
      lastTranscriptTimestamp: null,
    };
  }

  /**
   * Log a transcript entry to Loki
   * @param {Object} transcript - The transcript data
   * @param {string} transcript.sessionId - Session identifier
   * @param {number} transcript.turnNumber - Turn number in conversation
   * @param {number} transcript.timestamp - Unix timestamp
   * @param {string} transcript.messageType - Type of message (user, zara, system)
   * @param {string} transcript.content - The transcript text
   * @param {Object} transcript.metadata - Additional metadata
   * @param {Object} transcript.context - Conversation context
   */
  async logTranscript(transcript) {
    if (!this.enabled) {
      console.log('Transcript logging disabled');
      return;
    }

    try {
      // Prepare log entry for Loki
      const logEntry = this.prepareLogEntry(transcript);

      // Send to Loki
      await this.sendToLoki(logEntry);

      // Update metrics
      this.updateMetrics(transcript, 'success');

      console.log(
        `✅ Transcript logged: ${transcript.sessionId} turn ${transcript.turnNumber}`
      );
    } catch (error) {
      console.error('❌ Failed to log transcript:', error.message);
      this.updateMetrics(transcript, 'error');
      throw error;
    }
  }

  /**
   * Prepare log entry for Loki
   */
  prepareLogEntry(transcript) {
    const timestamp = new Date(transcript.timestamp).toISOString();

    // Extract safety flags
    const safetyFlags = transcript.metadata?.safetyFlags || [];
    const safetyFlagsStr =
      safetyFlags.length > 0 ? safetyFlags.join(',') : 'none';

    // Extract complexity scores
    const vocabComplexity =
      transcript.metadata?.vocabularyComplexity?.level || 'unknown';
    const grammarComplexity =
      transcript.metadata?.grammarComplexity?.level || 'unknown';

    // Calculate content length
    const contentLength = transcript.content?.length || 0;

    return {
      streams: [
        {
          stream: {
            job: this.serviceName,
            session_id: transcript.sessionId,
            message_type: transcript.messageType,
            turn_number: transcript.turnNumber.toString(),
            content_length: contentLength.toString(),
            safety_flags: safetyFlagsStr,
            vocabulary_complexity: vocabComplexity,
            grammar_complexity: grammarComplexity,
            conversation_flow:
              transcript.context?.conversationFlow || 'unknown',
            user_intent: transcript.context?.userIntent || 'unknown',
          },
          values: [
            [
              (transcript.timestamp * 1000000).toString(), // Loki expects nanoseconds
              JSON.stringify({
                timestamp: timestamp,
                level: 'info',
                message: 'Transcript recorded',
                sessionId: transcript.sessionId,
                turnNumber: transcript.turnNumber,
                messageType: transcript.messageType,
                content: transcript.content,
                metadata: transcript.metadata,
                context: transcript.context,
                // Additional fields for analysis
                contentLength: contentLength,
                safetyFlags: safetyFlags,
                vocabularyComplexity: vocabComplexity,
                grammarComplexity: grammarComplexity,
                turnDuration: transcript.metadata?.turnDuration || 0,
                messageId: transcript.metadata?.messageId || 'unknown',
              }),
            ],
          ],
        },
      ],
    };
  }

  /**
   * Send log entry to Loki
   */
  async sendToLoki(logEntry) {
    return new Promise((resolve, reject) => {
      const postData = JSON.stringify(logEntry);

      const options = {
        hostname: 'localhost',
        port: 3100,
        path: '/loki/api/v1/push',
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
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(data);
          } else {
            reject(
              new Error(`Loki responded with status ${res.statusCode}: ${data}`)
            );
          }
        });
      });

      req.on('error', err => {
        reject(new Error(`Failed to send to Loki: ${err.message}`));
      });

      req.write(postData);
      req.end();
    });
  }

  /**
   * Update internal metrics
   */
  updateMetrics(transcript, status) {
    if (status === 'success') {
      this.metrics.transcriptEntriesTotal++;
      this.metrics.lastTranscriptTimestamp = Date.now();
    } else {
      this.metrics.transcriptErrorsTotal++;
    }
  }

  /**
   * Get current metrics (for Prometheus integration)
   */
  getMetrics() {
    return {
      transcript_entries_total: this.metrics.transcriptEntriesTotal,
      transcript_errors_total: this.metrics.transcriptErrorsTotal,
      last_transcript_timestamp: this.metrics.lastTranscriptTimestamp,
    };
  }

  /**
   * Batch log multiple transcripts
   */
  async logTranscripts(transcripts) {
    const results = [];

    for (const transcript of transcripts) {
      try {
        await this.logTranscript(transcript);
        results.push({ transcript, status: 'success' });
      } catch (error) {
        results.push({ transcript, status: 'error', error: error.message });
      }
    }

    return results;
  }

  /**
   * Search transcripts in Loki
   */
  async searchTranscripts(query, startTime, endTime) {
    const encodedQuery = encodeURIComponent(query);
    const start = startTime || Date.now() - 24 * 60 * 60 * 1000; // Default to last 24h
    const end = endTime || Date.now();

    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'localhost',
        port: 3100,
        path: `/loki/api/v1/query_range?query=${encodedQuery}&start=${
          start * 1000000
        }&end=${end * 1000000}`,
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
            resolve(response);
          } catch (err) {
            reject(new Error(`Failed to parse Loki response: ${err.message}`));
          }
        });
      });

      req.on('error', err => {
        reject(new Error(`Failed to query Loki: ${err.message}`));
      });

      req.end();
    });
  }

  /**
   * Get transcript statistics
   */
  async getTranscriptStats(timeRange = '1h') {
    const end = Date.now();
    let start;

    switch (timeRange) {
      case '1h':
        start = end - 60 * 60 * 1000;
        break;
      case '24h':
        start = end - 24 * 60 * 60 * 1000;
        break;
      case '7d':
        start = end - 7 * 24 * 60 * 60 * 1000;
        break;
      default:
        start = end - 60 * 60 * 1000; // Default to 1h
    }

    try {
      const userQuery = `{job="${this.serviceName}", message_type="user"}`;
      const zaraQuery = `{job="${this.serviceName}", message_type="zara"}`;

      const [userLogs, zaraLogs] = await Promise.all([
        this.searchTranscripts(userQuery, start, end),
        this.searchTranscripts(zaraQuery, start, end),
      ]);

      return {
        timeRange,
        userMessages: userLogs.data?.result?.[0]?.values?.length || 0,
        zaraMessages: zaraLogs.data?.result?.[0]?.values?.length || 0,
        totalMessages:
          (userLogs.data?.result?.[0]?.values?.length || 0) +
          (zaraLogs.data?.result?.[0]?.values?.length || 0),
        startTime: new Date(start).toISOString(),
        endTime: new Date(end).toISOString(),
      };
    } catch (error) {
      console.error('Failed to get transcript stats:', error.message);
      return null;
    }
  }
}

// Export the class
module.exports = TranscriptLogger;

// Example usage (if run directly)
if (require.main === module) {
  const logger = new TranscriptLogger();

  // Example transcript
  const exampleTranscript = {
    sessionId: 'example-session-123',
    turnNumber: 1,
    timestamp: Math.floor(Date.now() / 1000),
    messageType: 'user',
    content: 'Hello, this is a test transcript',
    metadata: {
      messageId: 'msg_example_123',
      turnDuration: 1500,
    },
    context: {
      conversationFlow: 'start',
      userIntent: 'greeting',
    },
  };

  // Test logging
  logger
    .logTranscript(exampleTranscript)
    .then(() => {
      console.log('Example transcript logged successfully');
      return logger.getTranscriptStats('1h');
    })
    .then(stats => {
      console.log('Transcript stats:', stats);
    })
    .catch(error => {
      console.error('Error:', error.message);
    });
}
