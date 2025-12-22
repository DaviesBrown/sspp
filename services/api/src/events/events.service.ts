import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { CreateEventDto } from './dto/create-event.dto';

@Injectable()
export class EventsService {
  private readonly logger = new Logger(EventsService.name);

  constructor(
    @InjectQueue(process.env.QUEUE_NAME || 'sales-events')
    private readonly eventQueue: Queue,
  ) {}

  async queueEvent(event: CreateEventDto): Promise<string> {
    this.logger.log(`Queueing event: ${event.eventType} for ${event.accountId}`);
    
    const job = await this.eventQueue.add('process-event', event, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000,
      },
      removeOnComplete: true,
      removeOnFail: false,
    });
    
    this.logger.log(`Event queued with job ID: ${job.id}`);
    return job.id.toString();
  }
}
