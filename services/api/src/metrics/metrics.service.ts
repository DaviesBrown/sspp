import { Injectable, OnModuleInit } from '@nestjs/common';
import * as client from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry: client.Registry;

  // HTTP Request metrics
  public readonly httpRequestDuration: client.Histogram<string>;
  public readonly httpRequestTotal: client.Counter<string>;

  // Event processing metrics
  public readonly eventsReceived: client.Counter<string>;
  public readonly eventsQueued: client.Counter<string>;
  public readonly eventsQueueErrors: client.Counter<string>;

  // Queue metrics
  public readonly queueSize: client.Gauge<string>;
  public readonly queueProcessingTime: client.Histogram<string>;

  // Signal metrics
  public readonly signalsProcessed: client.Counter<string>;
  public readonly signalScore: client.Histogram<string>;

  // Database metrics
  public readonly dbQueryDuration: client.Histogram<string>;
  public readonly dbConnectionPool: client.Gauge<string>;

  // Redis metrics
  public readonly redisOperationDuration: client.Histogram<string>;
  public readonly redisConnectionStatus: client.Gauge<string>;

  constructor() {
    this.registry = new client.Registry();

    // Default metrics (CPU, memory, etc.)
    client.collectDefaultMetrics({
      register: this.registry,
      prefix: 'sspp_api_',
    });

    // HTTP Request Duration Histogram
    this.httpRequestDuration = new client.Histogram({
      name: 'sspp_api_http_request_duration_seconds',
      help: 'Duration of HTTP requests in seconds',
      labelNames: ['method', 'route', 'status_code'],
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
      registers: [this.registry],
    });

    // HTTP Request Counter
    this.httpRequestTotal = new client.Counter({
      name: 'sspp_api_http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code'],
      registers: [this.registry],
    });

    // Events Received Counter
    this.eventsReceived = new client.Counter({
      name: 'sspp_api_events_received_total',
      help: 'Total number of events received',
      labelNames: ['event_type'],
      registers: [this.registry],
    });

    // Events Queued Counter
    this.eventsQueued = new client.Counter({
      name: 'sspp_api_events_queued_total',
      help: 'Total number of events successfully queued',
      labelNames: ['event_type'],
      registers: [this.registry],
    });

    // Events Queue Errors Counter
    this.eventsQueueErrors = new client.Counter({
      name: 'sspp_api_events_queue_errors_total',
      help: 'Total number of events that failed to queue',
      labelNames: ['event_type', 'error_type'],
      registers: [this.registry],
    });

    // Queue Size Gauge
    this.queueSize = new client.Gauge({
      name: 'sspp_api_queue_size',
      help: 'Current size of the event queue',
      labelNames: ['queue_name', 'state'],
      registers: [this.registry],
    });

    // Queue Processing Time Histogram
    this.queueProcessingTime = new client.Histogram({
      name: 'sspp_api_queue_processing_seconds',
      help: 'Time taken to add events to queue',
      labelNames: ['queue_name'],
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1],
      registers: [this.registry],
    });

    // Signals Processed Counter
    this.signalsProcessed = new client.Counter({
      name: 'sspp_api_signals_processed_total',
      help: 'Total number of signals processed',
      labelNames: ['signal_type'],
      registers: [this.registry],
    });

    // Signal Score Histogram
    this.signalScore = new client.Histogram({
      name: 'sspp_api_signal_score',
      help: 'Distribution of signal scores',
      labelNames: ['signal_type'],
      buckets: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
      registers: [this.registry],
    });

    // Database Query Duration Histogram
    this.dbQueryDuration = new client.Histogram({
      name: 'sspp_api_db_query_duration_seconds',
      help: 'Duration of database queries in seconds',
      labelNames: ['query_type', 'table'],
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
      registers: [this.registry],
    });

    // Database Connection Pool Gauge
    this.dbConnectionPool = new client.Gauge({
      name: 'sspp_api_db_connection_pool',
      help: 'Database connection pool status',
      labelNames: ['state'],
      registers: [this.registry],
    });

    // Redis Operation Duration Histogram
    this.redisOperationDuration = new client.Histogram({
      name: 'sspp_api_redis_operation_duration_seconds',
      help: 'Duration of Redis operations in seconds',
      labelNames: ['operation'],
      buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1],
      registers: [this.registry],
    });

    // Redis Connection Status Gauge
    this.redisConnectionStatus = new client.Gauge({
      name: 'sspp_api_redis_connection_status',
      help: 'Redis connection status (1 = connected, 0 = disconnected)',
      registers: [this.registry],
    });
  }

  onModuleInit() {
    // Initialize Redis connection status to 0 (will be updated by health checks)
    this.redisConnectionStatus.set(0);
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  getContentType(): string {
    return this.registry.contentType;
  }

  // Helper method to track HTTP request timing
  startHttpTimer(method: string, route: string): () => void {
    const end = this.httpRequestDuration.startTimer({ method, route });
    return (statusCode: string) => {
      end({ status_code: statusCode });
      this.httpRequestTotal.inc({ method, route, status_code: statusCode });
    };
  }

  // Helper method to track database query timing
  startDbTimer(queryType: string, table: string): () => void {
    return this.dbQueryDuration.startTimer({ query_type: queryType, table });
  }

  // Helper method to track Redis operation timing
  startRedisTimer(operation: string): () => void {
    return this.redisOperationDuration.startTimer({ operation });
  }

  // Helper method to record event received
  recordEventReceived(eventType: string): void {
    this.eventsReceived.inc({ event_type: eventType });
  }

  // Helper method to record event queued
  recordEventQueued(eventType: string): void {
    this.eventsQueued.inc({ event_type: eventType });
  }

  // Helper method to record queue error
  recordQueueError(eventType: string, errorType: string): void {
    this.eventsQueueErrors.inc({ event_type: eventType, error_type: errorType });
  }

  // Helper method to update queue size
  updateQueueSize(queueName: string, waiting: number, active: number, delayed: number): void {
    this.queueSize.set({ queue_name: queueName, state: 'waiting' }, waiting);
    this.queueSize.set({ queue_name: queueName, state: 'active' }, active);
    this.queueSize.set({ queue_name: queueName, state: 'delayed' }, delayed);
  }
}
