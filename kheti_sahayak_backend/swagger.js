const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Kheti Sahayak API',
      version: '1.0.0',
      description: `
# Kheti Sahayak - Agricultural Assistance Platform

A comprehensive agricultural assistance platform providing:
- 🌾 Crop Health Diagnostics with AI-powered disease detection
- 🛒 Agricultural Marketplace for buying/selling farm products
- 📚 Educational content for farmers
- 🌦️ Weather forecasting and agricultural advisories
- 👨‍🌾 Expert consultation services
- 📱 Multi-language support (Hindi, Marathi, English)

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:
\`\`\`
Authorization: Bearer <your-jwt-token>
\`\`\`

## Rate Limiting

API requests are rate-limited to ensure fair usage:
- Public endpoints: 100 requests per 15 minutes
- Authenticated endpoints: 1000 requests per 15 minutes

## Error Responses

All error responses follow this format:
\`\`\`json
{
  "success": false,
  "error": "Error message",
  "type": "ErrorType",
  "details": []
}
\`\`\`
      `,
      contact: {
        name: 'Kheti Sahayak Team',
        email: 'support@khetisahayak.com',
        url: 'https://khetisahayak.com'
      },
      license: {
        name: 'ISC',
        url: 'https://opensource.org/licenses/ISC'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      },
      {
        url: 'https://api.khetisahayak.com',
        description: 'Production server'
      }
    ],
    tags: [
      {
        name: 'Authentication',
        description: 'User authentication and profile management'
      },
      {
        name: 'Diagnostics',
        description: 'Crop health diagnostics and AI analysis'
      },
      {
        name: 'Marketplace',
        description: 'Agricultural marketplace operations'
      },
      {
        name: 'Weather',
        description: 'Weather information and forecasts'
      },
      {
        name: 'Educational Content',
        description: 'Educational resources for farmers'
      },
      {
        name: 'Notifications',
        description: 'User notifications and alerts'
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
            id: { type: 'integer', example: 1 },
            username: { type: 'string', example: 'farmer123' },
            email: { type: 'string', format: 'email', example: 'farmer@example.com' },
            first_name: { type: 'string', example: 'Rajesh' },
            last_name: { type: 'string', example: 'Kumar' },
            phone: { type: 'string', example: '+919876543210' },
            role: { type: 'string', enum: ['farmer', 'expert', 'admin'], example: 'farmer' },
            profile_image: { type: 'string', example: 'https://s3.amazonaws.com/profiles/user.jpg' },
            location_lat: { type: 'number', example: 28.6139 },
            location_lng: { type: 'number', example: 77.2090 },
            address: { type: 'string', example: '123 Farm Road, Village Name' },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        Product: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            name: { type: 'string', example: 'Organic Tomato Seeds' },
            description: { type: 'string', example: 'High-quality organic tomato seeds' },
            price: { type: 'number', format: 'decimal', example: 150.00 },
            category: { type: 'string', example: 'seeds' },
            seller_id: { type: 'integer', example: 1 },
            image_urls: { type: 'array', items: { type: 'string' } },
            quantity: { type: 'integer', example: 100 },
            unit: { type: 'string', example: 'packet' },
            status: { type: 'string', enum: ['active', 'sold', 'inactive'], example: 'active' },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        CropDiagnostic: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            user_id: { type: 'integer', example: 1 },
            crop_type: { type: 'string', example: 'tomato' },
            issue_description: { type: 'string', example: 'Yellow leaves with brown spots' },
            image_urls: { type: 'array', items: { type: 'string' } },
            diagnosis_result: { type: 'string', example: 'Disease: Early Blight (Confidence: 85%)' },
            recommendations: { type: 'string', example: 'Apply fungicide containing chlorothalonil' },
            confidence_score: { type: 'number', format: 'decimal', example: 0.85 },
            status: { type: 'string', enum: ['pending', 'analyzed', 'expert_review', 'resolved'], example: 'analyzed' },
            disease_id: { type: 'integer', nullable: true, example: 1 },
            expert_review_id: { type: 'integer', nullable: true, example: null },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' }
          }
        },
        CropDisease: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            disease_name: { type: 'string', example: 'Early Blight' },
            scientific_name: { type: 'string', example: 'Alternaria solani' },
            crop_type: { type: 'string', example: 'tomato' },
            description: { type: 'string', example: 'Fungal disease affecting tomato plants' },
            symptoms: { type: 'string', example: 'Yellow leaves, brown spots, target-like lesions' },
            prevention: { type: 'string', example: 'Improve air circulation, avoid overhead watering' },
            severity: { type: 'string', enum: ['low', 'moderate', 'high', 'severe'], example: 'moderate' }
          }
        },
        TreatmentRecommendation: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            disease_id: { type: 'integer', example: 1 },
            treatment_type: { type: 'string', enum: ['organic', 'chemical', 'cultural', 'biological'], example: 'chemical' },
            treatment_name: { type: 'string', example: 'Copper Fungicide' },
            active_ingredient: { type: 'string', example: 'Copper sulfate' },
            dosage: { type: 'string', example: '2g per liter' },
            application_method: { type: 'string', example: 'Foliar spray' },
            timing: { type: 'string', example: 'Early morning or evening' },
            effectiveness_rating: { type: 'integer', minimum: 1, maximum: 5, example: 4 },
            cost_estimate: { type: 'string', example: '₹200-300 per application' }
          }
        },
        Weather: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            location: {
              type: 'object',
              properties: {
                name: { type: 'string', example: 'Mumbai' },
                country: { type: 'string', example: 'IN' },
                lat: { type: 'number', example: 19.0760 },
                lon: { type: 'number', example: 72.8777 }
              }
            },
            current: {
              type: 'object',
              properties: {
                temp: { type: 'number', example: 28.5 },
                feels_like: { type: 'number', example: 30.2 },
                humidity: { type: 'integer', example: 75 },
                weather: { type: 'string', example: 'Clouds' },
                description: { type: 'string', example: 'broken clouds' },
                wind_speed: { type: 'number', example: 5.5 }
              }
            }
          }
        },
        Notification: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            user_id: { type: 'integer', example: 1 },
            title: { type: 'string', example: 'New Diagnostic Review' },
            message: { type: 'string', example: 'Your crop diagnostic has been reviewed by an expert' },
            type: { type: 'string', enum: ['info', 'success', 'warning', 'error'], example: 'success' },
            related_entity_type: { type: 'string', example: 'diagnostic' },
            related_entity_id: { type: 'integer', example: 1 },
            read_status: { type: 'boolean', example: false },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        EducationalContent: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            title: { type: 'string', example: 'Best Practices for Tomato Farming' },
            content: { type: 'string', example: 'Comprehensive guide to tomato cultivation...' },
            content_type: { type: 'string', enum: ['article', 'video', 'tutorial'], example: 'article' },
            category: { type: 'string', example: 'crop_management' },
            language: { type: 'string', example: 'en' },
            author: { type: 'string', example: 'Dr. Agricultural Expert' },
            image_url: { type: 'string', example: 'https://s3.amazonaws.com/content/image.jpg' },
            views: { type: 'integer', example: 1250 },
            created_at: { type: 'string', format: 'date-time' }
          }
        },
        Error: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            error: { type: 'string', example: 'Resource not found' },
            type: { type: 'string', example: 'NotFoundError' },
            details: { type: 'array', items: { type: 'object' } }
          }
        },
        Success: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Operation completed successfully' }
          }
        }
      },
      responses: {
        UnauthorizedError: {
          description: 'Authentication required or invalid token',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' },
              example: {
                success: false,
                error: 'Invalid token. Please log in again.',
                type: 'AuthenticationError'
              }
            }
          }
        },
        ForbiddenError: {
          description: 'Access denied - insufficient permissions',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' },
              example: {
                success: false,
                error: 'Access denied',
                type: 'AuthorizationError'
              }
            }
          }
        },
        NotFoundError: {
          description: 'Resource not found',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' },
              example: {
                success: false,
                error: 'Resource not found',
                type: 'NotFoundError'
              }
            }
          }
        },
        ValidationError: {
          description: 'Validation failed',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' },
              example: {
                success: false,
                error: 'Validation failed',
                type: 'ValidationError',
                details: [
                  { field: 'email', message: 'Invalid email format' }
                ]
              }
            }
          }
        }
      }
    }
  },
  apis: ['./routes/*.js', './controllers/*.js']
};

const specs = swaggerJsdoc(options);

module.exports = specs; 