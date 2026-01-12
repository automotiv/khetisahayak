exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.createTable('expert_date_overrides', {
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
    date: {
      type: 'date',
      notNull: true,
    },
    is_available: {
      type: 'boolean',
      notNull: true,
      default: false,
    },
    reason: {
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

  pgm.createIndex('expert_date_overrides', 'expert_id');
  pgm.createIndex('expert_date_overrides', ['expert_id', 'date'], { unique: true });
  pgm.createIndex('expert_date_overrides', 'date');
};

exports.down = (pgm) => {
  pgm.dropTable('expert_date_overrides', { ifExists: true, cascade: true });
};
