-- Create sales_signals table
CREATE TABLE IF NOT EXISTS sales_signals (
    id SERIAL PRIMARY KEY,
    account_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    signal_type VARCHAR(100) NOT NULL,
    signal_score DECIMAL(3, 2) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for common queries
CREATE INDEX idx_sales_signals_account_id ON sales_signals(account_id);
CREATE INDEX idx_sales_signals_user_id ON sales_signals(user_id);
CREATE INDEX idx_sales_signals_event_type ON sales_signals(event_type);
CREATE INDEX idx_sales_signals_signal_type ON sales_signals(signal_type);
CREATE INDEX idx_sales_signals_timestamp ON sales_signals(timestamp DESC);
CREATE INDEX idx_sales_signals_processed_at ON sales_signals(processed_at DESC);

-- Create composite index for common filtering patterns
CREATE INDEX idx_sales_signals_account_timestamp ON sales_signals(account_id, timestamp DESC);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sales_signals_updated_at BEFORE UPDATE
    ON sales_signals FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create a view for signal analytics
CREATE OR REPLACE VIEW signal_analytics AS
SELECT
    account_id,
    DATE(timestamp) as date,
    signal_type,
    COUNT(*) as signal_count,
    AVG(signal_score) as avg_score,
    MAX(signal_score) as max_score
FROM sales_signals
GROUP BY account_id, DATE(timestamp), signal_type;
