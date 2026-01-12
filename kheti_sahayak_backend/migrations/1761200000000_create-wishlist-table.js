/**
 * Migration: Create Wishlist Table
 *
 * Creates table for wishlist functionality:
 * - wishlists: Stores products saved to user's wishlist
 */

exports.up = async (pgm) => {
  // Create wishlists table
  pgm.createTable('wishlists', {
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
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
  });

  // Create unique constraint to prevent duplicate wishlist entries
  pgm.addConstraint('wishlists', 'unique_user_product_wishlist', {
    unique: ['user_id', 'product_id'],
  });

  // Create indexes for better query performance
  pgm.createIndex('wishlists', 'user_id');
  pgm.createIndex('wishlists', 'product_id');
  pgm.createIndex('wishlists', ['user_id', 'created_at']);
};

exports.down = (pgm) => {
  pgm.dropTable('wishlists', { ifExists: true, cascade: true });
};
