import { IsString, IsNotEmpty, IsObject, IsDateString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum EventType {
  EMAIL_SENT = 'email_sent',
  EMAIL_OPENED = 'email_opened',
  EMAIL_CLICKED = 'email_clicked',
  MEETING_BOOKED = 'meeting_booked',
  CALL_MADE = 'call_made',
  DEMO_COMPLETED = 'demo_completed',
}

export class CreateEventDto {
  @ApiProperty({ description: 'Account identifier' })
  @IsString()
  @IsNotEmpty()
  accountId: string;

  @ApiProperty({ description: 'User identifier' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ enum: EventType, description: 'Type of sales event' })
  @IsEnum(EventType)
  @IsNotEmpty()
  eventType: EventType;

  @ApiProperty({ description: 'ISO timestamp of the event' })
  @IsDateString()
  @IsNotEmpty()
  timestamp: string;

  @ApiProperty({ description: 'Additional event metadata', required: false })
  @IsObject()
  metadata?: Record<string, any>;
}
