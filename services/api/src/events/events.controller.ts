import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { EventsService } from './events.service';
import { CreateEventDto } from './dto/create-event.dto';

@ApiTags('events')
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiOperation({ summary: 'Ingest a sales event' })
  @ApiResponse({ status: 202, description: 'Event accepted for processing' })
  @ApiResponse({ status: 400, description: 'Invalid event data' })
  async createEvent(@Body() createEventDto: CreateEventDto) {
    const jobId = await this.eventsService.queueEvent(createEventDto);
    return {
      status: 'accepted',
      jobId,
      message: 'Event queued for processing',
    };
  }
}
