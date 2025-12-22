import { Controller, Get, Param, Query, ParseIntPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam, ApiQuery } from '@nestjs/swagger';
import { JobsService } from './jobs.service';

@ApiTags('jobs')
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get job queue statistics' })
  @ApiResponse({
    status: 200,
    description: 'Returns queue statistics',
    schema: {
      example: {
        waiting: 5,
        active: 2,
        completed: 150,
        failed: 3,
        delayed: 0,
        total: 160,
      },
    },
  })
  async getStats() {
    return this.jobsService.getQueueStats();
  }

  @Get('recent')
  @ApiOperation({ summary: 'Get recent jobs' })
  @ApiQuery({ name: 'limit', required: false, description: 'Number of jobs to return', example: 10 })
  @ApiResponse({
    status: 200,
    description: 'Returns list of recent jobs',
    schema: {
      example: [
        {
          id: '3',
          state: 'completed',
          data: {
            accountId: 'test_001',
            userId: 'user_001',
            eventType: 'email_sent',
            timestamp: '2024-12-21T10:00:00Z',
            metadata: { campaign: 'Test' },
          },
          timestamp: 1703145571000,
          processedOn: 1703145571100,
          finishedOn: 1703145571200,
        },
      ],
    },
  })
  async getRecentJobs(@Query('limit', new ParseIntPipe({ optional: true })) limit?: number) {
    return this.jobsService.getRecentJobs(limit || 10);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get job status by ID' })
  @ApiParam({ name: 'id', description: 'Job ID', example: '3' })
  @ApiResponse({
    status: 200,
    description: 'Returns job status and details',
    schema: {
      example: {
        id: '3',
        state: 'completed',
        progress: 100,
        data: {
          accountId: 'test_001',
          userId: 'user_001',
          eventType: 'email_sent',
          timestamp: '2024-12-21T10:00:00Z',
          metadata: { campaign: 'Test' },
        },
        timestamp: 1703145571000,
        processedOn: 1703145571100,
        finishedOn: 1703145571200,
        failedReason: null,
        returnvalue: {
          id: 3,
          accountId: 'test_001',
          signalType: 'outreach',
          signalScore: 0.1,
        },
      },
    },
  })
  @ApiResponse({ status: 404, description: 'Job not found' })
  async getJobStatus(@Param('id') id: string) {
    return this.jobsService.getJobStatus(id);
  }
}
