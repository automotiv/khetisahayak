/**
 * Migration: Create Payments and Refunds tables for Razorpay integration
 */

exports.up = (pgm) => {
  // Create payments table
  pgm.createTable('payments', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    order_id: {
      type: 'uuid',
      notNull: true,
      references: '"orders"',
      onDelete: 'CASCADE'
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    razorpay_order_id: {
      type: 'varchar(100)',
      unique: true
    },
    razorpay_payment_id: {
      type: 'varchar(100)',
      unique: true
    },
    razorpay_signature: {
      type: 'text'
    },
    amount: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    currency: {
      type: 'varchar(3)',
      notNull: true,
      default: 'INR'
    },
    status: {
      type: 'varchar(30)',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'created', 'authorized', 'captured', 'failed', 'refunded', 'partially_refunded')"
    },
    payment_method: {
      type: 'varchar(50)'
    },
    error_message: {
      type: 'text'
    },
    paid_at: {
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

  // Create indexes for payments
  pgm.createIndex('payments', 'order_id');
  pgm.createIndex('payments', 'user_id');
  pgm.createIndex('payments', 'razorpay_order_id');
  pgm.createIndex('payments', 'razorpay_payment_id');
  pgm.createIndex('payments', 'status');

  // Add trigger for updated_at
  pgm.sql(`
    CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  // Create refunds table
  pgm.createTable('refunds', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    payment_id: {
      type: 'uuid',
      notNull: true,
      references: '"payments"',
      onDelete: 'CASCADE'
    },
    razorpay_refund_id: {
      type: 'varchar(100)',
      unique: true
    },
    amount: {
      type: 'decimal(10, 2)',
      notNull: true
    },
    status: {
      type: 'varchar(30)',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'processed', 'failed')"
    },
    reason: {
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

  // Create indexes for refunds
  pgm.createIndex('refunds', 'payment_id');
  pgm.createIndex('refunds', 'razorpay_refund_id');

  // Add trigger for updated_at
  pgm.sql(`
    CREATE TRIGGER update_refunds_updated_at
    BEFORE UPDATE ON refunds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  // Add payment_status column to orders table if not exists
  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders' AND column_name = 'payment_status'
      ) THEN
        ALTER TABLE orders ADD COLUMN payment_status varchar(30) DEFAULT 'pending';
      END IF;
    END $$;
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('refunds');
  pgm.dropTable('payments');
  pgm.sql(`ALTER TABLE orders DROP COLUMN IF EXISTS payment_status`);
};
