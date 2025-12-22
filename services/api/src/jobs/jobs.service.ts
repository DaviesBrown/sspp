import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue, Job } from 'bull';
import { WINSTON_MODULE_PROVIDER } from 'nest-winston';
import { Logger } from 'winston';

@Injectable()
export class JobsService {
  constructor(
    @InjectQueue(process.env.QUEUE_NAME || 'sales-events')
    private readonly queue: Queue,
    @Inject(WINSTON_MODULE_PROVIDER) private readonly logger: Logger,
  ) {}

  async getJobStatus(jobId: string) {
    const job = await this.queue.getJob(jobId);

    if (!job) {
      throw new NotFoundException(`Job with ID ${jobId} not found`);
    }

    const state = await job.getState();
    const progress = job.progress();
    const failedReason = job.failedReason;

    this.logger.info('Job status retrieved', { jobId, state });

    return {
      id: job.id,
      state,
      progress,
      data: job.data,
      timestamp: job.timestamp,
      processedOn: job.processedOn,
      finishedOn: job.finishedOn,
      failedReason,
      returnvalue: job.returnvalue,
    };
  }

  async getQueueStats() {
    const [waiting, active, completed, failed, delayed] = await Promise.all([
      this.queue.getWaitingCount(),
      this.queue.getActiveCount(),
      this.queue.getCompletedCount(),
      this.queue.getFailedCount(),
      this.queue.getDelayedCount(),
    ]);

    return {
      waiting,
      active,
      completed,
      failed,
      delayed,
      total: waiting + active + completed + failed + delayed,
    };
  }

  async getRecentJobs(limit: number = 10) {
    const [waiting, active, completed, failed] = await Promise.all([
      this.queue.getWaiting(0, limit - 1),
      this.queue.getActive(0, limit - 1),
      this.queue.getCompleted(0, limit - 1),
      this.queue.getFailed(0, limit - 1),
    ]);

    const formatJob = async (job: Job) => ({
      id: job.id,
      state: await job.getState(),
      data: job.data,
      timestamp: job.timestamp,
      processedOn: job.processedOn,
      finishedOn: job.finishedOn,
    });

    const allJobs = await Promise.all([
      ...waiting.map(formatJob),
      ...active.map(formatJob),
      ...completed.map(formatJob),
      ...failed.map(formatJob),
    ]);

    // Sort by timestamp (newest first)
    allJobs.sort((a, b) => b.timestamp - a.timestamp);

    return allJobs.slice(0, limit);
  }
}
