import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { HealthController } from './health.controller';

@Module({
  imports: [
    BullModule.registerQueue({
      name: process.env.QUEUE_NAME || 'sales-events',
    }),
  ],
  controllers: [HealthController],
})
export class HealthModule {}
