import { Controller, Get, Param, Query, ParseIntPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { SignalsService } from './signals.service';
import { QuerySignalsDto } from './dto/query-signals.dto';

@ApiTags('signals')
@Controller('signals')
export class SignalsController {
  constructor(private readonly signalsService: SignalsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all processed signals with filters and pagination' })
  @ApiResponse({
    status: 200,
    description: 'Returns paginated list of processed signals',
    schema: {
      example: {
        data: [
          {
            id: 1,
            account_id: 'test_001',
            user_id: 'user_001',
            event_type: 'email_sent',
            signal_type: 'outreach',
            signal_score: 0.1,
            timestamp: '2024-12-21T10:00:00.000Z',
            processed_at: '2025-12-21T00:49:31.643Z',
            metadata: { campaign: 'Test' },
          },
        ],
        pagination: {
          page: 1,
          limit: 20,
          total: 100,
          totalPages: 5,
        },
      },
    },
  })
  async findAll(@Query() query: QuerySignalsDto) {
    return this.signalsService.findAll(query);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get signal processing statistics' })
  @ApiResponse({
    status: 200,
    description: 'Returns aggregated signal statistics',
    schema: {
      example: {
        total_signals: 150,
        unique_accounts: 45,
        unique_users: 120,
        avg_signal_score: 0.35,
        signals_by_type: {
          outreach: 50,
          engagement: 60,
          conversion: 40,
        },
        signals_by_event: {
          email_sent: 70,
          email_opened: 50,
          meeting_booked: 30,
        },
      },
    },
  })
  async getStats() {
    return this.signalsService.getStats();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific signal by ID' })
  @ApiParam({ name: 'id', description: 'Signal ID', example: 1 })
  @ApiResponse({
    status: 200,
    description: 'Returns signal details',
    schema: {
      example: {
        id: 1,
        account_id: 'test_001',
        user_id: 'user_001',
        event_type: 'email_sent',
        signal_type: 'outreach',
        signal_score: 0.1,
        timestamp: '2024-12-21T10:00:00.000Z',
        processed_at: '2025-12-21T00:49:31.643Z',
        metadata: { campaign: 'Test' },
      },
    },
  })
  @ApiResponse({ status: 404, description: 'Signal not found' })
  async findOne(@Param('id', ParseIntPipe) id: number) {
    return this.signalsService.findOne(id);
  }
}
