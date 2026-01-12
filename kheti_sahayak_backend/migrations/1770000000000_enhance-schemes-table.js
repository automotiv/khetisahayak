/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    pgm.addColumns('schemes', {
        scheme_code: { type: 'varchar(50)', unique: true },
        scheme_type: { type: 'varchar(50)', default: 'subsidy' },
        implementing_agency: { type: 'varchar(255)' },
        ministry: { type: 'varchar(255)' },
        application_start_date: { type: 'timestamp' },
        application_end_date: { type: 'timestamp' },
        application_url: { type: 'varchar(500)' },
        helpline_number: { type: 'varchar(50)' },
        benefit_amount_min: { type: 'numeric(12, 2)' },
        benefit_amount_max: { type: 'numeric(12, 2)' },
        benefit_type: { type: 'varchar(50)' },
        eligibility_criteria: { type: 'jsonb' },
        required_documents: { type: 'jsonb' },
        priority: { type: 'integer', default: 0 },
        notification_enabled: { type: 'boolean', default: true },
        notification_days_before: { 
            type: 'integer[]',
            default: pgm.func("ARRAY[30, 15, 7, 3, 1]")
        },
        last_updated: { type: 'timestamp', default: pgm.func('current_timestamp') },
        source_url: { type: 'varchar(500)' },
        is_featured: { type: 'boolean', default: false },
        view_count: { type: 'integer', default: 0 },
        application_count: { type: 'integer', default: 0 }
    });

    pgm.createTable('scheme_subscriptions', {
        id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
        user_id: { 
            type: 'uuid', 
            notNull: true,
            references: 'users(id)',
            onDelete: 'CASCADE'
        },
        scheme_id: { 
            type: 'integer', 
            notNull: true,
            references: 'schemes(id)',
            onDelete: 'CASCADE'
        },
        notification_enabled: { type: 'boolean', default: true },
        subscribed_at: { type: 'timestamp', default: pgm.func('current_timestamp') },
        last_notified_at: { type: 'timestamp' },
        notification_preferences: {
            type: 'jsonb',
            default: '{"email": true, "push": true, "sms": false}'
        }
    });

    pgm.addConstraint('scheme_subscriptions', 'unique_user_scheme_subscription', {
        unique: ['user_id', 'scheme_id']
    });

    pgm.createTable('scheme_applications', {
        id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
        user_id: { 
            type: 'uuid', 
            notNull: true,
            references: 'users(id)',
            onDelete: 'CASCADE'
        },
        scheme_id: { 
            type: 'integer', 
            notNull: true,
            references: 'schemes(id)',
            onDelete: 'CASCADE'
        },
        status: {
            type: 'varchar(50)',
            default: 'draft',
            check: "status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn')"
        },
        application_reference: { type: 'varchar(100)' },
        submitted_at: { type: 'timestamp' },
        documents_submitted: { type: 'jsonb' },
        eligibility_check_result: { type: 'jsonb' },
        notes: { type: 'text' },
        created_at: { type: 'timestamp', default: pgm.func('current_timestamp') },
        updated_at: { type: 'timestamp', default: pgm.func('current_timestamp') }
    });

    pgm.createTable('scheme_notifications', {
        id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
        user_id: { 
            type: 'uuid', 
            notNull: true,
            references: 'users(id)',
            onDelete: 'CASCADE'
        },
        scheme_id: { 
            type: 'integer', 
            notNull: true,
            references: 'schemes(id)',
            onDelete: 'CASCADE'
        },
        notification_type: {
            type: 'varchar(50)',
            notNull: true,
            check: "notification_type IN ('deadline_reminder', 'new_scheme', 'scheme_update', 'eligibility_match', 'application_status')"
        },
        title: { type: 'varchar(255)', notNull: true },
        message: { type: 'text', notNull: true },
        is_read: { type: 'boolean', default: false },
        sent_via: { type: 'varchar(50)[]', default: pgm.func("ARRAY['push']") },
        sent_at: { type: 'timestamp', default: pgm.func('current_timestamp') },
        read_at: { type: 'timestamp' }
    });

    pgm.createTable('user_eligibility_profiles', {
        id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
        user_id: { 
            type: 'uuid', 
            notNull: true,
            unique: true,
            references: 'users(id)',
            onDelete: 'CASCADE'
        },
        farm_size_hectares: { type: 'numeric(10, 2)' },
        annual_income: { type: 'numeric(12, 2)' },
        land_ownership_type: { 
            type: 'varchar(50)',
            check: "land_ownership_type IN ('owner', 'tenant', 'sharecropper', 'lease')"
        },
        primary_crops: { type: 'text[]' },
        state: { type: 'varchar(100)' },
        district: { type: 'varchar(100)' },
        block: { type: 'varchar(100)' },
        village: { type: 'varchar(100)' },
        farmer_category: {
            type: 'varchar(50)',
            check: "farmer_category IN ('marginal', 'small', 'semi_medium', 'medium', 'large')"
        },
        social_category: { type: 'varchar(50)' },
        gender: { type: 'varchar(20)' },
        age: { type: 'integer' },
        has_bank_account: { type: 'boolean', default: false },
        has_aadhar: { type: 'boolean', default: false },
        has_kcc: { type: 'boolean', default: false },
        irrigation_type: { type: 'varchar(50)' },
        soil_type: { type: 'varchar(50)' },
        additional_criteria: { type: 'jsonb' },
        created_at: { type: 'timestamp', default: pgm.func('current_timestamp') },
        updated_at: { type: 'timestamp', default: pgm.func('current_timestamp') }
    });

    pgm.createIndex('schemes', 'scheme_type');
    pgm.createIndex('schemes', 'category');
    pgm.createIndex('schemes', 'active');
    pgm.createIndex('schemes', 'application_end_date');
    pgm.createIndex('schemes', 'priority');
    pgm.createIndex('schemes', 'is_featured');

    pgm.createIndex('scheme_subscriptions', 'user_id');
    pgm.createIndex('scheme_subscriptions', 'scheme_id');

    pgm.createIndex('scheme_applications', 'user_id');
    pgm.createIndex('scheme_applications', 'scheme_id');
    pgm.createIndex('scheme_applications', 'status');

    pgm.createIndex('scheme_notifications', 'user_id');
    pgm.createIndex('scheme_notifications', 'scheme_id');
    pgm.createIndex('scheme_notifications', 'is_read');
    pgm.createIndex('scheme_notifications', 'sent_at');

    pgm.createIndex('user_eligibility_profiles', 'state');
    pgm.createIndex('user_eligibility_profiles', 'district');
    pgm.createIndex('user_eligibility_profiles', 'farmer_category');
};

exports.down = pgm => {
    pgm.dropTable('user_eligibility_profiles', { ifExists: true });
    pgm.dropTable('scheme_notifications', { ifExists: true });
    pgm.dropTable('scheme_applications', { ifExists: true });
    pgm.dropTable('scheme_subscriptions', { ifExists: true });

    pgm.dropColumns('schemes', [
        'scheme_code',
        'scheme_type',
        'implementing_agency',
        'ministry',
        'application_start_date',
        'application_end_date',
        'application_url',
        'helpline_number',
        'benefit_amount_min',
        'benefit_amount_max',
        'benefit_type',
        'eligibility_criteria',
        'required_documents',
        'priority',
        'notification_enabled',
        'notification_days_before',
        'last_updated',
        'source_url',
        'is_featured',
        'view_count',
        'application_count'
    ]);
};
