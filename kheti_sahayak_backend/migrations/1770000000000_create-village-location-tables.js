exports.shorthands = undefined;

exports.up = pgm => {
  pgm.createTable('user_village_preferences', {
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
    village_name: {
      type: 'varchar(200)',
      notNull: true
    },
    district: {
      type: 'varchar(100)'
    },
    state: {
      type: 'varchar(100)'
    },
    state_code: {
      type: 'varchar(5)'
    },
    latitude: {
      type: 'decimal(10,7)',
      notNull: true
    },
    longitude: {
      type: 'decimal(10,7)',
      notNull: true
    },
    display_name: {
      type: 'text'
    },
    is_primary: {
      type: 'boolean',
      default: false
    },
    agro_climatic_zone: {
      type: 'varchar(100)'
    },
    source: {
      type: 'varchar(50)',
      default: 'nominatim'
    },
    created_at: {
      type: 'timestamp with time zone',
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  pgm.createIndex('user_village_preferences', ['user_id', 'is_primary']);
  pgm.createIndex('user_village_preferences', ['latitude', 'longitude']);
  pgm.createIndex('user_village_preferences', ['state_code']);
  pgm.createIndex('user_village_preferences', ['user_id', 'latitude', 'longitude'], {
    unique: true,
    name: 'unique_user_village_location'
  });

  pgm.sql(`
    CREATE TRIGGER update_user_village_preferences_updated_at
    BEFORE UPDATE ON user_village_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.createTable('village_weather_cache', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    latitude: {
      type: 'decimal(10,7)',
      notNull: true
    },
    longitude: {
      type: 'decimal(10,7)',
      notNull: true
    },
    village_name: {
      type: 'varchar(200)'
    },
    district: {
      type: 'varchar(100)'
    },
    state_code: {
      type: 'varchar(5)'
    },
    weather_data: {
      type: 'jsonb',
      notNull: true
    },
    forecast_data: {
      type: 'jsonb'
    },
    agricultural_advisory: {
      type: 'jsonb'
    },
    fetched_at: {
      type: 'timestamp with time zone',
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    expires_at: {
      type: 'timestamp with time zone',
      notNull: true
    }
  });

  pgm.createIndex('village_weather_cache', ['latitude', 'longitude'], {
    unique: true,
    name: 'unique_village_weather_location'
  });
  pgm.createIndex('village_weather_cache', ['expires_at']);
  pgm.createIndex('village_weather_cache', ['state_code']);
};

exports.down = pgm => {
  pgm.dropTable('village_weather_cache');
  pgm.dropTable('user_village_preferences');
};
