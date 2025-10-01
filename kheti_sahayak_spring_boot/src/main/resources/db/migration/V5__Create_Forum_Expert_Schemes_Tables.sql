-- =====================================================
-- V5: Create Community Forum, Expert Network, and Government Schemes Tables
-- =====================================================

-- =====================================================
-- COMMUNITY FORUM TABLES
-- =====================================================

-- Forum Topics Table
CREATE TABLE IF NOT EXISTS forum_topics (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    crop_type VARCHAR(50),
    region VARCHAR(100),
    season VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    upvote_count INTEGER DEFAULT 0,
    has_expert_answer BOOLEAN DEFAULT FALSE,
    last_activity_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_topic_status CHECK (status IN ('ACTIVE', 'RESOLVED', 'CLOSED', 'ARCHIVED'))
);

-- Forum Topic Tags Table
CREATE TABLE IF NOT EXISTS forum_topic_tags (
    topic_id BIGINT NOT NULL,
    tag VARCHAR(50) NOT NULL,
    PRIMARY KEY (topic_id, tag),
    FOREIGN KEY (topic_id) REFERENCES forum_topics(id) ON DELETE CASCADE
);

-- Forum Replies Table
CREATE TABLE IF NOT EXISTS forum_replies (
    id BIGSERIAL PRIMARY KEY,
    topic_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    is_expert_answer BOOLEAN DEFAULT FALSE,
    is_accepted_answer BOOLEAN DEFAULT FALSE,
    upvote_count INTEGER DEFAULT 0,
    downvote_count INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (topic_id) REFERENCES forum_topics(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =====================================================
-- EXPERT NETWORK TABLES
-- =====================================================

-- Expert Consultations Table
CREATE TABLE IF NOT EXISTS expert_consultations (
    id BIGSERIAL PRIMARY KEY,
    farmer_id BIGINT NOT NULL,
    expert_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50),
    crop_type VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    scheduled_at TIMESTAMP,
    duration_minutes INTEGER DEFAULT 30,
    expert_response TEXT,
    rating INTEGER,
    feedback TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (expert_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_consultation_status CHECK (status IN ('PENDING', 'SCHEDULED', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5)
);

-- =====================================================
-- GOVERNMENT SCHEMES TABLES
-- =====================================================

-- Government Schemes Table
CREATE TABLE IF NOT EXISTS government_schemes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50),
    benefit_amount DECIMAL(10, 2),
    eligibility_criteria TEXT,
    required_documents TEXT,
    application_process TEXT,
    official_website VARCHAR(500),
    helpline_number VARCHAR(20),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    applicable_states TEXT,
    applicable_crops TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Scheme Applications Table
CREATE TABLE IF NOT EXISTS scheme_applications (
    id BIGSERIAL PRIMARY KEY,
    scheme_id BIGINT NOT NULL,
    farmer_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    application_number VARCHAR(50) UNIQUE NOT NULL,
    documents_uploaded TEXT,
    farmer_notes TEXT,
    admin_notes TEXT,
    rejection_reason TEXT,
    approval_date TIMESTAMP,
    disbursement_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (scheme_id) REFERENCES government_schemes(id) ON DELETE CASCADE,
    FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_application_status CHECK (status IN ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'DISBURSED'))
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Forum indexes
CREATE INDEX idx_forum_topics_user_id ON forum_topics(user_id);
CREATE INDEX idx_forum_topics_category ON forum_topics(category);
CREATE INDEX idx_forum_topics_status ON forum_topics(status);
CREATE INDEX idx_forum_topics_last_activity ON forum_topics(last_activity_at DESC);
CREATE INDEX idx_forum_topics_pinned ON forum_topics(is_pinned);
CREATE INDEX idx_forum_replies_topic_id ON forum_replies(topic_id);
CREATE INDEX idx_forum_replies_user_id ON forum_replies(user_id);

-- Expert network indexes
CREATE INDEX idx_consultations_farmer_id ON expert_consultations(farmer_id);
CREATE INDEX idx_consultations_expert_id ON expert_consultations(expert_id);
CREATE INDEX idx_consultations_status ON expert_consultations(status);
CREATE INDEX idx_consultations_scheduled_at ON expert_consultations(scheduled_at);

-- Government schemes indexes
CREATE INDEX idx_schemes_category ON government_schemes(category);
CREATE INDEX idx_schemes_is_active ON government_schemes(is_active);
CREATE INDEX idx_applications_farmer_id ON scheme_applications(farmer_id);
CREATE INDEX idx_applications_scheme_id ON scheme_applications(scheme_id);
CREATE INDEX idx_applications_status ON scheme_applications(status);
CREATE INDEX idx_applications_number ON scheme_applications(application_number);

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Sample Forum Topics
INSERT INTO forum_topics (user_id, title, content, category, crop_type, status, view_count, reply_count, last_activity_at) VALUES
(1, 'Best practices for rice pest control?', 'I am facing issues with brown planthopper in my rice field. What are the best organic methods to control this pest?', 'PEST_CONTROL', 'Rice', 'ACTIVE', 45, 3, CURRENT_TIMESTAMP),
(1, 'Drip irrigation installation guide', 'Can someone share their experience with drip irrigation installation? What are the costs and benefits?', 'IRRIGATION', 'All', 'RESOLVED', 89, 5, CURRENT_TIMESTAMP),
(1, 'Government subsidy for organic farming', 'Are there any government schemes available for farmers transitioning to organic farming?', 'GOVERNMENT_SCHEMES', 'All', 'ACTIVE', 62, 2, CURRENT_TIMESTAMP);

-- Sample Forum Replies
INSERT INTO forum_replies (topic_id, user_id, content, is_expert_answer, upvote_count) VALUES
(1, 2, 'Neem oil spray is very effective against brown planthopper. Mix 5ml per liter of water and spray in the evening.', TRUE, 5),
(1, 1, 'Thank you! How often should I apply this spray?', FALSE, 0),
(2, 2, 'Drip irrigation can save up to 60% water. Initial investment is around ₹30,000 per acre but ROI is good.', TRUE, 8);

-- Sample Government Schemes
INSERT INTO government_schemes (name, description, category, benefit_amount, eligibility_criteria, required_documents, application_process, official_website, helpline_number, is_active, applicable_states) VALUES
('PM-KISAN', 'Pradhan Mantri Kisan Samman Nidhi - Direct income support of ₹6,000 per year to all landholding farmers in three equal installments.', 'SUBSIDY', 6000.00, 'All landholding farmers', 'Aadhaar card, Bank account details, Land ownership papers', 'Apply online at pmkisan.gov.in or visit nearest CSC center', 'https://pmkisan.gov.in', '155261', TRUE, 'All India'),
('Pradhan Mantri Fasal Bima Yojana', 'Crop insurance scheme providing financial support to farmers in case of crop loss due to natural calamities, pests, and diseases.', 'INSURANCE', NULL, 'All farmers growing notified crops', 'Aadhaar card, Bank details, Land records, Crop sowing certificate', 'Apply through banks or insurance companies', 'https://pmfby.gov.in', '1800-180-1551', TRUE, 'All India'),
('Kisan Credit Card (KCC)', 'Credit facility for farmers to meet short-term credit requirements for cultivation and other needs.', 'LOAN', NULL, 'Farmers with land ownership or tenancy', 'Land documents, Aadhaar card, Bank account proof', 'Apply at nearest bank branch', 'https://www.india.gov.in/kisan-credit-card-kcc', '180025888', TRUE, 'All India');

-- Sample Scheme Applications
INSERT INTO scheme_applications (scheme_id, farmer_id, status, application_number, farmer_notes) VALUES
(1, 1, 'APPROVED', 'APP1727787000001', 'Applied for PM-KISAN scheme. All documents submitted.'),
(2, 1, 'UNDER_REVIEW', 'APP1727787000002', 'Crop insurance application for Kharif 2025 season.');

-- Sample Expert Consultations
INSERT INTO expert_consultations (farmer_id, expert_id, title, description, category, crop_type, status, created_at) VALUES
(1, 2, 'Soil health improvement consultation', 'Need expert advice on improving soil fertility for better wheat yield.', 'SOIL_HEALTH', 'Wheat', 'PENDING', CURRENT_TIMESTAMP),
(1, 2, 'Disease identification in tomato plants', 'My tomato plants are showing yellow leaves and wilting. Need urgent expert consultation.', 'CROP_DISEASES', 'Vegetables', 'SCHEDULED', CURRENT_TIMESTAMP);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATE
-- =====================================================

-- Auto-update updated_at for forum topics
CREATE OR REPLACE FUNCTION update_forum_topics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_forum_topics_updated_at
    BEFORE UPDATE ON forum_topics
    FOR EACH ROW
    EXECUTE FUNCTION update_forum_topics_updated_at();

-- Auto-update updated_at for schemes
CREATE OR REPLACE FUNCTION update_schemes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_schemes_updated_at
    BEFORE UPDATE ON government_schemes
    FOR EACH ROW
    EXECUTE FUNCTION update_schemes_updated_at();

CREATE TRIGGER trigger_update_applications_updated_at
    BEFORE UPDATE ON scheme_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_schemes_updated_at();

