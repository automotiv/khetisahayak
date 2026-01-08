/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.sql(`
    ALTER TABLE products ADD COLUMN IF NOT EXISTS subcategory VARCHAR(255);
    ALTER TABLE products ADD COLUMN IF NOT EXISTS brand VARCHAR(255);
    ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS unit VARCHAR(50) DEFAULT 'piece';
    ALTER TABLE products ADD COLUMN IF NOT EXISTS image_urls TEXT[];
    ALTER TABLE products ADD COLUMN IF NOT EXISTS specifications JSONB;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS is_organic BOOLEAN DEFAULT FALSE;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    
    ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(255);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name VARCHAR(255);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10, 8);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11, 8);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url VARCHAR(500);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS summary TEXT;
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS subcategory VARCHAR(255);
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS difficulty_level VARCHAR(50) DEFAULT 'beginner';
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS video_url VARCHAR(500);
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS tags TEXT[];
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE;
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;
    ALTER TABLE educational_content ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
  `);
};

exports.down = (pgm) => {
  pgm.sql(`
    ALTER TABLE products DROP COLUMN IF EXISTS subcategory;
    ALTER TABLE products DROP COLUMN IF EXISTS brand;
    ALTER TABLE products DROP COLUMN IF EXISTS stock_quantity;
    ALTER TABLE products DROP COLUMN IF EXISTS unit;
    ALTER TABLE products DROP COLUMN IF EXISTS image_urls;
    ALTER TABLE products DROP COLUMN IF EXISTS specifications;
    ALTER TABLE products DROP COLUMN IF EXISTS is_organic;
    ALTER TABLE products DROP COLUMN IF EXISTS is_available;
    ALTER TABLE products DROP COLUMN IF EXISTS updated_at;
  `);
};
