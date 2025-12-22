-- Seed some test data for development
INSERT INTO sales_signals (account_id, user_id, event_type, signal_type, signal_score, timestamp, metadata)
VALUES
    ('acc_001', 'user_001', 'email_sent', 'outreach', 0.10, NOW() - INTERVAL '5 days', '{"campaign": "Q4 Outreach"}'),
    ('acc_001', 'user_001', 'email_opened', 'engagement', 0.30, NOW() - INTERVAL '4 days', '{"campaign": "Q4 Outreach"}'),
    ('acc_001', 'user_001', 'email_clicked', 'high_engagement', 0.60, NOW() - INTERVAL '3 days', '{"campaign": "Q4 Outreach", "link": "demo"}'),
    ('acc_001', 'user_002', 'meeting_booked', 'intent', 0.80, NOW() - INTERVAL '2 days', '{"meeting_type": "demo", "duration": 30}'),
    ('acc_002', 'user_003', 'email_sent', 'outreach', 0.10, NOW() - INTERVAL '1 day', '{"campaign": "New Year"}'),
    ('acc_002', 'user_003', 'call_made', 'outreach', 0.50, NOW() - INTERVAL '12 hours', '{"duration": 15, "outcome": "interested"}'),
    ('acc_003', 'user_004', 'demo_completed', 'high_intent', 0.90, NOW() - INTERVAL '6 hours', '{"attendees": 3, "duration": 45}');
