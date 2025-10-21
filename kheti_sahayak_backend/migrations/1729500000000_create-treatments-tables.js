/**
 * Migration: Create crop diseases and treatment recommendations tables
 *
 * This migration creates tables for storing crop disease information
 * and treatment recommendations for MVP
 */

exports.up = async (pgm) => {
  // Create crop_diseases table
  pgm.createTable('crop_diseases', {
    id: { type: 'serial', primaryKey: true },
    disease_name: { type: 'varchar(255)', notNull: true },
    scientific_name: { type: 'varchar(255)' },
    crop_type: { type: 'varchar(100)', notNull: true },
    description: { type: 'text' },
    symptoms: { type: 'text' },
    causes: { type: 'text' },
    prevention: { type: 'text' },
    severity: { type: 'varchar(50)' }, // low, moderate, high, severe
    ai_model_class: { type: 'varchar(255)' }, // Maps to ML model output class
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  // Create index on disease_name and crop_type for faster lookups
  pgm.createIndex('crop_diseases', 'disease_name');
  pgm.createIndex('crop_diseases', 'crop_type');
  pgm.createIndex('crop_diseases', 'ai_model_class');

  // Create treatment_recommendations table
  pgm.createTable('treatment_recommendations', {
    id: { type: 'serial', primaryKey: true },
    disease_id: {
      type: 'integer',
      notNull: true,
      references: '"crop_diseases"',
      onDelete: 'CASCADE'
    },
    treatment_type: {
      type: 'varchar(50)',
      notNull: true,
      comment: 'organic, chemical, cultural, biological'
    },
    treatment_name: { type: 'varchar(255)', notNull: true },
    active_ingredient: { type: 'varchar(255)' },
    dosage: { type: 'varchar(255)' },
    application_method: { type: 'text' },
    timing: { type: 'varchar(255)' },
    frequency: { type: 'varchar(100)' },
    precautions: { type: 'text' },
    effectiveness_rating: {
      type: 'integer',
      check: 'effectiveness_rating >= 1 AND effectiveness_rating <= 5',
      comment: '1-5 star rating'
    },
    cost_estimate: { type: 'varchar(100)' },
    availability: {
      type: 'varchar(50)',
      comment: 'easily_available, locally_available, requires_order'
    },
    notes: { type: 'text' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  // Create index on disease_id for faster joins
  pgm.createIndex('treatment_recommendations', 'disease_id');
  pgm.createIndex('treatment_recommendations', 'treatment_type');

  // Update diagnostics table to add AI-specific columns
  pgm.addColumns('diagnostics', {
    disease_detected: { type: 'varchar(255)' },
    ai_confidence: { type: 'decimal(5,2)' },
    severity: { type: 'varchar(50)' },
    ai_model_version: { type: 'varchar(50)' },
    disease_id: {
      type: 'integer',
      references: '"crop_diseases"',
      onDelete: 'SET NULL'
    }
  });

  pgm.createIndex('diagnostics', 'disease_id');
  pgm.createIndex('diagnostics', 'severity');
};

exports.down = async (pgm) => {
  // Drop indexes
  pgm.dropIndex('diagnostics', 'severity');
  pgm.dropIndex('diagnostics', 'disease_id');

  // Drop columns from diagnostics
  pgm.dropColumns('diagnostics', ['disease_detected', 'ai_confidence', 'severity', 'ai_model_version', 'disease_id']);

  // Drop treatment_recommendations table
  pgm.dropTable('treatment_recommendations');

  // Drop crop_diseases table
  pgm.dropTable('crop_diseases');
};
