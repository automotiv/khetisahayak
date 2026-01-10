/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = (pgm) => {
  // Expert availability table
  pgm.createTable('expert_availability', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    expert_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    day_of_week: {
      type: 'integer',
      notNull: true,
      check: 'day_of_week >= 0 AND day_of_week <= 6',
    },
    start_time: {
      type: 'time',
      notNull: true,
    },
    end_time: {
      type: 'time',
      notNull: true,
    },
    slot_duration_minutes: {
      type: 'integer',
      notNull: true,
      default: 30,
    },
    is_available: {
      type: 'boolean',
      notNull: true,
      default: true,
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  // Expert profiles table (extends users)
  pgm.createTable('expert_profiles', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      unique: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    specialization: {
      type: 'varchar(255)',
      notNull: true,
    },
    expertise_areas: {
      type: 'text[]',
      default: '{}',
    },
    qualification: {
      type: 'varchar(255)',
    },
    experience_years: {
      type: 'integer',
      default: 0,
    },
    bio: {
      type: 'text',
    },
    languages: {
      type: 'text[]',
      default: "'{Hindi,English}'",
    },
    consultation_fee: {
      type: 'numeric(10, 2)',
      notNull: true,
      default: 200,
    },
    rating: {
      type: 'numeric(3, 2)',
      default: 0,
    },
    total_reviews: {
      type: 'integer',
      default: 0,
    },
    total_consultations: {
      type: 'integer',
      default: 0,
    },
    is_verified: {
      type: 'boolean',
      default: false,
    },
    is_active: {
      type: 'boolean',
      default: true,
    },
    profile_image_url: {
      type: 'varchar(500)',
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  // Consultations table
  pgm.createTable('consultations', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    farmer_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    expert_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    scheduled_at: {
      type: 'timestamp with time zone',
      notNull: true,
    },
    duration_minutes: {
      type: 'integer',
      notNull: true,
      default: 30,
    },
    status: {
      type: 'varchar(20)',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')",
    },
    consultation_type: {
      type: 'varchar(20)',
      notNull: true,
      default: 'video',
      check: "consultation_type IN ('video', 'audio', 'chat')",
    },
    issue_description: {
      type: 'text',
    },
    issue_images: {
      type: 'text[]',
      default: '{}',
    },
    diagnosis_id: {
      type: 'uuid',
      references: 'diagnostics(id)',
      onDelete: 'SET NULL',
    },
    call_room_id: {
      type: 'varchar(100)',
    },
    call_started_at: {
      type: 'timestamp with time zone',
    },
    call_ended_at: {
      type: 'timestamp with time zone',
    },
    actual_duration_minutes: {
      type: 'integer',
    },
    expert_notes: {
      type: 'text',
    },
    recommendations: {
      type: 'text',
    },
    follow_up_required: {
      type: 'boolean',
      default: false,
    },
    follow_up_date: {
      type: 'date',
    },
    payment_id: {
      type: 'uuid',
      references: 'payments(id)',
      onDelete: 'SET NULL',
    },
    payment_status: {
      type: 'varchar(20)',
      default: 'pending',
      check: "payment_status IN ('pending', 'paid', 'refunded', 'failed')",
    },
    amount: {
      type: 'numeric(10, 2)',
      notNull: true,
    },
    cancellation_reason: {
      type: 'text',
    },
    cancelled_by: {
      type: 'uuid',
      references: 'users(id)',
      onDelete: 'SET NULL',
    },
    cancelled_at: {
      type: 'timestamp with time zone',
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  // Consultation reviews table
  pgm.createTable('consultation_reviews', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    consultation_id: {
      type: 'uuid',
      notNull: true,
      unique: true,
      references: 'consultations(id)',
      onDelete: 'CASCADE',
    },
    farmer_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    expert_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    rating: {
      type: 'integer',
      notNull: true,
      check: 'rating >= 1 AND rating <= 5',
    },
    review_text: {
      type: 'text',
    },
    was_helpful: {
      type: 'boolean',
    },
    would_recommend: {
      type: 'boolean',
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  // Create indexes for performance
  pgm.createIndex('expert_availability', 'expert_id');
  pgm.createIndex('expert_availability', ['expert_id', 'day_of_week']);
  pgm.createIndex('expert_profiles', 'user_id');
  pgm.createIndex('expert_profiles', 'specialization');
  pgm.createIndex('expert_profiles', 'is_verified');
  pgm.createIndex('consultations', 'farmer_id');
  pgm.createIndex('consultations', 'expert_id');
  pgm.createIndex('consultations', 'status');
  pgm.createIndex('consultations', 'scheduled_at');
  pgm.createIndex('consultations', ['expert_id', 'scheduled_at']);
  pgm.createIndex('consultation_reviews', 'expert_id');

  // Update users table to add expert role if not exists
  pgm.sql(`
    ALTER TABLE users 
    DROP CONSTRAINT IF EXISTS users_role_check;
    
    ALTER TABLE users 
    ADD CONSTRAINT users_role_check 
    CHECK (role IN ('user', 'admin', 'content-creator', 'expert', 'farmer'));
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('consultation_reviews', { ifExists: true, cascade: true });
  pgm.dropTable('consultations', { ifExists: true, cascade: true });
  pgm.dropTable('expert_profiles', { ifExists: true, cascade: true });
  pgm.dropTable('expert_availability', { ifExists: true, cascade: true });
};
