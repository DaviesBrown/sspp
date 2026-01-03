import { Controller, Get, Res } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiExcludeEndpoint } from '@nestjs/swagger';
import { Response } from 'express';
import { MetricsService } from './metrics.service';

@ApiTags('metrics')
@Controller()
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}

  @Get('metrics')
  @ApiOperation({ summary: 'Prometheus metrics endpoint' })
  @ApiResponse({
    status: 200,
    description: 'Returns Prometheus-formatted metrics',
    content: {
      'text/plain': {
        schema: {
          type: 'string',
          example: `# HELP sspp_api_http_requests_total Total number of HTTP requests
# TYPE sspp_api_http_requests_total counter
sspp_api_http_requests_total{method="GET",route="/health",status_code="200"} 42`,
        },
      },
    },
  })
  async getMetrics(@Res() res: Response): Promise<void> {
    const metrics = await this.metricsService.getMetrics();
    res.set('Content-Type', this.metricsService.getContentType());
    res.send(metrics);
  }

  @Get('metrics/json')
  @ApiExcludeEndpoint()
  async getMetricsJson(): Promise<object> {
    // Return metrics in a more readable JSON format for debugging
    const metricsText = await this.metricsService.getMetrics();
    const lines = metricsText.split('\n');
    const metrics: Record<string, any> = {};
    
    let currentMetric = '';
    for (const line of lines) {
      if (line.startsWith('# HELP')) {
        currentMetric = line.split(' ')[2];
        metrics[currentMetric] = { help: line.substring(line.indexOf(currentMetric) + currentMetric.length + 1) };
      } else if (line.startsWith('# TYPE')) {
        const type = line.split(' ')[3];
        if (metrics[currentMetric]) {
          metrics[currentMetric].type = type;
        }
      } else if (line && !line.startsWith('#')) {
        const match = line.match(/^([^\{]+)(\{[^\}]*\})?\s+(.+)$/);
        if (match) {
          const [, name, labels, value] = match;
          if (!metrics[name]) {
            metrics[name] = {};
          }
          if (!metrics[name].values) {
            metrics[name].values = [];
          }
          metrics[name].values.push({
            labels: labels || '',
            value: parseFloat(value),
          });
        }
      }
    }
    
    return metrics;
  }
}
