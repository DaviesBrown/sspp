import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';

@Module({
  imports: [
    BullModule.registerQueue({
      name: process.env.QUEUE_NAME || 'sales-events',
    }),
  ],
  controllers: [EventsController],
  providers: [EventsService],
})
export class EventsModule {}
