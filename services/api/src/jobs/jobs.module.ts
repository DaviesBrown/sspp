import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { JobsController } from './jobs.controller';
import { JobsService } from './jobs.service';

@Module({
  imports: [
    BullModule.registerQueue({
      name: process.env.QUEUE_NAME || 'sales-events',
    }),
  ],
  controllers: [JobsController],
  providers: [JobsService],
})
export class JobsModule {}
