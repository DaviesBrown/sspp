import { getPool } from '../database/connection';
import { getElasticsearchClient } from '../elasticsearch/connection';
import { logger } from '../utils/logger';
import { calculateSignalScore } from '../utils/signal-calculator';

interface SalesEvent {
  accountId: string;
  userId: string;
  eventType: string;
  timestamp: string;
  metadata?: Record<string, any>;
}

interface ProcessedSignal {
  id: string;
  accountId: string;
  userId: string;
  eventType: string;
  signalType: string;
  signalScore: number;
  timestamp: Date;
  processedAt: Date;
  metadata?: Record<string, any>;
}

export async function processEvent(event: SalesEvent): Promise<ProcessedSignal> {
  const pool = getPool();
  const esClient = getElasticsearchClient();

  // Calculate signal
  const signalType = determineSignalType(event.eventType);
  const signalScore = calculateSignalScore(event.eventType, event.metadata);

  const processedAt = new Date();
  const timestamp = new Date(event.timestamp);

  // Store in PostgreSQL
  const query = `
    INSERT INTO sales_signals (
      account_id, user_id, event_type, signal_type, signal_score, 
      timestamp, processed_at, metadata
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING id
  `;

  const values = [
    event.accountId,
    event.userId,
    event.eventType,
    signalType,
    signalScore,
    timestamp,
    processedAt,
    JSON.stringify(event.metadata || {}),
  ];

  const result = await pool.query(query, values);
  const signalId = result.rows[0].id;

  logger.info('Signal stored in PostgreSQL', { signalId });

  // Index in Elasticsearch
  await esClient.index({
    index: 'sales-signals',
    id: signalId,
    document: {
      accountId: event.accountId,
      userId: event.userId,
      eventType: event.eventType,
      signalType,
      signalScore,
      timestamp,
      processedAt,
      metadata: event.metadata,
    },
  });

  logger.info('Signal indexed in Elasticsearch', { signalId });

  return {
    id: signalId,
    accountId: event.accountId,
    userId: event.userId,
    eventType: event.eventType,
    signalType,
    signalScore,
    timestamp,
    processedAt,
    metadata: event.metadata,
  };
}

function determineSignalType(eventType: string): string {
  const mapping: Record<string, string> = {
    email_sent: 'outreach',
    email_opened: 'engagement',
    email_clicked: 'high_engagement',
    meeting_booked: 'intent',
    call_made: 'outreach',
    demo_completed: 'high_intent',
  };

  return mapping[eventType] || 'unknown';
}
