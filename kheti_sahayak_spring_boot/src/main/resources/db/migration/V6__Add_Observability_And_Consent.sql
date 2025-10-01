-- =====================================================
-- V6: Add Observability and User Consent Tables
-- Implements Issue #256 (Observability) and #255 (Privacy & Consent)
-- =====================================================

-- =====================================================
-- USER CONSENT TABLE (Issue #255: Privacy & Consent)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_consents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    
    -- ML and Data Usage
    ml_data_usage_consent BOOLEAN DEFAULT FALSE,
    ml_data_usage_consent_date TIMESTAMP,
    
    -- Chatbot
    chatbot_consent BOOLEAN DEFAULT FALSE,
    chatbot_consent_date TIMESTAMP,
    
    -- Location
    location_sharing_consent BOOLEAN DEFAULT FALSE,
    location_sharing_consent_date TIMESTAMP,
    
    -- Image Sharing for ML Training
    image_sharing_ml_consent BOOLEAN DEFAULT FALSE,
    image_sharing_ml_consent_date TIMESTAMP,
    
    -- Marketing
    marketing_consent BOOLEAN DEFAULT FALSE,
    marketing_consent_date TIMESTAMP,
    
    -- Analytics
    analytics_consent BOOLEAN DEFAULT FALSE,
    analytics_consent_date TIMESTAMP,
    
    -- Third-party Sharing
    third_party_sharing_consent BOOLEAN DEFAULT FALSE,
    third_party_sharing_consent_date TIMESTAMP,
    
    -- Audit Trail
    consent_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for consent table
CREATE INDEX idx_user_consents_user_id ON user_consents(user_id);
CREATE INDEX idx_user_consents_ml_consent ON user_consents(ml_data_usage_consent);

-- Insert default consent for existing users
INSERT INTO user_consents (user_id, consent_version)
SELECT id, '1.0' FROM users
WHERE id NOT IN (SELECT user_id FROM user_consents);

-- =====================================================
-- AUDIT LOG TABLE (Issue #256: Observability)
-- =====================================================

CREATE TABLE IF NOT EXISTS api_audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    response_time_ms INTEGER,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    request_body TEXT,
    response_body TEXT,
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes for audit log
CREATE INDEX idx_audit_log_user_id ON api_audit_log(user_id);
CREATE INDEX idx_audit_log_endpoint ON api_audit_log(endpoint);
CREATE INDEX idx_audit_log_created_at ON api_audit_log(created_at DESC);
CREATE INDEX idx_audit_log_status_code ON api_audit_log(status_code);

-- =====================================================
-- ML METRICS TABLE (Issue #253, #254: ML Monitoring)
-- =====================================================

CREATE TABLE IF NOT EXISTS ml_inference_metrics (
    id BIGSERIAL PRIMARY KEY,
    diagnosis_id BIGINT,
    model_version VARCHAR(50),
    inference_time_ms INTEGER,
    confidence_score DECIMAL(5, 4),
    prediction_class VARCHAR(100),
    image_size_bytes BIGINT,
    preprocessing_time_ms INTEGER,
    postprocessing_time_ms INTEGER,
    total_time_ms INTEGER,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (diagnosis_id) REFERENCES crop_diagnosis(id) ON DELETE SET NULL
);

-- Indexes for ML metrics
CREATE INDEX idx_ml_metrics_created_at ON ml_inference_metrics(created_at DESC);
CREATE INDEX idx_ml_metrics_model_version ON ml_inference_metrics(model_version);
CREATE INDEX idx_ml_metrics_success ON ml_inference_metrics(success);
CREATE INDEX idx_ml_metrics_confidence ON ml_inference_metrics(confidence_score);

-- =====================================================
-- SYSTEM METRICS TABLE (Issue #256: QPS/Latency)
-- =====================================================

CREATE TABLE IF NOT EXISTS system_metrics_snapshot (
    id BIGSERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15, 4),
    metric_type VARCHAR(20) NOT NULL, -- COUNTER, GAUGE, HISTOGRAM, TIMER
    tags JSONB,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for system metrics
CREATE INDEX idx_system_metrics_name ON system_metrics_snapshot(metric_name);
CREATE INDEX idx_system_metrics_timestamp ON system_metrics_snapshot(timestamp DESC);
CREATE INDEX idx_system_metrics_type ON system_metrics_snapshot(metric_type);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATE
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_consents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_consents_updated_at
    BEFORE UPDATE ON user_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_user_consents_updated_at();

-- =====================================================
-- CLEANUP FUNCTION FOR OLD AUDIT LOGS
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_old_audit_logs(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM api_audit_log
    WHERE created_at < CURRENT_TIMESTAMP - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VIEWS FOR MONITORING DASHBOARDS
-- =====================================================

-- API Performance Summary View
CREATE OR REPLACE VIEW v_api_performance_summary AS
SELECT 
    endpoint,
    method,
    COUNT(*) as request_count,
    AVG(response_time_ms) as avg_response_time_ms,
    MAX(response_time_ms) as max_response_time_ms,
    MIN(response_time_ms) as min_response_time_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_response_time_ms,
    COUNT(CASE WHEN status_code >= 500 THEN 1 END) as error_count,
    DATE(created_at) as date
FROM api_audit_log
WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY endpoint, method, DATE(created_at)
ORDER BY request_count DESC;

-- ML Performance Summary View
CREATE OR REPLACE VIEW v_ml_performance_summary AS
SELECT 
    model_version,
    prediction_class,
    COUNT(*) as inference_count,
    AVG(inference_time_ms) as avg_inference_time_ms,
    AVG(confidence_score) as avg_confidence,
    COUNT(CASE WHEN success = FALSE THEN 1 END) as error_count,
    DATE(created_at) as date
FROM ml_inference_metrics
WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY model_version, prediction_class, DATE(created_at)
ORDER BY inference_count DESC;

-- User Consent Summary View
CREATE OR REPLACE VIEW v_consent_summary AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN ml_data_usage_consent = TRUE THEN 1 END) as ml_consent_count,
    COUNT(CASE WHEN chatbot_consent = TRUE THEN 1 END) as chatbot_consent_count,
    COUNT(CASE WHEN location_sharing_consent = TRUE THEN 1 END) as location_consent_count,
    COUNT(CASE WHEN image_sharing_ml_consent = TRUE THEN 1 END) as image_sharing_consent_count,
    ROUND(100.0 * COUNT(CASE WHEN ml_data_usage_consent = TRUE THEN 1 END) / COUNT(*), 2) as ml_consent_percentage
FROM user_consents;

