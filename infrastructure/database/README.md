# Database Configuration

This directory contains database initialization scripts and migration utilities for the Sales Signal Processing Platform's PostgreSQL database.

## Architecture Role

```
┌─────────────────────────────────────────────────────────────┐
│                   Data Flow                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   API Service                                                │
│       │                                                      │
│       ▼                                                      │
│   Redis Queue                                                │
│       │                                                      │
│       ▼                                                      │
│   Worker Service                                             │
│       │                                                      │
│       ├──────────────────►  PostgreSQL  ◄── YOU ARE HERE    │
│       │                                                      │
│       └──────────────────►  Elasticsearch                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

PostgreSQL serves as the **primary data store** for processed sales signals. The worker service writes to it after processing events from the queue.

## Files

### [init.sql](init.sql)

Database initialization script that runs when PostgreSQL first starts. Creates:

- Database schema
- Required tables
- Indexes for common queries
- Initial user permissions

```sql
-- Example structure
CREATE TABLE signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    signal_data JSONB NOT NULL,
    processed_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_signals_customer ON signals(customer_id);
CREATE INDEX idx_signals_event_type ON signals(event_type);
CREATE INDEX idx_signals_processed_at ON signals(processed_at);
```

### [seed.sql](seed.sql)

Optional seed data for development and testing environments. Contains:

- Sample signal records
- Test data for local development
- Demo data for presentations

```sql
-- Example seed data
INSERT INTO signals (event_type, customer_id, signal_data)
VALUES 
    ('purchase', 'cust_001', '{"amount": 150.00, "product": "Widget A"}'),
    ('inquiry', 'cust_002', '{"product": "Widget B", "channel": "email"}');
```

### [migrate.sh](migrate.sh)

Database migration utility script for applying schema changes:

```bash
#!/bin/bash
# Run migrations against the database

set -e

DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/sspp}"

echo "Running migrations..."
psql "$DATABASE_URL" -f migrations/*.sql

echo "Migrations complete!"
```

## Usage

### Local Development

```bash
# Start PostgreSQL with Docker Compose (from repo root)
docker-compose up -d postgres

# The init.sql script runs automatically on first start
# To re-initialize, remove the volume:
docker-compose down -v
docker-compose up -d postgres

# Run seed data
docker-compose exec postgres psql -U postgres -d sspp -f /docker-entrypoint-initdb.d/seed.sql
```

### Docker Compose Integration

The `docker-compose.yml` mounts this directory:

```yaml
postgres:
  image: postgres:15
  volumes:
    - ./infrastructure/database/init.sql:/docker-entrypoint-initdb.d/01-init.sql
    - ./infrastructure/database/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql
    - postgres_data:/var/lib/postgresql/data
  environment:
    POSTGRES_DB: sspp
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
```

### Kubernetes

For Kubernetes deployments, database initialization is handled via:

1. **Init Container**: Runs migrations before the main container starts
2. **ConfigMap**: Stores SQL scripts
3. **Secret**: Stores database credentials

See: [infrastructure/k8s/base/postgres-deployment.yaml](../k8s/base/postgres-deployment.yaml)

## Schema Design

### Core Tables

| Table | Purpose |
|-------|---------|
| `signals` | Processed sales signals |
| `events` | Raw event log (audit trail) |
| `customers` | Customer metadata cache |

### Indexes

Indexes are optimized for common query patterns:

```sql
-- Query: Get signals by customer
CREATE INDEX idx_signals_customer ON signals(customer_id);

-- Query: Get signals by type and time range
CREATE INDEX idx_signals_type_time ON signals(event_type, processed_at DESC);

-- Query: Full-text search on signal data
CREATE INDEX idx_signals_data ON signals USING GIN(signal_data);
```

## Migrations Strategy

For production, we recommend using a migration tool like:

- [golang-migrate](https://github.com/golang-migrate/migrate)
- [Flyway](https://flywaydb.org/)
- [Prisma](https://www.prisma.io/)

Migration workflow:

```
1. Create numbered migration file: 001_create_signals.sql
2. Test locally with docker-compose
3. Apply to staging environment
4. Apply to production (with backup)
```

## Backup & Recovery

### Backup Script

```bash
#!/bin/bash
# backup.sh
pg_dump "$DATABASE_URL" > "backup_$(date +%Y%m%d_%H%M%S).sql"
```

### Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres:15
              command: ["/bin/sh", "-c"]
              args:
                - pg_dump $DATABASE_URL | gzip > /backups/backup_$(date +%Y%m%d).sql.gz
```

## Connection Strings

| Environment | Connection String |
|-------------|-------------------|
| Local | `postgresql://postgres:postgres@localhost:5432/sspp` |
| Docker Compose | `postgresql://postgres:postgres@postgres:5432/sspp` |
| Kubernetes Dev | `postgresql://$(DB_USER):$(DB_PASS)@postgres.sspp-dev:5432/sspp` |
| Kubernetes Prod | `postgresql://$(DB_USER):$(DB_PASS)@postgres.sspp-prod:5432/sspp` |

## Related Resources

| Resource | Location |
|----------|----------|
| K8s PostgreSQL | [infrastructure/k8s/base/postgres-deployment.yaml](../k8s/base/postgres-deployment.yaml) |
| K8s Secrets | [infrastructure/k8s/base/secrets.yaml](../k8s/base/secrets.yaml) |
| Docker Compose | [docker-compose.yml](../../docker-compose.yml) |
| Worker Service | [services/worker/](../../services/worker/) |
