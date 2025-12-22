import dotenv from 'dotenv';
import { logger } from './utils/logger';
import { createWorker } from './worker';
import { connectDatabase, disconnectDatabase } from './database/connection';
import { connectElasticsearch } from './elasticsearch/connection';

dotenv.config();

async function bootstrap() {
  try {
    logger.info('Starting Signal Processing Worker...');
    
    // Connect to PostgreSQL
    await connectDatabase();
    logger.info('✓ Connected to PostgreSQL');
    
    // Connect to Elasticsearch
    await connectElasticsearch();
    logger.info('✓ Connected to Elasticsearch');
    
    // Start worker
    const worker = createWorker();
    logger.info('✓ Worker started and listening for jobs');
    
    // Graceful shutdown
    const shutdown = async () => {
      logger.info('Shutting down worker...');
      await worker.close();
      await disconnectDatabase();
      logger.info('Worker shut down successfully');
      process.exit(0);
    };
    
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
    
  } catch (error) {
    logger.error('Failed to start worker:', error);
    process.exit(1);
  }
}

bootstrap();
