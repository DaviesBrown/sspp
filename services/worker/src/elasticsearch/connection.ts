import { Client } from '@elastic/elasticsearch';
import { logger } from '../utils/logger';

let client: Client | null = null;

export async function connectElasticsearch(): Promise<Client> {
  if (client) {
    return client;
  }

  client = new Client({
    node: process.env.ELASTICSEARCH_NODE || 'http://localhost:9200',
  });

  // Test connection
  await client.ping();

  // Ensure index exists
  const indexName = 'sales-signals';
  const indexExists = await client.indices.exists({ index: indexName });

  if (!indexExists) {
    await client.indices.create({
      index: indexName,
      body: {
        mappings: {
          properties: {
            accountId: { type: 'keyword' },
            userId: { type: 'keyword' },
            eventType: { type: 'keyword' },
            signalType: { type: 'keyword' },
            signalScore: { type: 'float' },
            timestamp: { type: 'date' },
            processedAt: { type: 'date' },
            metadata: { type: 'object', enabled: false },
          },
        },
      },
    });
    logger.info('Created Elasticsearch index: sales-signals');
  }

  return client;
}

export function getElasticsearchClient(): Client {
  if (!client) {
    throw new Error('Elasticsearch not connected. Call connectElasticsearch() first.');
  }
  return client;
}
