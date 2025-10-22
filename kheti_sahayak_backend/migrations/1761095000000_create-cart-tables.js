/**
 * Migration: Create Shopping Cart Tables
 *
 * Creates tables for shopping cart functionality:
 * - cart_items: Stores items added to user's cart
 */

exports.up = async (pgm) => {
  // Create cart_items table
  pgm.createTable('cart_items', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()'),
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: 'users(id)',
      onDelete: 'CASCADE',
    },
    product_id: {
      type: 'uuid',
      notNull: true,
      references: 'products(id)',
      onDelete: 'CASCADE',
    },
    quantity: {
      type: 'integer',
      notNull: true,
      default: 1,
      check: 'quantity > 0',
    },
    unit_price: {
      type: 'numeric(10, 2)',
      notNull: true,
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
  });

  // Create unique constraint to prevent duplicate items in cart
  pgm.addConstraint('cart_items', 'unique_user_product', {
    unique: ['user_id', 'product_id'],
  });

  // Create indexes for better query performance
  pgm.createIndex('cart_items', 'user_id');
  pgm.createIndex('cart_items', 'product_id');
  pgm.createIndex('cart_items', ['user_id', 'created_at']);

  // Create trigger to update updated_at timestamp
  pgm.sql(`
    CREATE OR REPLACE FUNCTION update_cart_items_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);

  pgm.createTrigger('cart_items', 'update_cart_items_updated_at_trigger', {
    when: 'BEFORE',
    operation: 'UPDATE',
    function: 'update_cart_items_updated_at',
    level: 'ROW',
  });
};

exports.down = (pgm) => {
  pgm.dropTrigger('cart_items', 'update_cart_items_updated_at_trigger', {
    ifExists: true,
  });
  pgm.dropFunction('update_cart_items_updated_at', { ifExists: true });
  pgm.dropTable('cart_items', { ifExists: true, cascade: true });
};
