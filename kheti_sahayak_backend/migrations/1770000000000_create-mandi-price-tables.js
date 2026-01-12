/**
 * Migration: Create Mandi Price Tables
 * 
 * Tables for government mandi prices, MSP data, and price alerts
 */

exports.up = (pgm) => {
  // MSP (Minimum Support Price) table - stores official government MSP for crops
  pgm.createTable('msp_prices', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    crop_name: { type: 'varchar(100)', notNull: true },
    crop_name_hi: { type: 'varchar(100)' }, // Hindi name
    variety: { type: 'varchar(100)', default: 'Common' },
    season: { type: 'varchar(50)' }, // Kharif, Rabi, etc.
    year: { type: 'integer', notNull: true },
    msp_price: { type: 'decimal(10,2)', notNull: true }, // per quintal
    unit: { type: 'varchar(20)', default: 'quintal' },
    effective_date: { type: 'date' },
    source: { type: 'varchar(200)', default: 'Ministry of Agriculture' },
    created_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') },
    updated_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  pgm.createIndex('msp_prices', 'crop_name');
  pgm.createIndex('msp_prices', 'year');
  pgm.createIndex('msp_prices', ['crop_name', 'year', 'variety'], { unique: true });

  // Mandi price history - caches fetched prices from government APIs
  pgm.createTable('mandi_price_history', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    state: { type: 'varchar(100)', notNull: true },
    district: { type: 'varchar(100)', notNull: true },
    market: { type: 'varchar(200)', notNull: true },
    commodity: { type: 'varchar(100)', notNull: true },
    variety: { type: 'varchar(100)', default: 'Other' },
    grade: { type: 'varchar(50)' },
    min_price: { type: 'decimal(10,2)' }, // per quintal
    max_price: { type: 'decimal(10,2)' },
    modal_price: { type: 'decimal(10,2)' }, // Most common traded price
    arrival_date: { type: 'date', notNull: true },
    arrival_quantity: { type: 'decimal(10,2)' }, // in tonnes
    source: { type: 'varchar(100)', default: 'Agmarknet' },
    source_url: { type: 'text' },
    created_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  pgm.createIndex('mandi_price_history', 'commodity');
  pgm.createIndex('mandi_price_history', 'state');
  pgm.createIndex('mandi_price_history', 'arrival_date');
  pgm.createIndex('mandi_price_history', ['state', 'market', 'commodity', 'arrival_date']);

  // Price alert subscriptions
  pgm.createTable('price_alert_subscriptions', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    user_id: { 
      type: 'uuid', 
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE'
    },
    commodity: { type: 'varchar(100)', notNull: true },
    state: { type: 'varchar(100)' },
    district: { type: 'varchar(100)' },
    market: { type: 'varchar(200)' },
    alert_type: { type: 'varchar(20)', notNull: true, default: 'threshold' }, // threshold, percentage_change, msp_comparison
    threshold_price: { type: 'decimal(10,2)' }, // Alert when price crosses this
    threshold_direction: { type: 'varchar(10)', default: 'above' }, // above, below, both
    percentage_change: { type: 'decimal(5,2)' }, // Alert on X% change
    compare_to_msp: { type: 'boolean', default: false }, // Alert when below/above MSP
    msp_threshold_percent: { type: 'decimal(5,2)', default: 100 }, // e.g., alert when below 90% of MSP
    notification_channels: { type: 'jsonb', default: '["push", "in_app"]' },
    is_active: { type: 'boolean', default: true },
    last_triggered_at: { type: 'timestamp with time zone' },
    trigger_count: { type: 'integer', default: 0 },
    created_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') },
    updated_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  pgm.createIndex('price_alert_subscriptions', 'user_id');
  pgm.createIndex('price_alert_subscriptions', 'commodity');
  pgm.createIndex('price_alert_subscriptions', 'is_active');

  // Price alert history - log of triggered alerts
  pgm.createTable('price_alert_history', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    subscription_id: { 
      type: 'uuid', 
      notNull: true,
      references: 'price_alert_subscriptions(id)',
      onDelete: 'CASCADE'
    },
    user_id: { 
      type: 'uuid', 
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE'
    },
    commodity: { type: 'varchar(100)', notNull: true },
    alert_type: { type: 'varchar(50)', notNull: true },
    message: { type: 'text', notNull: true },
    message_hi: { type: 'text' },
    current_price: { type: 'decimal(10,2)' },
    threshold_price: { type: 'decimal(10,2)' },
    msp_price: { type: 'decimal(10,2)' },
    price_change_percent: { type: 'decimal(5,2)' },
    market: { type: 'varchar(200)' },
    state: { type: 'varchar(100)' },
    is_read: { type: 'boolean', default: false },
    is_dismissed: { type: 'boolean', default: false },
    triggered_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  pgm.createIndex('price_alert_history', 'user_id');
  pgm.createIndex('price_alert_history', 'subscription_id');
  pgm.createIndex('price_alert_history', 'triggered_at');

  // State and market master data
  pgm.createTable('mandi_markets', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    state: { type: 'varchar(100)', notNull: true },
    state_code: { type: 'varchar(10)' },
    district: { type: 'varchar(100)', notNull: true },
    market_name: { type: 'varchar(200)', notNull: true },
    market_type: { type: 'varchar(50)', default: 'APMC' }, // APMC, Private, Cooperative
    latitude: { type: 'decimal(10,7)' },
    longitude: { type: 'decimal(10,7)' },
    is_active: { type: 'boolean', default: true },
    created_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  pgm.createIndex('mandi_markets', 'state');
  pgm.createIndex('mandi_markets', ['state', 'district']);
  pgm.createIndex('mandi_markets', ['state', 'district', 'market_name'], { unique: true });

  // Add updated_at triggers
  pgm.sql(`
    CREATE TRIGGER update_msp_prices_updated_at
    BEFORE UPDATE ON msp_prices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_price_alert_subscriptions_updated_at
    BEFORE UPDATE ON price_alert_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('price_alert_history');
  pgm.dropTable('price_alert_subscriptions');
  pgm.dropTable('mandi_price_history');
  pgm.dropTable('mandi_markets');
  pgm.dropTable('msp_prices');
};
