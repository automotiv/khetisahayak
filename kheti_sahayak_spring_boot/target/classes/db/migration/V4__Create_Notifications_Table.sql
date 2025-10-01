-- Create notifications table for farmer alerts and system notifications
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(30) NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    action_url VARCHAR(500),
    action_text VARCHAR(50),
    icon VARCHAR(100),
    metadata TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    CONSTRAINT chk_notification_type CHECK (type IN (
        'WEATHER_ALERT', 'CROP_DISEASE_ALERT', 'PEST_ALERT', 'MARKET_PRICE_UPDATE',
        'EXPERT_RESPONSE', 'GOVERNMENT_SCHEME', 'IRRIGATION_REMINDER', 'FERTILIZER_REMINDER',
        'HARVEST_REMINDER', 'COMMUNITY_UPDATE', 'SYSTEM_UPDATE', 'GENERAL'
    )),
    CONSTRAINT chk_notification_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT'))
);

-- Create indexes for better query performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Insert sample notifications for testing
INSERT INTO notifications (user_id, title, message, type, priority, is_read, icon) VALUES
(1, 'Heavy Rainfall Alert', 'Heavy rainfall expected in your region tomorrow. Postpone irrigation and prepare for waterlogging.', 
 'WEATHER_ALERT', 'URGENT', FALSE, 'weather-alert'),
(1, 'New Government Scheme', 'PM-KISAN scheme registration is now open. Apply now to receive ₹6,000 per year.', 
 'GOVERNMENT_SCHEME', 'MEDIUM', FALSE, 'government'),
(1, 'Rice Price Update', 'Rice prices have increased to ₹2,200 per quintal in your local market.', 
 'MARKET_PRICE_UPDATE', 'MEDIUM', TRUE, 'market-update'),
(1, 'Irrigation Reminder', 'It''s time to irrigate your crops. Weather conditions are favorable.', 
 'IRRIGATION_REMINDER', 'LOW', TRUE, 'irrigation'),
(1, 'Pest Alert', 'Brown planthopper outbreak reported in neighboring farms. Monitor your rice fields closely.', 
 'PEST_ALERT', 'HIGH', FALSE, 'pest-alert');

-- Create function to automatically cleanup expired notifications
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications
    WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Note: The scheduled cleanup will be handled by the Spring @Scheduled annotation in NotificationService

