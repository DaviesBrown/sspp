import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

export class QuerySignalsDto {
  @ApiPropertyOptional({ description: 'Account ID to filter by', example: 'test_001' })
  @IsOptional()
  @IsString()
  accountId?: string;

  @ApiPropertyOptional({ description: 'User ID to filter by', example: 'user_001' })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiPropertyOptional({ description: 'Event type to filter by', example: 'email_sent' })
  @IsOptional()
  @IsIn(['email_sent', 'email_opened', 'email_clicked', 'page_view', 'form_submit', 'meeting_booked', 'demo_requested', 'trial_started'])
  eventType?: string;

  @ApiPropertyOptional({ description: 'Signal type to filter by', example: 'outreach' })
  @IsOptional()
  @IsIn(['outreach', 'engagement', 'conversion', 'interest'])
  signalType?: string;

  @ApiPropertyOptional({ description: 'Page number', example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ description: 'Sort by field', example: 'processed_at', default: 'processed_at' })
  @IsOptional()
  @IsIn(['processed_at', 'timestamp', 'signal_score', 'id'])
  sortBy?: string = 'processed_at';

  @ApiPropertyOptional({ description: 'Sort order', example: 'DESC', default: 'DESC' })
  @IsOptional()
  @IsIn(['ASC', 'DESC'])
  sortOrder?: 'ASC' | 'DESC' = 'DESC';
}
