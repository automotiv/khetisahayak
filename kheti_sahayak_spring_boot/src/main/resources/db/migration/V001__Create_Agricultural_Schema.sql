-- Kheti Sahayak Agricultural Platform Database Schema
-- Optimized for Indian agricultural data with proper indexing
-- Implements CodeRabbit performance standards for rural connectivity

-- Create users table with agricultural context
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    mobile_number VARCHAR(10) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    user_type VARCHAR(20) NOT NULL DEFAULT 'FARMER',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Agricultural profile fields
    primary_crop VARCHAR(50),
    state VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    village VARCHAR(100),
    farm_size DECIMAL(8,2),
    farming_experience INTEGER,
    irrigation_type VARCHAR(30),
    
    -- Location fields (restricted to Indian boundaries)
    latitude DECIMAL(10,7) CHECK (latitude BETWEEN 6.0 AND 37.0),
    longitude DECIMAL(10,7) CHECK (longitude BETWEEN 68.0 AND 97.0),
    
    -- Profile and preferences
    profile_image_url VARCHAR(500),
    preferred_language VARCHAR(20) DEFAULT 'ENGLISH',
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- Create crop diagnoses table for agricultural health tracking
CREATE TABLE crop_diagnoses (
    id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Crop and image information
    crop_type VARCHAR(50) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    processed_image_url VARCHAR(500),
    
    -- AI diagnosis results
    diagnosis VARCHAR(200),
    confidence DECIMAL(3,2) CHECK (confidence BETWEEN 0.0 AND 1.0),
    severity VARCHAR(20),
    status VARCHAR(30) NOT NULL DEFAULT 'SUBMITTED',
    
    -- Farmer input
    symptoms TEXT,
    
    -- Location context (Indian boundaries)
    latitude DECIMAL(10,7) CHECK (latitude BETWEEN 6.0 AND 37.0),
    longitude DECIMAL(10,7) CHECK (longitude BETWEEN 68.0 AND 97.0),
    weather_conditions VARCHAR(200),
    
    -- AI recommendations
    ai_recommendations TEXT,
    
    -- Expert review
    expert_id BIGINT REFERENCES users(id),
    expert_review TEXT,
    expert_confidence DECIMAL(3,2) CHECK (expert_confidence BETWEEN 0.0 AND 1.0),
    
    -- Treatment information
    estimated_treatment_cost DECIMAL(8,2) CHECK (estimated_treatment_cost >= 0),
    currency VARCHAR(3) DEFAULT 'INR',
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_date TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expert_reviewed_at TIMESTAMP
);

-- Create treatment steps table for detailed agricultural guidance
CREATE TABLE treatment_steps (
    id BIGSERIAL PRIMARY KEY,
    diagnosis_id BIGINT NOT NULL REFERENCES crop_diagnoses(id) ON DELETE CASCADE,
    
    -- Step information
    step_number INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(30) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    
    -- Timing and materials
    estimated_time VARCHAR(50),
    required_materials TEXT,
    estimated_cost DECIMAL(8,2) CHECK (estimated_cost >= 0),
    currency VARCHAR(3) DEFAULT 'INR',
    
    -- Agricultural context
    best_time_to_apply VARCHAR(100),
    weather_requirements VARCHAR(200),
    safety_precautions TEXT,
    expected_results VARCHAR(500),
    alternatives TEXT,
    
    -- Flags
    is_organic BOOLEAN NOT NULL DEFAULT FALSE,
    suitable_for_small_farmers BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create marketplace orders table for agricultural commerce
CREATE TABLE marketplace_orders (
    id BIGSERIAL PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    buyer_id BIGINT NOT NULL REFERENCES users(id),
    seller_id BIGINT NOT NULL REFERENCES users(id),
    
    -- Order financial information
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    
    -- Order status tracking
    order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(30),
    payment_transaction_id VARCHAR(100),
    
    -- Delivery information
    delivery_address TEXT NOT NULL,
    delivery_state VARCHAR(50) NOT NULL,
    delivery_district VARCHAR(50) NOT NULL,
    delivery_pin_code VARCHAR(6) NOT NULL CHECK (delivery_pin_code ~ '^[0-9]{6}$'),
    contact_number VARCHAR(10) NOT NULL CHECK (contact_number ~ '^[6-9][0-9]{9}$'),
    
    -- Delivery tracking
    expected_delivery_date TIMESTAMP,
    actual_delivery_date TIMESTAMP,
    
    -- Notes and feedback
    order_notes TEXT,
    seller_notes TEXT,
    cancellation_reason VARCHAR(500),
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    cancelled_at TIMESTAMP
);

-- Create order items table for agricultural products
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
    
    -- Product information
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(30) NOT NULL,
    variety VARCHAR(100),
    
    -- Quantity and pricing
    quantity DECIMAL(10,3) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(20) NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL CHECK (unit_price > 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    
    -- Quality and origin
    quality_grade VARCHAR(20),
    origin VARCHAR(50),
    harvest_date TIMESTAMP,
    expiry_date TIMESTAMP,
    is_organic BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Handling
    handling_instructions VARCHAR(500),
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for optimal agricultural data query performance

-- User table indexes for farmer lookup and location-based queries
CREATE INDEX idx_users_mobile ON users(mobile_number);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_state_district ON users(state, district);
CREATE INDEX idx_users_location ON users(latitude, longitude);
CREATE INDEX idx_users_crop ON users(primary_crop);
CREATE INDEX idx_users_created ON users(created_at);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;

-- Crop diagnoses indexes for agricultural health tracking
CREATE INDEX idx_diagnoses_farmer ON crop_diagnoses(farmer_id);
CREATE INDEX idx_diagnoses_crop_type ON crop_diagnoses(crop_type);
CREATE INDEX idx_diagnoses_status ON crop_diagnoses(status);
CREATE INDEX idx_diagnoses_created ON crop_diagnoses(created_at DESC);
CREATE INDEX idx_diagnoses_confidence ON crop_diagnoses(confidence DESC);
CREATE INDEX idx_diagnoses_location ON crop_diagnoses(latitude, longitude);
CREATE INDEX idx_diagnoses_expert ON crop_diagnoses(expert_id);
CREATE INDEX idx_diagnoses_farmer_crop ON crop_diagnoses(farmer_id, crop_type);
CREATE INDEX idx_diagnoses_severity ON crop_diagnoses(severity);

-- Treatment steps indexes for agricultural guidance
CREATE INDEX idx_treatment_diagnosis ON treatment_steps(diagnosis_id);
CREATE INDEX idx_treatment_priority ON treatment_steps(priority);
CREATE INDEX idx_treatment_category ON treatment_steps(category);
CREATE INDEX idx_treatment_cost ON treatment_steps(estimated_cost);
CREATE INDEX idx_treatment_organic ON treatment_steps(is_organic) WHERE is_organic = TRUE;

-- Marketplace orders indexes for agricultural commerce
CREATE INDEX idx_orders_buyer ON marketplace_orders(buyer_id);
CREATE INDEX idx_orders_seller ON marketplace_orders(seller_id);
CREATE INDEX idx_orders_status ON marketplace_orders(order_status);
CREATE INDEX idx_orders_payment ON marketplace_orders(payment_status);
CREATE INDEX idx_orders_created ON marketplace_orders(created_at DESC);
CREATE INDEX idx_orders_total ON marketplace_orders(total_amount DESC);
CREATE INDEX idx_orders_delivery_location ON marketplace_orders(delivery_state, delivery_district);
CREATE INDEX idx_orders_number ON marketplace_orders(order_number);

-- Order items indexes for product analysis
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_name);
CREATE INDEX idx_items_category ON order_items(product_category);
CREATE INDEX idx_items_total ON order_items(total_price DESC);
CREATE INDEX idx_items_organic ON order_items(is_organic) WHERE is_organic = TRUE;
CREATE INDEX idx_items_quality ON order_items(quality_grade);

-- Composite indexes for complex agricultural queries
CREATE INDEX idx_diagnoses_farmer_date_status ON crop_diagnoses(farmer_id, created_at DESC, status);
CREATE INDEX idx_orders_buyer_status_date ON marketplace_orders(buyer_id, order_status, created_at DESC);
CREATE INDEX idx_users_location_crop ON users(state, district, primary_crop);

-- Partial indexes for active records (performance optimization)
CREATE INDEX idx_active_farmers ON users(id, state, district) WHERE user_type = 'FARMER' AND is_active = TRUE;
CREATE INDEX idx_pending_diagnoses ON crop_diagnoses(id, farmer_id, created_at) WHERE status IN ('SUBMITTED', 'PROCESSING');
CREATE INDEX idx_active_orders ON marketplace_orders(id, buyer_id, created_at) WHERE order_status NOT IN ('DELIVERED', 'CANCELLED');

-- Add constraints for agricultural data integrity
ALTER TABLE users ADD CONSTRAINT chk_user_type CHECK (user_type IN ('FARMER', 'EXPERT', 'ADMIN', 'VENDOR'));
ALTER TABLE users ADD CONSTRAINT chk_irrigation_type CHECK (irrigation_type IN ('RAIN_FED', 'DRIP', 'SPRINKLER', 'FLOOD', 'MICRO_SPRINKLER', 'TUBE_WELL', 'CANAL'));
ALTER TABLE users ADD CONSTRAINT chk_language CHECK (preferred_language IN ('ENGLISH', 'HINDI', 'MARATHI', 'GUJARATI', 'PUNJABI', 'TAMIL', 'TELUGU', 'KANNADA', 'BENGALI', 'ODIA'));

ALTER TABLE crop_diagnoses ADD CONSTRAINT chk_diagnosis_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'));
ALTER TABLE crop_diagnoses ADD CONSTRAINT chk_diagnosis_status CHECK (status IN ('SUBMITTED', 'PROCESSING', 'AI_COMPLETED', 'EXPERT_REVIEW', 'COMPLETED', 'FOLLOW_UP'));

ALTER TABLE treatment_steps ADD CONSTRAINT chk_treatment_category CHECK (category IN ('CHEMICAL_TREATMENT', 'ORGANIC_TREATMENT', 'CULTURAL_PRACTICE', 'IRRIGATION_MANAGEMENT', 'FERTILIZER_APPLICATION', 'PREVENTIVE_MEASURE', 'MONITORING', 'HARVESTING'));
ALTER TABLE treatment_steps ADD CONSTRAINT chk_treatment_priority CHECK (priority IN ('URGENT', 'HIGH', 'MEDIUM', 'LOW'));

ALTER TABLE marketplace_orders ADD CONSTRAINT chk_order_status CHECK (order_status IN ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'RETURNED'));
ALTER TABLE marketplace_orders ADD CONSTRAINT chk_payment_status CHECK (payment_status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED'));
ALTER TABLE marketplace_orders ADD CONSTRAINT chk_payment_method CHECK (payment_method IN ('UPI', 'NET_BANKING', 'DEBIT_CARD', 'CREDIT_CARD', 'COD', 'WALLET'));

ALTER TABLE order_items ADD CONSTRAINT chk_product_category CHECK (product_category IN ('SEEDS', 'FERTILIZERS', 'PESTICIDES', 'TOOLS', 'FRESH_PRODUCE', 'GRAINS', 'IRRIGATION', 'MACHINERY', 'LIVESTOCK', 'DAIRY', 'ORGANIC_INPUTS'));
ALTER TABLE order_items ADD CONSTRAINT chk_unit CHECK (unit IN ('KG', 'QUINTAL', 'TON', 'LITER', 'PIECE', 'PACKET', 'BAG', 'ACRE', 'SQUARE_METER', 'BUNDLE'));
ALTER TABLE order_items ADD CONSTRAINT chk_quality_grade CHECK (quality_grade IN ('PREMIUM', 'GRADE_A', 'GRADE_B', 'GRADE_C', 'UNGRADED'));

-- Create triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_diagnoses_updated_at BEFORE UPDATE ON crop_diagnoses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_treatment_updated_at BEFORE UPDATE ON treatment_steps 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON marketplace_orders 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert initial data for agricultural platform

-- Insert sample crop types for validation
INSERT INTO users (full_name, mobile_number, user_type, state, district, primary_crop, farm_size, farming_experience, is_verified) VALUES
('Demo Farmer', '9876543210', 'FARMER', 'Maharashtra', 'Nashik', 'Rice', 2.5, 10, TRUE),
('Agricultural Expert', '9876543211', 'EXPERT', 'Maharashtra', 'Pune', NULL, NULL, 20, TRUE),
('Platform Admin', '9876543212', 'ADMIN', 'Maharashtra', 'Mumbai', NULL, NULL, NULL, TRUE);

-- Add comments for agricultural context
COMMENT ON TABLE users IS 'Agricultural platform users including farmers, experts, and administrators';
COMMENT ON TABLE crop_diagnoses IS 'Crop health diagnoses with AI and expert recommendations';
COMMENT ON TABLE treatment_steps IS 'Step-by-step agricultural treatment guidance';
COMMENT ON TABLE marketplace_orders IS 'Agricultural product orders and transactions';
COMMENT ON TABLE order_items IS 'Individual agricultural products in marketplace orders';

COMMENT ON COLUMN users.mobile_number IS 'Indian mobile number format (10 digits starting with 6-9)';
COMMENT ON COLUMN users.primary_crop IS 'Main crop grown by farmer (Rice, Wheat, Cotton, etc.)';
COMMENT ON COLUMN users.latitude IS 'Farm latitude within Indian boundaries (6.0 to 37.0)';
COMMENT ON COLUMN users.longitude IS 'Farm longitude within Indian boundaries (68.0 to 97.0)';

COMMENT ON COLUMN crop_diagnoses.confidence IS 'AI diagnosis confidence score (0.0 to 1.0)';
COMMENT ON COLUMN crop_diagnoses.severity IS 'Issue severity: LOW, MEDIUM, HIGH, CRITICAL';
COMMENT ON COLUMN crop_diagnoses.status IS 'Diagnosis processing status';

COMMENT ON COLUMN marketplace_orders.order_number IS 'Unique order identifier with KS prefix';
COMMENT ON COLUMN marketplace_orders.delivery_pin_code IS 'Indian PIN code (6 digits)';
COMMENT ON COLUMN marketplace_orders.contact_number IS 'Indian mobile number for delivery contact';

-- Create views for common agricultural queries

-- Active farmers by state and crop
CREATE VIEW active_farmers_by_state AS
SELECT 
    state,
    district,
    primary_crop,
    COUNT(*) as farmer_count,
    AVG(farm_size) as avg_farm_size,
    AVG(farming_experience) as avg_experience
FROM users 
WHERE user_type = 'FARMER' AND is_active = TRUE 
GROUP BY state, district, primary_crop;

-- Crop health statistics
CREATE VIEW crop_health_stats AS
SELECT 
    crop_type,
    COUNT(*) as total_diagnoses,
    AVG(confidence) as avg_confidence,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_diagnoses,
    COUNT(CASE WHEN severity = 'HIGH' OR severity = 'CRITICAL' THEN 1 END) as critical_cases
FROM crop_diagnoses 
GROUP BY crop_type;

-- Marketplace performance metrics
CREATE VIEW marketplace_metrics AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    COUNT(CASE WHEN order_status = 'DELIVERED' THEN 1 END) as delivered_orders
FROM marketplace_orders 
GROUP BY DATE_TRUNC('month', created_at);

-- Grant permissions for application user
-- CREATE USER kheti_sahayak_app WITH PASSWORD 'secure_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO kheti_sahayak_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO kheti_sahayak_app;
