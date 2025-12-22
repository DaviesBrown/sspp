import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import { WINSTON_MODULE_PROVIDER } from 'nest-winston';
import { Logger } from 'winston';
import { Pool } from 'pg';
import { QuerySignalsDto } from './dto/query-signals.dto';

@Injectable()
export class SignalsService {
  private pool: Pool;

  constructor(
    @Inject(WINSTON_MODULE_PROVIDER) private readonly logger: Logger,
  ) {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'sales_signals',
      user: process.env.DB_USER || 'sspp_user',
      password: process.env.DB_PASSWORD || 'sspp_password',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.logger.info('PostgreSQL connection pool initialized for signals service');
  }

  async findAll(query: QuerySignalsDto) {
    const { accountId, userId, eventType, signalType, page = 1, limit = 20, sortBy = 'processed_at', sortOrder = 'DESC' } = query;
    const offset = (page - 1) * limit;

    let whereClause = [];
    let params: any[] = [];
    let paramIndex = 1;

    if (accountId) {
      whereClause.push(`account_id = $${paramIndex++}`);
      params.push(accountId);
    }

    if (userId) {
      whereClause.push(`user_id = $${paramIndex++}`);
      params.push(userId);
    }

    if (eventType) {
      whereClause.push(`event_type = $${paramIndex++}`);
      params.push(eventType);
    }

    if (signalType) {
      whereClause.push(`signal_type = $${paramIndex++}`);
      params.push(signalType);
    }

    const whereString = whereClause.length > 0 ? `WHERE ${whereClause.join(' AND ')}` : '';

    // Get total count
    const countQuery = `SELECT COUNT(*) as total FROM sales_signals ${whereString}`;
    const countResult = await this.pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].total);

    // Get paginated results
    const dataQuery = `
      SELECT 
        id,
        account_id,
        user_id,
        event_type,
        signal_type,
        signal_score,
        timestamp,
        processed_at,
        metadata
      FROM sales_signals
      ${whereString}
      ORDER BY ${sortBy} ${sortOrder}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    const dataResult = await this.pool.query(dataQuery, [...params, limit, offset]);

    this.logger.info('Signals queried', { 
      filters: { accountId, userId, eventType, signalType },
      page,
      limit,
      total,
      returned: dataResult.rows.length
    });

    return {
      data: dataResult.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: number) {
    const query = `
      SELECT 
        id,
        account_id,
        user_id,
        event_type,
        signal_type,
        signal_score,
        timestamp,
        processed_at,
        metadata
      FROM sales_signals
      WHERE id = $1
    `;

    const result = await this.pool.query(query, [id]);

    if (result.rows.length === 0) {
      throw new NotFoundException(`Signal with ID ${id} not found`);
    }

    this.logger.info('Signal retrieved', { signalId: id });

    return result.rows[0];
  }

  async getStats() {
    // Compute stats via straightforward aggregate queries for reliability
    const [totalsRes, typeRes, eventRes] = await Promise.all([
      this.pool.query(
        `SELECT 
           COUNT(*)::bigint as total_signals,
           COUNT(DISTINCT account_id)::bigint as unique_accounts,
           COUNT(DISTINCT user_id)::bigint as unique_users,
           COALESCE(AVG(signal_score), 0) as avg_signal_score
         FROM sales_signals`
      ),
      this.pool.query(
        `SELECT signal_type, COUNT(*)::bigint as count
         FROM sales_signals
         GROUP BY signal_type`
      ),
      this.pool.query(
        `SELECT event_type, COUNT(*)::bigint as count
         FROM sales_signals
         GROUP BY event_type`
      ),
    ]);

    const totals = totalsRes.rows[0] || {
      total_signals: 0,
      unique_accounts: 0,
      unique_users: 0,
      avg_signal_score: 0,
    };

    const signals_by_type = (typeRes.rows || []).reduce((acc: Record<string, number>, row: any) => {
      if (row.signal_type) acc[row.signal_type] = Number(row.count);
      return acc;
    }, {});

    const signals_by_event = (eventRes.rows || []).reduce((acc: Record<string, number>, row: any) => {
      if (row.event_type) acc[row.event_type] = Number(row.count);
      return acc;
    }, {});

    return { ...totals, signals_by_type, signals_by_event };
  }

  async onModuleDestroy() {
    await this.pool.end();
    this.logger.info('PostgreSQL connection pool closed');
  }
}
