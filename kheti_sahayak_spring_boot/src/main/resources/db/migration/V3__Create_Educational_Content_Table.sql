-- Create educational_content table for agricultural knowledge base
CREATE TABLE IF NOT EXISTS educational_content (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    author VARCHAR(100) NOT NULL,
    excerpt VARCHAR(500),
    featured_image_url VARCHAR(500),
    video_url VARCHAR(500),
    content_type VARCHAR(20) NOT NULL DEFAULT 'ARTICLE',
    difficulty_level VARCHAR(20) NOT NULL DEFAULT 'BEGINNER',
    estimated_reading_time_minutes INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    published BOOLEAN DEFAULT FALSE,
    featured BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    crops_applicable VARCHAR(500),
    season_applicable VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP,
    
    CONSTRAINT chk_content_type CHECK (content_type IN ('ARTICLE', 'VIDEO', 'INFOGRAPHIC', 'TUTORIAL', 'CASE_STUDY', 'FAQ')),
    CONSTRAINT chk_difficulty_level CHECK (difficulty_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT'))
);

-- Create content_tags table for tagging system
CREATE TABLE IF NOT EXISTS content_tags (
    content_id BIGINT NOT NULL,
    tag VARCHAR(50) NOT NULL,
    PRIMARY KEY (content_id, tag),
    FOREIGN KEY (content_id) REFERENCES educational_content(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX idx_educational_content_category ON educational_content(category);
CREATE INDEX idx_educational_content_published ON educational_content(published);
CREATE INDEX idx_educational_content_published_at ON educational_content(published_at DESC);
CREATE INDEX idx_educational_content_language ON educational_content(language);
CREATE INDEX idx_educational_content_view_count ON educational_content(view_count DESC);
CREATE INDEX idx_educational_content_featured ON educational_content(featured);
CREATE INDEX idx_educational_content_crops_applicable ON educational_content(crops_applicable);

-- Insert sample educational content for farmers
INSERT INTO educational_content (
    title, content, category, author, excerpt, content_type, difficulty_level,
    estimated_reading_time_minutes, published, featured, language, crops_applicable, season_applicable
) VALUES
(
    'Best Practices for Rice Cultivation in Kharif Season',
    'Rice is one of the most important Kharif crops in India. This comprehensive guide covers everything from seed selection to harvest. Key steps include: 1) Seed treatment with fungicides, 2) Proper land preparation with 2-3 ploughings, 3) Maintaining water levels at 5-7 cm, 4) Applying fertilizers at correct intervals, 5) Regular monitoring for pests and diseases.',
    'CROP_MANAGEMENT',
    'Dr. Ramesh Kumar',
    'Complete guide to rice farming during monsoon season with modern techniques and traditional wisdom.',
    'ARTICLE',
    'BEGINNER',
    10,
    TRUE,
    TRUE,
    'en',
    'Rice',
    'KHARIF'
),
(
    'Organic Pest Control Methods for Vegetables',
    'Organic farming is gaining popularity. This article covers natural pest control methods: 1) Neem oil spray (5ml per liter), 2) Companion planting with marigolds, 3) Introducing beneficial insects, 4) Garlic-chili spray for aphids, 5) Crop rotation to break pest cycles. These methods are safe, effective, and environmentally friendly.',
    'PEST_CONTROL',
    'Dr. Priya Sharma',
    'Learn chemical-free pest control methods for healthy vegetables and sustainable farming.',
    'ARTICLE',
    'INTERMEDIATE',
    8,
    TRUE,
    TRUE,
    'en',
    'Vegetables',
    'ALL'
),
(
    'Drip Irrigation: Save Water and Increase Yield',
    'Drip irrigation can save up to 60% water compared to traditional methods. Installation steps: 1) Design the layout based on crop spacing, 2) Install main and sub-main pipes, 3) Connect drippers at plant locations, 4) Add filters to prevent clogging, 5) Maintain proper pressure. Benefits include water conservation, reduced weed growth, and better fertilizer utilization.',
    'IRRIGATION',
    'Engineer Suresh Patel',
    'Modern irrigation technique that saves water while improving crop productivity.',
    'TUTORIAL',
    'INTERMEDIATE',
    15,
    TRUE,
    FALSE,
    'en',
    'All Crops',
    'ALL'
),
(
    'Soil Health Management for Better Yields',
    'Healthy soil is the foundation of successful farming. Key practices: 1) Regular soil testing (pH, NPK levels), 2) Adding organic matter through compost and FYM, 3) Crop rotation to maintain nutrients, 4) Green manuring with legumes, 5) Avoiding excessive chemical use. Maintain soil pH between 6.0-7.5 for most crops.',
    'SOIL_HEALTH',
    'Dr. Anjali Verma',
    'Comprehensive guide to maintaining and improving soil fertility naturally.',
    'ARTICLE',
    'BEGINNER',
    12,
    TRUE,
    TRUE,
    'en',
    'All Crops',
    'ALL'
),
(
    'PM-KISAN Scheme: Complete Application Guide',
    'The PM-KISAN scheme provides ₹6,000 annual income support to farmers. Eligibility: All landholding farmers are eligible. Required documents: Aadhaar card, bank account details, land ownership papers. Application process: 1) Visit pmkisan.gov.in, 2) Click on Farmers Corner, 3) Fill in details, 4) Submit documents. Payment is made in three installments of ₹2,000 each.',
    'GOVERNMENT_SCHEMES',
    'Government Officer',
    'Step-by-step guide to apply for PM-KISAN direct benefit transfer scheme.',
    'FAQ',
    'BEGINNER',
    5,
    TRUE,
    FALSE,
    'en',
    'All Crops',
    'ALL'
);

-- Insert sample tags
INSERT INTO content_tags (content_id, tag) VALUES
(1, 'rice'), (1, 'kharif'), (1, 'monsoon'), (1, 'cultivation'),
(2, 'organic'), (2, 'pest-control'), (2, 'vegetables'), (2, 'natural'),
(3, 'irrigation'), (3, 'water-saving'), (3, 'drip-system'), (3, 'technology'),
(4, 'soil'), (4, 'fertility'), (4, 'organic-matter'), (4, 'sustainability'),
(5, 'government'), (5, 'pm-kisan'), (5, 'subsidy'), (5, 'financial-aid');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_educational_content_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic updated_at update
CREATE TRIGGER trigger_update_educational_content_updated_at
    BEFORE UPDATE ON educational_content
    FOR EACH ROW
    EXECUTE FUNCTION update_educational_content_updated_at();

