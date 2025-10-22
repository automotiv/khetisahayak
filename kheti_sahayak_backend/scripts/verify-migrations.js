/**
 * Database Migration Verification Script
 *
 * This script verifies that all database migrations have been applied correctly
 * and that the database schema matches expectations.
 */

const db = require('../db');
const fs = require('fs');
const path = require('path');

// ANSI color codes for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m'
};

/**
 * Expected tables in the database
 */
const expectedTables = [
  'users',
  'diagnostics',
  'marketplace_products',
  'notifications',
  'educational_content',
  'crop_diseases',
  'treatment_recommendations',
  'crop_recommendations',
  'pgmigrations' // node-pg-migrate tracking table
];

/**
 * Expected columns for critical tables
 */
const expectedColumns = {
  users: ['id', 'username', 'email', 'password', 'role', 'first_name', 'last_name', 'created_at'],
  diagnostics: ['id', 'user_id', 'crop_type', 'image_urls', 'diagnosis_result', 'status', 'disease_id'],
  crop_diseases: ['id', 'disease_name', 'crop_type', 'description', 'symptoms', 'prevention'],
  treatment_recommendations: ['id', 'disease_id', 'treatment_type', 'treatment_name', 'effectiveness_rating']
};

/**
 * Print formatted message
 */
function printMessage(message, color = 'reset', symbol = '') {
  console.log(`${colors[color]}${symbol} ${message}${colors.reset}`);
}

/**
 * Print section header
 */
function printHeader(message) {
  console.log(`\n${colors.bright}${colors.blue}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.bright}${colors.blue}${message}${colors.reset}`);
  console.log(`${colors.bright}${colors.blue}${'='.repeat(60)}${colors.reset}\n`);
}

/**
 * Check if all expected tables exist
 */
async function verifyTables() {
  printHeader('Verifying Database Tables');

  const query = `
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `;

  try {
    const result = await db.query(query);
    const existingTables = result.rows.map(row => row.table_name);

    printMessage(`Found ${existingTables.length} tables in database`, 'blue', '\u2139');

    const missingTables = expectedTables.filter(table => !existingTables.includes(table));
    const extraTables = existingTables.filter(table => !expectedTables.includes(table));

    if (missingTables.length === 0) {
      printMessage('All expected tables exist', 'green', '\u2713');
    } else {
      printMessage(`Missing tables: ${missingTables.join(', ')}`, 'red', '\u2717');
    }

    if (extraTables.length > 0) {
      printMessage(`Extra tables found: ${extraTables.join(', ')}`, 'yellow', '\u26A0');
    }

    return { existingTables, missingTables, extraTables };
  } catch (error) {
    printMessage(`Error verifying tables: ${error.message}`, 'red', '\u2717');
    throw error;
  }
}

/**
 * Check if all expected columns exist in critical tables
 */
async function verifyColumns() {
  printHeader('Verifying Table Columns');

  const results = {
    passed: [],
    failed: []
  };

  for (const [tableName, expectedCols] of Object.entries(expectedColumns)) {
    const query = `
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = $1
      ORDER BY ordinal_position
    `;

    try {
      const result = await db.query(query, [tableName]);
      const existingColumns = result.rows.map(row => row.column_name);

      const missingColumns = expectedCols.filter(col => !existingColumns.includes(col));

      if (missingColumns.length === 0) {
        printMessage(`Table '${tableName}': All expected columns exist`, 'green', '\u2713');
        results.passed.push(tableName);
      } else {
        printMessage(`Table '${tableName}': Missing columns: ${missingColumns.join(', ')}`, 'red', '\u2717');
        results.failed.push({ table: tableName, missingColumns });
      }
    } catch (error) {
      printMessage(`Error checking table '${tableName}': ${error.message}`, 'red', '\u2717');
      results.failed.push({ table: tableName, error: error.message });
    }
  }

  return results;
}

/**
 * Check migration history
 */
async function verifyMigrations() {
  printHeader('Verifying Migration History');

  try {
    const query = `
      SELECT id, name, run_on
      FROM pgmigrations
      ORDER BY run_on DESC
    `;

    const result = await db.query(query);

    if (result.rows.length === 0) {
      printMessage('No migrations have been run yet', 'yellow', '\u26A0');
      return { count: 0, migrations: [] };
    }

    printMessage(`Total migrations applied: ${result.rows.length}`, 'blue', '\u2139');

    result.rows.forEach((migration, index) => {
      const date = new Date(migration.run_on).toLocaleString();
      console.log(`  ${index + 1}. ${migration.name} (${date})`);
    });

    // Check for pending migrations
    const migrationsDir = path.join(__dirname, '../migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.js'))
      .map(file => file.replace('.js', ''));

    const appliedMigrations = result.rows.map(row => row.name);
    const pendingMigrations = migrationFiles.filter(file => !appliedMigrations.includes(file));

    if (pendingMigrations.length > 0) {
      printMessage(`\nPending migrations: ${pendingMigrations.length}`, 'yellow', '\u26A0');
      pendingMigrations.forEach(migration => {
        console.log(`  - ${migration}`);
      });
      printMessage('\nRun "npm run migrate:up" to apply pending migrations', 'yellow', '\u2139');
    } else {
      printMessage('\nAll migrations are up to date', 'green', '\u2713');
    }

    return { count: result.rows.length, migrations: result.rows, pending: pendingMigrations };
  } catch (error) {
    if (error.code === '42P01') {
      // Table doesn't exist
      printMessage('Migration tracking table does not exist', 'red', '\u2717');
      printMessage('Run "npm run migrate:up" to initialize migrations', 'yellow', '\u2139');
      return { count: 0, migrations: [], error: 'Table not found' };
    }
    printMessage(`Error verifying migrations: ${error.message}`, 'red', '\u2717');
    throw error;
  }
}

/**
 * Verify foreign key constraints
 */
async function verifyConstraints() {
  printHeader('Verifying Foreign Key Constraints');

  const query = `
    SELECT
      tc.table_name,
      kcu.column_name,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    ORDER BY tc.table_name
  `;

  try {
    const result = await db.query(query);

    if (result.rows.length === 0) {
      printMessage('No foreign key constraints found', 'yellow', '\u26A0');
    } else {
      printMessage(`Found ${result.rows.length} foreign key constraints`, 'green', '\u2713');

      const grouped = {};
      result.rows.forEach(row => {
        if (!grouped[row.table_name]) {
          grouped[row.table_name] = [];
        }
        grouped[row.table_name].push({
          column: row.column_name,
          references: `${row.foreign_table_name}.${row.foreign_column_name}`
        });
      });

      Object.entries(grouped).forEach(([table, constraints]) => {
        console.log(`\n  ${table}:`);
        constraints.forEach(c => {
          console.log(`    - ${c.column} → ${c.references}`);
        });
      });
    }

    return result.rows;
  } catch (error) {
    printMessage(`Error verifying constraints: ${error.message}`, 'red', '\u2717');
    throw error;
  }
}

/**
 * Verify database connection
 */
async function verifyConnection() {
  printHeader('Verifying Database Connection');

  try {
    const result = await db.query('SELECT version()');
    const version = result.rows[0].version;
    printMessage(`Connected to PostgreSQL`, 'green', '\u2713');
    printMessage(`Version: ${version}`, 'blue', '\u2139');
    return true;
  } catch (error) {
    printMessage(`Connection failed: ${error.message}`, 'red', '\u2717');
    throw error;
  }
}

/**
 * Main verification function
 */
async function runVerification() {
  console.log('\n');
  printMessage('DATABASE MIGRATION VERIFICATION', 'bright');
  console.log('\n');

  try {
    // Verify connection
    await verifyConnection();

    // Verify migrations
    const migrationResults = await verifyMigrations();

    // Verify tables
    const tableResults = await verifyTables();

    // Verify columns
    const columnResults = await verifyColumns();

    // Verify constraints
    const constraintResults = await verifyConstraints();

    // Summary
    printHeader('Verification Summary');

    const totalChecks = expectedTables.length + Object.keys(expectedColumns).length;
    const passedChecks = tableResults.existingTables.filter(t => expectedTables.includes(t)).length +
                         columnResults.passed.length;

    const allPassed = tableResults.missingTables.length === 0 && columnResults.failed.length === 0;

    if (allPassed) {
      printMessage(`All checks passed (${passedChecks}/${totalChecks})`, 'green', '\u2713');
      printMessage('Database schema is properly configured', 'green', '\u2713');
    } else {
      printMessage(`Some checks failed (${passedChecks}/${totalChecks} passed)`, 'yellow', '\u26A0');
      if (tableResults.missingTables.length > 0) {
        printMessage(`Missing ${tableResults.missingTables.length} tables`, 'red', '\u2717');
      }
      if (columnResults.failed.length > 0) {
        printMessage(`${columnResults.failed.length} tables have missing columns`, 'red', '\u2717');
      }
    }

    console.log('\n');
    process.exit(allPassed ? 0 : 1);
  } catch (error) {
    printMessage(`\nVerification failed with error: ${error.message}`, 'red', '\u2717');
    console.error(error);
    process.exit(1);
  } finally {
    // Close database connection
    await db.query('SELECT 1'); // Keep connection alive for pool cleanup
  }
}

// Run verification
runVerification();
