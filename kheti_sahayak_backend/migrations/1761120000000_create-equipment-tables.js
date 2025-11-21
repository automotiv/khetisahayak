/**
 * Migration: Create Equipment Rental Platform tables
 *
 * Supports Farm Machinery Lending & Rental Platform (Epic #395)
 */

exports.up = (pgm) => {
  // Equipment categories table
  pgm.createTable('equipment_categories', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    name: {
      type: 'varchar(100)',
      notNull: true
    },
    name_hi: {
      type: 'varchar(100)'
    },
    description: {
      type: 'text'
    },
    icon: {
      type: 'varchar(100)'
    },
    parent_id: {
      type: 'uuid',
      references: '"equipment_categories"',
      onDelete: 'SET NULL'
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Equipment listings table
  pgm.createTable('equipment_listings', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    owner_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    category_id: {
      type: 'uuid',
      notNull: true,
      references: '"equipment_categories"',
      onDelete: 'RESTRICT'
    },
    name: {
      type: 'varchar(200)',
      notNull: true
    },
    description: {
      type: 'text'
    },
    brand: {
      type: 'varchar(100)'
    },
    model: {
      type: 'varchar(100)'
    },
    year_of_manufacture: {
      type: 'integer'
    },
    condition: {
      type: 'varchar(20)',
      notNull: true,
      default: 'good',
      check: "condition IN ('excellent', 'good', 'fair', 'needs_repair')"
    },
    hourly_rate: {
      type: 'decimal(10, 2)'
    },
    daily_rate: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    weekly_rate: {
      type: 'decimal(10, 2)'
    },
    deposit_amount: {
      type: 'decimal(10, 2)'
    },
    location_address: {
      type: 'text'
    },
    location_lat: {
      type: 'decimal(10, 8)'
    },
    location_lng: {
      type: 'decimal(11, 8)'
    },
    service_radius_km: {
      type: 'integer',
      default: 50
    },
    images: {
      type: 'jsonb',
      default: '[]'
    },
    specifications: {
      type: 'jsonb',
      default: '{}'
    },
    availability_status: {
      type: 'varchar(20)',
      notNull: true,
      default: 'available',
      check: "availability_status IN ('available', 'rented', 'maintenance', 'unavailable')"
    },
    is_operator_included: {
      type: 'boolean',
      default: false
    },
    operator_rate_per_day: {
      type: 'decimal(10, 2)'
    },
    minimum_rental_days: {
      type: 'integer',
      default: 1
    },
    maximum_rental_days: {
      type: 'integer'
    },
    total_rentals: {
      type: 'integer',
      default: 0
    },
    average_rating: {
      type: 'decimal(2, 1)',
      default: 0
    },
    review_count: {
      type: 'integer',
      default: 0
    },
    is_verified: {
      type: 'boolean',
      default: false
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Equipment bookings table
  pgm.createTable('equipment_bookings', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    equipment_id: {
      type: 'uuid',
      notNull: true,
      references: '"equipment_listings"',
      onDelete: 'CASCADE'
    },
    renter_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    owner_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    start_date: {
      type: 'date',
      notNull: true
    },
    end_date: {
      type: 'date',
      notNull: true
    },
    rental_days: {
      type: 'integer',
      notNull: true
    },
    daily_rate: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    operator_included: {
      type: 'boolean',
      default: false
    },
    operator_rate: {
      type: 'decimal(10, 2)'
    },
    subtotal: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    deposit_amount: {
      type: 'decimal(10, 2)'
    },
    service_fee: {
      type: 'decimal(10, 2)',
      default: 0
    },
    total_amount: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    delivery_address: {
      type: 'text'
    },
    delivery_lat: {
      type: 'decimal(10, 8)'
    },
    delivery_lng: {
      type: 'decimal(11, 8)'
    },
    status: {
      type: 'varchar(20)',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'disputed')"
    },
    payment_status: {
      type: 'varchar(20)',
      notNull: true,
      default: 'pending',
      check: "payment_status IN ('pending', 'paid', 'refunded', 'partially_refunded')"
    },
    cancellation_reason: {
      type: 'text'
    },
    cancelled_by: {
      type: 'uuid',
      references: '"users"'
    },
    notes: {
      type: 'text'
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Equipment reviews table
  pgm.createTable('equipment_reviews', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    booking_id: {
      type: 'uuid',
      notNull: true,
      unique: true,
      references: '"equipment_bookings"',
      onDelete: 'CASCADE'
    },
    equipment_id: {
      type: 'uuid',
      notNull: true,
      references: '"equipment_listings"',
      onDelete: 'CASCADE'
    },
    reviewer_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    rating: {
      type: 'integer',
      notNull: true,
      check: 'rating >= 1 AND rating <= 5'
    },
    review_text: {
      type: 'text'
    },
    condition_rating: {
      type: 'integer',
      check: 'condition_rating >= 1 AND condition_rating <= 5'
    },
    owner_rating: {
      type: 'integer',
      check: 'owner_rating >= 1 AND owner_rating <= 5'
    },
    value_rating: {
      type: 'integer',
      check: 'value_rating >= 1 AND value_rating <= 5'
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create indexes
  pgm.createIndex('equipment_listings', 'owner_id');
  pgm.createIndex('equipment_listings', 'category_id');
  pgm.createIndex('equipment_listings', 'availability_status');
  pgm.createIndex('equipment_listings', ['location_lat', 'location_lng']);
  pgm.createIndex('equipment_bookings', 'equipment_id');
  pgm.createIndex('equipment_bookings', 'renter_id');
  pgm.createIndex('equipment_bookings', 'owner_id');
  pgm.createIndex('equipment_bookings', 'status');
  pgm.createIndex('equipment_bookings', ['start_date', 'end_date']);
  pgm.createIndex('equipment_reviews', 'equipment_id');

  // Add triggers for updated_at
  pgm.sql(`
    CREATE TRIGGER update_equipment_listings_updated_at
    BEFORE UPDATE ON equipment_listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_equipment_bookings_updated_at
    BEFORE UPDATE ON equipment_bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('equipment_reviews');
  pgm.dropTable('equipment_bookings');
  pgm.dropTable('equipment_listings');
  pgm.dropTable('equipment_categories');
};
