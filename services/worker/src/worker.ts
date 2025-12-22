import Queue from 'bull';
import { logger } from './utils/logger';
import { processEvent } from './processors/event-processor';

export function createWorker(): Queue.Queue {
  const queue = new Queue(process.env.QUEUE_NAME || 'sales-events', {
    redis: {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || undefined,
    },
  });

  const concurrency = parseInt(process.env.QUEUE_CONCURRENCY || '5');

  queue.process('process-event', concurrency, async (job) => {
    logger.info(`Processing job ${job.id}`, { data: job.data });
    
    try {
      const result = await processEvent(job.data);
      logger.info(`Job ${job.id} completed successfully`, { result });
      return result;
    } catch (error) {
      logger.error(`Job ${job.id} failed`, { error });
      throw error;
    }
  });

  // Event handlers
  queue.on('completed', (job) => {
    logger.debug(`Job ${job.id} completed`);
  });

  queue.on('failed', (job, err) => {
    logger.error(`Job ${job?.id} failed`, { error: err.message });
  });

  queue.on('error', (error) => {
    logger.error('Queue error', { error });
  });

  return queue;
}
