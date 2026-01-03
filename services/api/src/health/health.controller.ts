import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { Response } from 'express';
import { Pool } from 'pg';
import { MetricsService } from '../metrics/metrics.service';

@ApiTags('health')
@Controller()
export class HealthController {
  private pool: Pool;

  constructor(
    @InjectQueue(process.env.QUEUE_NAME || 'sales-events')
    private readonly queue: Queue,
    private readonly metricsService: MetricsService,
  ) {
    // PostgreSQL connection pool for health checks
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'sales_signals',
      user: process.env.DB_USER || 'sspp_user',
      password: process.env.DB_PASSWORD || 'sspp_password',
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  }

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint with dependency status' })
  @ApiResponse({
    status: 200,
    description: 'All services healthy',
    schema: {
      example: {
        status: 'healthy',
        timestamp: '2025-12-22T10:00:00.000Z',
        services: {
          redis: { status: 'healthy', responseTime: 5 },
          postgres: { status: 'healthy', responseTime: 12 },
        },
      },
    },
  })
  @ApiResponse({ status: 503, description: 'One or more services unhealthy' })
  async health(@Res() res: Response) {
    const timestamp = new Date().toISOString();
    const checks: Record<string, any> = {};

    // Check Redis (via Bull queue)
    const redisTimer = this.metricsService.startRedisTimer('ping');
    const redisStart = Date.now();
    try {
      await this.queue.client.ping();
      redisTimer();
      checks.redis = {
        status: 'healthy',
        responseTime: Date.now() - redisStart,
      };
      this.metricsService.redisConnectionStatus.set(1);
    } catch (error) {
      redisTimer();
      checks.redis = {
        status: 'unhealthy',
        error: error.message,
      };
      this.metricsService.redisConnectionStatus.set(0);
    }

    // Check PostgreSQL
    const dbTimer = this.metricsService.startDbTimer('health_check', 'system');
    const pgStart = Date.now();
    try {
      await this.pool.query('SELECT 1');
      dbTimer();
      checks.postgres = {
        status: 'healthy',
        responseTime: Date.now() - pgStart,
      };
      
      // Update connection pool metrics
      this.metricsService.dbConnectionPool.set({ state: 'total' }, this.pool.totalCount);
      this.metricsService.dbConnectionPool.set({ state: 'idle' }, this.pool.idleCount);
      this.metricsService.dbConnectionPool.set({ state: 'waiting' }, this.pool.waitingCount);
    } catch (error) {
      dbTimer();
      checks.postgres = {
        status: 'unhealthy',
        error: error.message,
      };
    }

    const allHealthy = Object.values(checks).every((check: any) => check.status === 'healthy');
    const overallStatus = allHealthy ? 'healthy' : 'degraded';
    const statusCode = allHealthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;

    return res.status(statusCode).json({
      status: overallStatus,
      timestamp,
      services: checks,
    });
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness check endpoint' })
  @ApiResponse({
    status: 200,
    description: 'Service ready to accept traffic',
    schema: {
      example: {
        status: 'ready',
        timestamp: '2025-12-22T10:00:00.000Z',
        uptime: 123.45,
      },
    },
  })
  async ready(@Res() res: Response) {
    const timestamp = new Date().toISOString();
    
    // Quick check - just verify Redis is reachable
    try {
      await this.queue.client.ping();
      this.metricsService.redisConnectionStatus.set(1);
      return res.status(HttpStatus.OK).json({
        status: 'ready',
        timestamp,
        uptime: process.uptime(),
      });
    } catch (error) {
      this.metricsService.redisConnectionStatus.set(0);
      return res.status(HttpStatus.SERVICE_UNAVAILABLE).json({
        status: 'not ready',
        timestamp,
        error: 'Redis connection failed',
      });
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}
