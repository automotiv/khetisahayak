const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Kheti Sahayak API',
      version: '1.0.0',
      description: 'API documentation for Kheti Sahayak - Agricultural Assistance Platform',
      contact: {
        name: 'Kheti Sahayak Team',
        email: 'support@khetisahayak.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string' },
            email: { type: 'string', format: 'email' },
            phone: { type: 'string' },
            user_type: { type: 'string', enum: ['farmer', 'expert', 'admin'] },
            location: { type: 'string' },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        Product: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string' },
            description: { type: 'string' },
            price: { type: 'number' },
            category: { type: 'string' },
            seller_id: { type: 'integer' },
            image_url: { type: 'string' },
            stock_quantity: { type: 'integer' },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        Order: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            user_id: { type: 'integer' },
            product_id: { type: 'integer' },
            quantity: { type: 'integer' },
            total_amount: { type: 'number' },
            status: { type: 'string', enum: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'] },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        CropDiagnostic: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            user_id: { type: 'integer' },
            crop_name: { type: 'string' },
            symptoms: { type: 'string' },
            image_url: { type: 'string' },
            ai_prediction: { type: 'string' },
            expert_review: { type: 'string' },
            status: { type: 'string', enum: ['pending', 'ai_analyzed', 'expert_reviewed'] },
            created_at: { type: 'string', format: 'date-time' }
          }
        }
      }
    }
  },
  apis: ['./routes/*.js', './controllers/*.js']
};

const specs = swaggerJsdoc(options);

module.exports = specs; 