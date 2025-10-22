# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kheti Sahayak is an agricultural assistance platform backend built with Node.js/Express and PostgreSQL. It provides APIs for crop diagnostics, marketplace, educational content, weather forecasting, reviews/ratings, shopping cart, and expert consultation.

## Development Commands

### Starting the Application

```bash
# Development mode with hot reload
npm run dev

# Production mode
npm start
```

The server runs on `http://localhost:3000` by default. API documentation is available at `http://localhost:3000/api-docs` (Swagger UI).

### Database Operations

```bash
# Initialize database (create tables)
npm run db:init

# Run pending migrations
npm run migrate:up

# Rollback last migration
npm run migrate:down

# Create new migration
npm run migrate:create <migration-name>

# Seed database with test data
npm run db:seed

# Verify migration status
npm run db:verify
```

**Important**: Migrations use node-pg-migrate. When creating migrations, follow the naming convention `<timestamp>_<description>.js` and use the migration API (pgm object) not raw SQL.

### Testing

```bash
# Run all tests
npm test

# Run tests in watch mode (not configured, use with --watch flag manually)
npm test -- --watch

# Run specific test file
npm test -- tests/unit/auth.test.js
```

Tests use Jest with pg-mem (in-memory PostgreSQL). Test files are organized under `tests/` with subdirectories: `unit/`, `integration/`, `e2e/`. The `tests/old_tests/` directory is ignored.

## Architecture

### Request Flow

1. **Request** → Express middleware (CORS, JSON parsing, logging)
2. **Route** (`routes/*.js`) → Swagger-documented endpoints
3. **Middleware** (`middleware/authMiddleware.js`) → JWT authentication via `protect` middleware
4. **Controller** (`controllers/*Controller.js`) → Business logic wrapped in `asyncHandler`
5. **Database** (`db.js`) → PostgreSQL queries via `db.query()`
6. **Response** → Standardized JSON format
7. **Error Handler** (`middleware/errorMiddleware.js`) → Centralized error responses

### Database Layer

- **Connection**: PostgreSQL connection pool configured in `db.js`
- **Schema**: Managed via node-pg-migrate in `migrations/` directory
- **Tables**: users, products, orders, diagnostics, educational_content, cart_items, product_reviews, treatments, etc.
- **Seed Data**: Use `seedData.js` for test users/content

The database uses UUIDs for primary keys (via `uuid_generate_v4()`), timestamp fields with triggers for auto-updates, and foreign key constraints with CASCADE deletes where appropriate.

### Authentication & Authorization

Authentication is JWT-based (see `middleware/authMiddleware.js`):

- `protect` middleware: Validates JWT token from `Authorization: Bearer <token>` header
- `authorize(...roles)` middleware: Role-based access control for 'admin', 'expert', 'content_creator', 'farmer'
- Token payload includes: `{ id: user.id, role: user.role }`

All protected routes must use `protect` middleware. For role-specific routes, chain with `authorize('admin', 'expert')`.

### Redis Caching

Redis is used for caching weather data and session management (see `redisClient.js`). The application includes a **MockRedisClient** that automatically activates when Redis is unavailable, allowing development without Redis running.

### ML Service Integration

The ML service for crop disease detection is a separate FastAPI service (in `ml_service/`). The backend sends disease detection requests to `http://localhost:8000/predict` with form-data containing crop images. Mock responses are used when ML service is unavailable.

### Error Handling

All controllers use `express-async-handler` to avoid try-catch blocks. Errors are handled by centralized middleware in `middleware/errorMiddleware.js`:

- `notFound`: Handles 404 errors for undefined routes
- `errorHandler`: Formats all errors consistently with `{ success: false, error, type, stack }`

Custom error responses:
```javascript
res.status(400);
throw new Error('Your error message'); // Will be caught by errorHandler
```

### Swagger Documentation

API documentation is auto-generated from JSDoc comments in route files (`routes/*.js`). Each endpoint has Swagger annotations following OpenAPI 3.0 spec. View docs at `/api-docs`.

Example pattern:
```javascript
/**
 * @swagger
 * /api/resource:
 *   get:
 *     summary: Description
 *     tags: [Tag]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Success response
 */
```

## Key Implementation Patterns

### Controllers

All controllers export async functions wrapped with `asyncHandler`:

```javascript
const asyncHandler = require('express-async-handler');

const getResource = asyncHandler(async (req, res) => {
  const userId = req.user.id; // Available after protect middleware
  const result = await db.query('SELECT * FROM table WHERE user_id = $1', [userId]);
  res.json({ success: true, data: result.rows });
});
```

### Database Queries

Always use parameterized queries to prevent SQL injection:

```javascript
// ✓ Correct
await db.query('SELECT * FROM users WHERE email = $1', [email]);

// ✗ Wrong
await db.query(`SELECT * FROM users WHERE email = '${email}'`);
```

For complex queries with joins, use clear formatting and include column aliases to avoid conflicts.

### Migration Files

Migrations must export `up` and `down` functions:

```javascript
exports.up = (pgm) => {
  pgm.createTable('table_name', {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('uuid_generate_v4()') },
    // ... columns
    created_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') },
    updated_at: { type: 'timestamp with time zone', notNull: true, default: pgm.func('CURRENT_TIMESTAMP') }
  });

  // Add indexes
  pgm.createIndex('table_name', 'column_name');

  // Add trigger for updated_at
  pgm.sql(`
    CREATE TRIGGER update_table_name_updated_at
    BEFORE UPDATE ON table_name
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('table_name');
};
```

## Environment Configuration

Required environment variables (see `env.example`):

- **Database**: `DB_USER`, `DB_HOST`, `DB_NAME`, `DB_PASSWORD`, `DB_PORT`
- **JWT**: `JWT_SECRET`, `JWT_EXPIRE`
- **Server**: `PORT`, `NODE_ENV`
- **Optional**: `REDIS_HOST`, `REDIS_PORT`, `AWS_REGION`, `AWS_S3_BUCKET_NAME`, `ML_SERVICE_URL`, `WEATHER_API_KEY`

Missing Redis/AWS/ML configurations will fall back to mock implementations for development.

## Test User Credentials

After running `npm run db:seed`, the following test users are available:

- Admin: `admin@khetisahayak.com` / `admin123`
- Expert: `expert@khetisahayak.com` / `expert123`
- Content Creator: `creator@khetisahayak.com` / `creator123`
- Farmer: `farmer@khetisahayak.com` / `user123`

## Common Debugging Steps

1. **Server won't start**: Check if PostgreSQL is running and database exists
2. **Authentication errors**: Verify JWT_SECRET is set and token is valid (not expired)
3. **Database errors**: Run `npm run db:verify` to check migration status
4. **Redis errors**: Redis is optional, mock client will activate automatically
5. **ML service errors**: ML service is optional, mock responses will be used

## API Endpoints

Main endpoint groups (all prefixed with `/api`):

- `/auth` - Registration, login, password reset
- `/marketplace` - Products, categories, sellers
- `/cart` - Shopping cart operations
- `/orders` - Order placement and tracking
- `/reviews` - Product reviews and ratings
- `/diagnostics` - Crop disease detection
- `/educational-content` - Farming guides and videos
- `/weather` - Weather forecasts and agricultural advisories
- `/notifications` - User notifications
- `/health` - Health check endpoint

See `/api-docs` for complete API reference with request/response examples.
