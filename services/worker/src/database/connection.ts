import { Pool } from 'pg';
import { logger } from '../utils/logger';

let pool: Pool | null = null;

export async function connectDatabase(): Promise<Pool> {
  if (pool) {
    return pool;
  }

  pool = new Pool({
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    database: process.env.POSTGRES_DB || 'sales_signals',
    user: process.env.POSTGRES_USER || 'sspp_user',
    password: process.env.POSTGRES_PASSWORD || 'dev_password',
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  pool.on('error', (err) => {
    logger.error('Unexpected database error', { error: err });
  });

  // Test connection
  await pool.query('SELECT NOW()');

  return pool;
}

export async function disconnectDatabase(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

export function getPool(): Pool {
  if (!pool) {
    throw new Error('Database not connected. Call connectDatabase() first.');
  }
  return pool;
}
