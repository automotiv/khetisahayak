/**
 * Migration: Create Technology Adoption Hub tables
 *
 * Supports New Technology Adoption Hub (Epic #396)
 */

exports.up = (pgm) => {
  // Technology categories table
  pgm.createTable('technology_categories', {
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
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    display_order: {
      type: 'integer',
      default: 0
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Agricultural technologies table
  pgm.createTable('agricultural_technologies', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    category_id: {
      type: 'uuid',
      notNull: true,
      references: '"technology_categories"',
      onDelete: 'RESTRICT'
    },
    name: {
      type: 'varchar(200)',
      notNull: true
    },
    name_hi: {
      type: 'varchar(200)'
    },
    slug: {
      type: 'varchar(200)',
      unique: true
    },
    description: {
      type: 'text'
    },
    description_hi: {
      type: 'text'
    },
    benefits: {
      type: 'jsonb',
      default: '[]'
    },
    suitable_crops: {
      type: 'jsonb',
      default: '[]'
    },
    suitable_farm_sizes: {
      type: 'jsonb',
      default: '[]'
    },
    implementation_cost_min: {
      type: 'decimal(12, 2)'
    },
    implementation_cost_max: {
      type: 'decimal(12, 2)'
    },
    expected_roi_percent: {
      type: 'decimal(5, 2)'
    },
    payback_period_months: {
      type: 'integer'
    },
    difficulty_level: {
      type: 'varchar(20)',
      default: 'medium',
      check: "difficulty_level IN ('easy', 'medium', 'hard', 'expert')"
    },
    images: {
      type: 'jsonb',
      default: '[]'
    },
    video_url: {
      type: 'text'
    },
    implementation_steps: {
      type: 'jsonb',
      default: '[]'
    },
    required_resources: {
      type: 'jsonb',
      default: '[]'
    },
    government_subsidies: {
      type: 'jsonb',
      default: '[]'
    },
    adoption_count: {
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
    is_featured: {
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

  // Courses table
  pgm.createTable('courses', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    technology_id: {
      type: 'uuid',
      references: '"agricultural_technologies"',
      onDelete: 'SET NULL'
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    title_hi: {
      type: 'varchar(200)'
    },
    slug: {
      type: 'varchar(200)',
      unique: true
    },
    description: {
      type: 'text'
    },
    description_hi: {
      type: 'text'
    },
    instructor_name: {
      type: 'varchar(100)'
    },
    instructor_bio: {
      type: 'text'
    },
    instructor_image: {
      type: 'text'
    },
    thumbnail_url: {
      type: 'text'
    },
    duration_minutes: {
      type: 'integer'
    },
    difficulty_level: {
      type: 'varchar(20)',
      default: 'beginner',
      check: "difficulty_level IN ('beginner', 'intermediate', 'advanced')"
    },
    language: {
      type: 'varchar(10)',
      default: 'en'
    },
    price: {
      type: 'decimal(10, 2)',
      default: 0
    },
    is_free: {
      type: 'boolean',
      default: true
    },
    enrollment_count: {
      type: 'integer',
      default: 0
    },
    completion_count: {
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
    certificate_available: {
      type: 'boolean',
      default: false
    },
    is_featured: {
      type: 'boolean',
      default: false
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    published_at: {
      type: 'timestamp with time zone'
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

  // Course modules table
  pgm.createTable('course_modules', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    course_id: {
      type: 'uuid',
      notNull: true,
      references: '"courses"',
      onDelete: 'CASCADE'
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    title_hi: {
      type: 'varchar(200)'
    },
    description: {
      type: 'text'
    },
    order_index: {
      type: 'integer',
      notNull: true
    },
    duration_minutes: {
      type: 'integer'
    },
    is_preview: {
      type: 'boolean',
      default: false
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Course lessons table
  pgm.createTable('course_lessons', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    module_id: {
      type: 'uuid',
      notNull: true,
      references: '"course_modules"',
      onDelete: 'CASCADE'
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    title_hi: {
      type: 'varchar(200)'
    },
    content_type: {
      type: 'varchar(20)',
      notNull: true,
      check: "content_type IN ('video', 'text', 'quiz', 'assignment', 'download')"
    },
    content: {
      type: 'text'
    },
    video_url: {
      type: 'text'
    },
    duration_minutes: {
      type: 'integer'
    },
    order_index: {
      type: 'integer',
      notNull: true
    },
    is_preview: {
      type: 'boolean',
      default: false
    },
    attachments: {
      type: 'jsonb',
      default: '[]'
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Course enrollments table
  pgm.createTable('course_enrollments', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    course_id: {
      type: 'uuid',
      notNull: true,
      references: '"courses"',
      onDelete: 'CASCADE'
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    progress_percent: {
      type: 'decimal(5, 2)',
      default: 0
    },
    completed_lessons: {
      type: 'jsonb',
      default: '[]'
    },
    last_lesson_id: {
      type: 'uuid'
    },
    status: {
      type: 'varchar(20)',
      default: 'enrolled',
      check: "status IN ('enrolled', 'in_progress', 'completed', 'dropped')"
    },
    completed_at: {
      type: 'timestamp with time zone'
    },
    certificate_url: {
      type: 'text'
    },
    enrolled_at: {
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

  // Technology adoption experiences table
  pgm.createTable('technology_experiences', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    technology_id: {
      type: 'uuid',
      notNull: true,
      references: '"agricultural_technologies"',
      onDelete: 'CASCADE'
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    experience_text: {
      type: 'text',
      notNull: true
    },
    implementation_cost: {
      type: 'decimal(12, 2)'
    },
    roi_achieved_percent: {
      type: 'decimal(5, 2)'
    },
    time_to_implement_days: {
      type: 'integer'
    },
    farm_size_acres: {
      type: 'decimal(10, 2)'
    },
    crop_type: {
      type: 'varchar(100)'
    },
    rating: {
      type: 'integer',
      notNull: true,
      check: 'rating >= 1 AND rating <= 5'
    },
    would_recommend: {
      type: 'boolean',
      default: true
    },
    images: {
      type: 'jsonb',
      default: '[]'
    },
    likes_count: {
      type: 'integer',
      default: 0
    },
    comments_count: {
      type: 'integer',
      default: 0
    },
    is_verified: {
      type: 'boolean',
      default: false
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Technology demo requests table
  pgm.createTable('technology_demo_requests', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    technology_id: {
      type: 'uuid',
      notNull: true,
      references: '"agricultural_technologies"',
      onDelete: 'CASCADE'
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    preferred_date: {
      type: 'date'
    },
    preferred_time: {
      type: 'varchar(50)'
    },
    location: {
      type: 'text'
    },
    farm_size_acres: {
      type: 'decimal(10, 2)'
    },
    current_crops: {
      type: 'text'
    },
    contact_phone: {
      type: 'varchar(20)'
    },
    notes: {
      type: 'text'
    },
    status: {
      type: 'varchar(20)',
      default: 'pending',
      check: "status IN ('pending', 'scheduled', 'completed', 'cancelled')"
    },
    scheduled_date: {
      type: 'timestamp with time zone'
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

  // Create indexes
  pgm.createIndex('agricultural_technologies', 'category_id');
  pgm.createIndex('agricultural_technologies', 'slug');
  pgm.createIndex('agricultural_technologies', 'is_featured');
  pgm.createIndex('courses', 'technology_id');
  pgm.createIndex('courses', 'slug');
  pgm.createIndex('courses', 'is_featured');
  pgm.createIndex('course_modules', ['course_id', 'order_index']);
  pgm.createIndex('course_lessons', ['module_id', 'order_index']);
  pgm.createIndex('course_enrollments', ['course_id', 'user_id'], { unique: true });
  pgm.createIndex('course_enrollments', 'user_id');
  pgm.createIndex('technology_experiences', 'technology_id');
  pgm.createIndex('technology_experiences', 'user_id');
  pgm.createIndex('technology_demo_requests', 'technology_id');
  pgm.createIndex('technology_demo_requests', 'user_id');

  // Add triggers
  pgm.sql(`
    CREATE TRIGGER update_agricultural_technologies_updated_at
    BEFORE UPDATE ON agricultural_technologies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_course_enrollments_updated_at
    BEFORE UPDATE ON course_enrollments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_technology_demo_requests_updated_at
    BEFORE UPDATE ON technology_demo_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('technology_demo_requests');
  pgm.dropTable('technology_experiences');
  pgm.dropTable('course_enrollments');
  pgm.dropTable('course_lessons');
  pgm.dropTable('course_modules');
  pgm.dropTable('courses');
  pgm.dropTable('agricultural_technologies');
  pgm.dropTable('technology_categories');
};
