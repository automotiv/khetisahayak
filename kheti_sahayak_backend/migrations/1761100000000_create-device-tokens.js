/**
 * Migration: Create Device Tokens table for FCM
 *
 * Stores FCM device tokens for push notifications
 */

exports.up = (pgm) => {
  // Create device_tokens table
  pgm.createTable('device_tokens', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    token: {
      type: 'text',
      notNull: true
    },
    platform: {
      type: 'varchar(20)',
      notNull: true,
      check: "platform IN ('android', 'ios', 'web')"
    },
    device_name: {
      type: 'varchar(100)'
    },
    app_version: {
      type: 'varchar(20)'
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    last_used_at: {
      type: 'timestamp with time zone',
      default: pgm.func('CURRENT_TIMESTAMP')
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

  // Create unique constraint on user + token
  pgm.createIndex('device_tokens', ['user_id', 'token'], { unique: true });

  // Create index for active tokens lookup
  pgm.createIndex('device_tokens', ['user_id', 'is_active']);

  // Create index for token lookup (for invalidation)
  pgm.createIndex('device_tokens', ['token']);

  // Add trigger for updated_at
  pgm.sql(`
    CREATE TRIGGER update_device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  // Create notification_topics table for topic subscriptions
  pgm.createTable('notification_topics', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    topic: {
      type: 'varchar(100)',
      notNull: true
    },
    subscribed_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create unique constraint on user + topic
  pgm.createIndex('notification_topics', ['user_id', 'topic'], { unique: true });

  // Create notification_history table
  pgm.createTable('notification_history', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      references: '"users"',
      onDelete: 'CASCADE'
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    body: {
      type: 'text',
      notNull: true
    },
    notification_type: {
      type: 'varchar(50)',
      notNull: true
    },
    data: {
      type: 'jsonb'
    },
    is_read: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    sent_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    read_at: {
      type: 'timestamp with time zone'
    }
  });

  // Create index for user notifications
  pgm.createIndex('notification_history', ['user_id', 'sent_at']);
  pgm.createIndex('notification_history', ['user_id', 'is_read']);
};

exports.down = (pgm) => {
  pgm.dropTable('notification_history');
  pgm.dropTable('notification_topics');
  pgm.dropTable('device_tokens');
};
