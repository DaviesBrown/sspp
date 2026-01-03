import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { CreateEventDto } from './dto/create-event.dto';
import { MetricsService } from '../metrics/metrics.service';

@Injectable()
export class EventsService {
  private readonly logger = new Logger(EventsService.name);

  constructor(
    @InjectQueue(process.env.QUEUE_NAME || 'sales-events')
    private readonly eventQueue: Queue,
    private readonly metricsService: MetricsService,
  ) {}

  async queueEvent(event: CreateEventDto): Promise<string> {
    this.logger.log(`Queueing event: ${event.eventType} for ${event.accountId}`);
    
    // Track event received
    this.metricsService.recordEventReceived(event.eventType);
    
    const stopTimer = this.metricsService.queueProcessingTime.startTimer({
      queue_name: process.env.QUEUE_NAME || 'sales-events',
    });

    try {
      const job = await this.eventQueue.add('process-event', event, {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
        removeOnComplete: 1000, // Keep completed jobs for 1000 most recent
        removeOnFail: false,
      });
      
      stopTimer();
      
      // Track event queued successfully
      this.metricsService.recordEventQueued(event.eventType);
      
      // Update queue size metrics
      await this.updateQueueMetrics();
      
      this.logger.log(`Event queued with job ID: ${job.id}`);
      return job.id.toString();
    } catch (error) {
      stopTimer();
      
      // Track queue error
      this.metricsService.recordQueueError(
        event.eventType,
        error.name || 'UnknownError',
      );
      
      throw error;
    }
  }

  private async updateQueueMetrics(): Promise<void> {
    try {
      const queueName = process.env.QUEUE_NAME || 'sales-events';
      const [waiting, active, delayed] = await Promise.all([
        this.eventQueue.getWaitingCount(),
        this.eventQueue.getActiveCount(),
        this.eventQueue.getDelayedCount(),
      ]);
      
      this.metricsService.updateQueueSize(queueName, waiting, active, delayed);
    } catch (error) {
      this.logger.warn('Failed to update queue metrics', error);
    }
  }
}
