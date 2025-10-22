/**
 * Migration: Add Reviews and Ratings for Marketplace Products
 *
 * This migration creates a product_reviews table that allows users to:
 * - Rate products (1-5 stars)
 * - Write text reviews
 * - Optionally upload images
 * - Track verified purchases
 * - Mark reviews as helpful
 *
 * @type {import('node-pg-migrate').ColumnDefinitions | undefined}
 */
exports.shorthands = undefined;

/**
 * @param pgm {import('node-pg-migrate').MigrationBuilder}
 * @param run {() => void | undefined}
 * @returns {Promise<void> | void}
 */
exports.up = (pgm) => {
  // Create product_reviews table
  pgm.createTable('product_reviews', {
    id: { type: 'serial', primaryKey: true },
    product_id: {
      type: 'integer',
      notNull: true,
      references: 'marketplace_products',
      onDelete: 'CASCADE',
    },
    user_id: {
      type: 'integer',
      notNull: true,
      references: 'users',
      onDelete: 'CASCADE',
    },
    rating: {
      type: 'integer',
      notNull: true,
      check: 'rating >= 1 AND rating <= 5',
    },
    title: {
      type: 'varchar(200)',
      notNull: false,
    },
    review_text: {
      type: 'text',
      notNull: false,
    },
    images: {
      type: 'text[]',
      notNull: false,
      default: pgm.func('ARRAY[]::text[]'),
    },
    verified_purchase: {
      type: 'boolean',
      notNull: true,
      default: false,
    },
    helpful_count: {
      type: 'integer',
      notNull: true,
      default: 0,
    },
    status: {
      type: 'varchar(20)',
      notNull: true,
      default: 'active',
      check: "status IN ('active', 'hidden', 'flagged', 'deleted')",
    },
    created_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
    updated_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
  });

  // Create review_helpful table to track which users found reviews helpful
  pgm.createTable('review_helpful', {
    id: { type: 'serial', primaryKey: true },
    review_id: {
      type: 'integer',
      notNull: true,
      references: 'product_reviews',
      onDelete: 'CASCADE',
    },
    user_id: {
      type: 'integer',
      notNull: true,
      references: 'users',
      onDelete: 'CASCADE',
    },
    created_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP'),
    },
  });

  // Add indexes for better query performance
  pgm.createIndex('product_reviews', 'product_id');
  pgm.createIndex('product_reviews', 'user_id');
  pgm.createIndex('product_reviews', 'rating');
  pgm.createIndex('product_reviews', 'created_at');
  pgm.createIndex('product_reviews', 'status');

  pgm.createIndex('review_helpful', 'review_id');
  pgm.createIndex('review_helpful', 'user_id');

  // Add unique constraint to prevent duplicate reviews from same user for same product
  pgm.addConstraint('product_reviews', 'unique_user_product_review', {
    unique: ['user_id', 'product_id'],
  });

  // Add unique constraint to prevent duplicate helpful marks
  pgm.addConstraint('review_helpful', 'unique_user_review_helpful', {
    unique: ['user_id', 'review_id'],
  });

  // Add trigger to update updated_at timestamp
  pgm.sql(`
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ language 'plpgsql';

    CREATE TRIGGER update_product_reviews_updated_at
    BEFORE UPDATE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
};

/**
 * @param pgm {import('node-pg-migrate').MigrationBuilder}
 * @param run {() => void | undefined}
 * @returns {Promise<void> | void}
 */
exports.down = (pgm) => {
  // Drop trigger and function
  pgm.sql(`
    DROP TRIGGER IF EXISTS update_product_reviews_updated_at ON product_reviews;
    DROP FUNCTION IF EXISTS update_updated_at_column();
  `);

  // Drop tables (will cascade to constraints and indexes)
  pgm.dropTable('review_helpful', { cascade: true });
  pgm.dropTable('product_reviews', { cascade: true });
};
