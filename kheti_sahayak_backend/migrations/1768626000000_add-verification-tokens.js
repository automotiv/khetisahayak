exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.addColumns('users', {
    email_verified: {
      type: 'boolean',
      default: false,
      notNull: true,
    },
    phone_verified: {
      type: 'boolean',
      default: false,
      notNull: true,
    },
    email_verification_token: {
      type: 'varchar(255)',
    },
    email_verification_expires: {
      type: 'timestamp with time zone',
    },
    password_reset_token: {
      type: 'varchar(255)',
    },
    password_reset_expires: {
      type: 'timestamp with time zone',
    },
  });

  pgm.createTable('otp_verifications', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    user_id: {
      type: 'uuid',
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    phone: {
      type: 'varchar(20)',
      notNull: true,
    },
    otp_hash: {
      type: 'varchar(255)',
      notNull: true,
    },
    purpose: {
      type: 'varchar(50)',
      notNull: true,
      check: "purpose IN ('phone_verification', 'login', 'password_reset')",
    },
    attempts: {
      type: 'integer',
      default: 0,
      notNull: true,
    },
    expires_at: {
      type: 'timestamp with time zone',
      notNull: true,
    },
    verified_at: {
      type: 'timestamp with time zone',
    },
    created_at: {
      type: 'timestamp with time zone',
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
  });

  pgm.createIndex('otp_verifications', 'phone');
  pgm.createIndex('otp_verifications', 'user_id');
  pgm.createIndex('otp_verifications', 'expires_at');

  pgm.createIndex('users', 'email_verification_token');
  pgm.createIndex('users', 'password_reset_token');
};

exports.down = (pgm) => {
  pgm.dropTable('otp_verifications');
  
  pgm.dropColumns('users', [
    'email_verified',
    'phone_verified',
    'email_verification_token',
    'email_verification_expires',
    'password_reset_token',
    'password_reset_expires',
  ]);
};
