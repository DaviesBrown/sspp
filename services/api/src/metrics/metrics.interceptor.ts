import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Request, Response } from 'express';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();

    const method = request.method;
    const route = this.normalizeRoute(request.route?.path || request.path);

    // Skip metrics endpoint to avoid recursion
    if (route === '/metrics' || route === '/metrics/json') {
      return next.handle();
    }

    const stopTimer = this.metricsService.startHttpTimer(method, route);

    return next.handle().pipe(
      tap({
        next: () => {
          stopTimer(response.statusCode.toString());
        },
        error: (error) => {
          const statusCode = error.status || error.statusCode || 500;
          stopTimer(statusCode.toString());
        },
      }),
    );
  }

  private normalizeRoute(path: string): string {
    // Normalize dynamic route parameters for consistent labeling
    // e.g., /events/123 -> /events/:id
    return path
      .replace(/\/\d+/g, '/:id')
      .replace(/\/[a-f0-9-]{36}/gi, '/:uuid');
  }
}
