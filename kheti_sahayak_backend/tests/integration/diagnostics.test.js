const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

// Mock db with query function
const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

jest.mock('../../s3', () => ({
  uploadFileToS3: jest.fn(() => Promise.resolve('https://s3.amazonaws.com/test-bucket/test-image.jpg'))
}));
jest.mock('../../services/mlService', () => ({
  analyzeImage: jest.fn(() => Promise.resolve({
    disease: 'Early Blight',
    confidence: 0.85,
    severity: 'moderate',
    symptoms: ['Yellow leaves with brown spots'],
    treatment_steps: ['Apply fungicide', 'Improve air circulation'],
    recommendations: 'Apply fungicide containing chlorothalonil'
  }))
}));

const db = require('../../db');

// Create Express app for testing
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const diagnosticsRoutes = require('../../routes/diagnostics');
app.use('/api/diagnostics', diagnosticsRoutes);

// Error handler
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

describe('Diagnostics API Integration Tests', () => {
  let authToken;
  let expertToken;

  beforeAll(() => {
    // Generate test JWT tokens
    const secret = process.env.JWT_SECRET || 'test-secret';
    authToken = jwt.sign({ id: 1, email: 'farmer@test.com', role: 'farmer' }, secret, { expiresIn: '1h' });
    expertToken = jwt.sign({ id: 2, email: 'expert@test.com', role: 'expert' }, secret, { expiresIn: '1h' });
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/diagnostics/upload', () => {
    it('should upload and analyze image successfully', async () => {
      const mockDiagnostic = {
        id: 1,
        user_id: 1,
        crop_type: 'tomato',
        issue_description: 'yellow leaves with brown spots',
        image_urls: ['https://s3.amazonaws.com/test-bucket/test-image.jpg'],
        diagnosis_result: 'Disease: Early Blight (Confidence: 85.0%)',
        recommendations: 'Apply fungicide containing chlorothalonil',
        confidence_score: 0.85,
        status: 'analyzed',
        created_at: new Date()
      };

      db.query.mockResolvedValue({
        rows: [mockDiagnostic]
      });

      const response = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('crop_type', 'tomato')
        .field('issue_description', 'yellow leaves with brown spots')
        .attach('image', Buffer.from('fake-image-data'), 'test.jpg');

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.diagnostic).toBeDefined();
      expect(response.body.aiAnalysis).toBeDefined();
      expect(response.body.aiAnalysis.disease).toBe('Early Blight');
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .post('/api/diagnostics/upload')
        .field('crop_type', 'tomato')
        .field('issue_description', 'yellow leaves');

      expect(response.status).toBe(401);
    });

    it('should return 400 when no image is provided', async () => {
      const response = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('crop_type', 'tomato')
        .field('issue_description', 'yellow leaves');

      expect(response.status).toBe(400);
    });

    it('should return 400 when crop_type is missing', async () => {
      const response = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('issue_description', 'yellow leaves')
        .attach('image', Buffer.from('fake-image-data'), 'test.jpg');

      expect(response.status).toBe(400);
    });

    it('should return 400 when issue_description is missing', async () => {
      const response = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${authToken}`)
        .field('crop_type', 'tomato')
        .attach('image', Buffer.from('fake-image-data'), 'test.jpg');

      expect(response.status).toBe(400);
    });
  });

  describe('GET /api/diagnostics', () => {
    it('should get diagnostic history with pagination', async () => {
      const mockDiagnostics = [
        {
          id: 1,
          crop_type: 'tomato',
          status: 'analyzed',
          created_at: new Date()
        },
        {
          id: 2,
          crop_type: 'potato',
          status: 'pending',
          created_at: new Date()
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: mockDiagnostics })
        .mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const response = await request(app)
        .get('/api/diagnostics')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.diagnostics).toHaveLength(2);
      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.total_items).toBe(2);
    });

    it('should filter diagnostics by status', async () => {
      const mockDiagnostics = [
        {
          id: 1,
          status: 'analyzed',
          crop_type: 'tomato'
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: mockDiagnostics })
        .mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/diagnostics?status=analyzed')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.diagnostics).toHaveLength(1);
      expect(response.body.diagnostics[0].status).toBe('analyzed');
    });

    it('should filter diagnostics by crop_type', async () => {
      const mockDiagnostics = [
        {
          id: 1,
          crop_type: 'tomato',
          status: 'analyzed'
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: mockDiagnostics })
        .mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/diagnostics?crop_type=tomato')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.diagnostics).toHaveLength(1);
      expect(response.body.diagnostics[0].crop_type).toBe('tomato');
    });

    it('should support pagination parameters', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [{ count: '50' }] });

      const response = await request(app)
        .get('/api/diagnostics?page=2&limit=20')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.pagination.current_page).toBe(2);
      expect(response.body.pagination.items_per_page).toBe(20);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/diagnostics');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/diagnostics/:id', () => {
    it('should get diagnostic by id', async () => {
      const mockDiagnostic = {
        id: 1,
        crop_type: 'tomato',
        issue_description: 'yellow leaves',
        status: 'analyzed',
        user_id: 1
      };

      db.query.mockResolvedValue({
        rows: [mockDiagnostic]
      });

      const response = await request(app)
        .get('/api/diagnostics/1')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.diagnostic).toBeDefined();
      expect(response.body.diagnostic.id).toBe(1);
    });

    it('should return 404 when diagnostic not found', async () => {
      db.query.mockResolvedValue({
        rows: []
      });

      const response = await request(app)
        .get('/api/diagnostics/999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/diagnostics/1');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/diagnostics/:id/treatments', () => {
    it('should get treatment recommendations for diagnostic', async () => {
      const mockDiagnostic = {
        id: 1,
        disease_id: 1,
        crop_type: 'tomato',
        user_id: 1
      };

      const mockTreatments = [
        {
          id: 1,
          disease_id: 1,
          disease_name: 'Early Blight',
          treatment_type: 'chemical',
          treatment_name: 'Copper Fungicide',
          effectiveness_rating: 9,
          symptoms: ['Yellow leaves'],
          prevention: 'Improve air circulation'
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: [mockDiagnostic] })
        .mockResolvedValueOnce({ rows: mockTreatments });

      const response = await request(app)
        .get('/api/diagnostics/1/treatments')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.treatments).toBeDefined();
      expect(response.body.disease).toBeDefined();
      expect(response.body.disease.name).toBe('Early Blight');
    });

    it('should handle diagnostics without disease_id', async () => {
      const mockDiagnostic = {
        id: 1,
        disease_id: null,
        crop_type: 'unknown',
        user_id: 1
      };

      db.query.mockResolvedValue({
        rows: [mockDiagnostic]
      });

      const response = await request(app)
        .get('/api/diagnostics/1/treatments')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.treatments).toEqual([]);
    });

    it('should return 404 when diagnostic not found', async () => {
      db.query.mockResolvedValue({
        rows: []
      });

      const response = await request(app)
        .get('/api/diagnostics/999/treatments')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });
  });

  describe('POST /api/diagnostics/:id/expert-review', () => {
    it('should request expert review successfully', async () => {
      const mockDiagnostic = {
        id: 1,
        crop_type: 'tomato',
        status: 'analyzed',
        expert_review_id: null,
        user_id: 1
      };

      const mockExpert = {
        id: 2,
        username: 'expert1',
        first_name: 'Dr.',
        last_name: 'Expert'
      };

      const mockUpdatedDiagnostic = {
        ...mockDiagnostic,
        expert_review_id: 2,
        status: 'pending'
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockDiagnostic] })
        .mockResolvedValueOnce({ rows: [mockExpert] })
        .mockResolvedValueOnce({ rows: [mockUpdatedDiagnostic] })
        .mockResolvedValueOnce({ rows: [{}] }); // notification

      const response = await request(app)
        .post('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.assigned_expert).toBeDefined();
      expect(response.body.diagnostic.status).toBe('pending');
    });

    it('should return 400 when expert review already requested', async () => {
      const mockDiagnostic = {
        id: 1,
        expert_review_id: 2,
        status: 'pending',
        user_id: 1
      };

      db.query.mockResolvedValue({
        rows: [mockDiagnostic]
      });

      const response = await request(app)
        .post('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
    });

    it('should return 503 when no experts available', async () => {
      const mockDiagnostic = {
        id: 1,
        expert_review_id: null,
        status: 'analyzed',
        user_id: 1
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockDiagnostic] })
        .mockResolvedValueOnce({ rows: [] }); // no experts

      const response = await request(app)
        .post('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(503);
    });

    it('should return 400 for resolved diagnostic', async () => {
      const mockDiagnostic = {
        id: 1,
        status: 'resolved',
        expert_review_id: 2,
        user_id: 1
      };

      db.query.mockResolvedValue({
        rows: [mockDiagnostic]
      });

      const response = await request(app)
        .post('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
    });
  });

  describe('PUT /api/diagnostics/:id/expert-review', () => {
    it('should submit expert review successfully', async () => {
      const mockDiagnostic = {
        id: 1,
        user_id: 1,
        crop_type: 'tomato',
        status: 'pending',
        expert_review_id: 2
      };

      const mockUpdatedDiagnostic = {
        ...mockDiagnostic,
        diagnosis_result: 'Expert Diagnosis: Confirmed Early Blight',
        recommendations: 'Apply copper fungicide every 7 days',
        status: 'resolved'
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockDiagnostic] })
        .mockResolvedValueOnce({ rows: [mockUpdatedDiagnostic] })
        .mockResolvedValueOnce({ rows: [{}] }); // notification

      const response = await request(app)
        .put('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${expertToken}`)
        .send({
          expert_diagnosis: 'Confirmed Early Blight',
          expert_recommendations: 'Apply copper fungicide every 7 days',
          severity_level: 'moderate'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.diagnostic.status).toBe('resolved');
    });

    it('should return 400 when diagnosis is missing', async () => {
      const response = await request(app)
        .put('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${expertToken}`)
        .send({
          expert_recommendations: 'Apply fungicide'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when recommendations are missing', async () => {
      const response = await request(app)
        .put('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${expertToken}`)
        .send({
          expert_diagnosis: 'Early Blight'
        });

      expect(response.status).toBe(400);
    });

    it('should return 404 when diagnostic not assigned to expert', async () => {
      db.query.mockResolvedValue({
        rows: []
      });

      const response = await request(app)
        .put('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${expertToken}`)
        .send({
          expert_diagnosis: 'Early Blight',
          expert_recommendations: 'Apply fungicide'
        });

      expect(response.status).toBe(404);
    });

    it('should return 403 without expert role', async () => {
      const response = await request(app)
        .put('/api/diagnostics/1/expert-review')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          expert_diagnosis: 'Early Blight',
          expert_recommendations: 'Apply fungicide'
        });

      expect(response.status).toBe(403);
    });
  });

  describe('GET /api/diagnostics/recommendations', () => {
    it('should get crop recommendations without filters', async () => {
      const mockRecommendations = [
        {
          id: 1,
          crop_name: 'Wheat',
          season: 'winter',
          soil_type: 'loamy'
        },
        {
          id: 2,
          crop_name: 'Rice',
          season: 'monsoon',
          soil_type: 'clay'
        }
      ];

      db.query.mockResolvedValue({
        rows: mockRecommendations
      });

      const response = await request(app)
        .get('/api/diagnostics/recommendations');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.recommendations).toHaveLength(2);
    });

    it('should filter recommendations by season', async () => {
      const mockRecommendations = [
        {
          id: 1,
          crop_name: 'Wheat',
          season: 'winter',
          soil_type: 'loamy'
        }
      ];

      db.query.mockResolvedValue({
        rows: mockRecommendations
      });

      const response = await request(app)
        .get('/api/diagnostics/recommendations?season=winter');

      expect(response.status).toBe(200);
      expect(response.body.recommendations).toHaveLength(1);
      expect(response.body.recommendations[0].season).toBe('winter');
    });

    it('should filter recommendations by multiple criteria', async () => {
      const mockRecommendations = [
        {
          id: 1,
          crop_name: 'Tomato',
          season: 'summer',
          soil_type: 'loamy',
          water_requirement: 'moderate'
        }
      ];

      db.query.mockResolvedValue({
        rows: mockRecommendations
      });

      const response = await request(app)
        .get('/api/diagnostics/recommendations?season=summer&soil_type=loamy&water_availability=moderate');

      expect(response.status).toBe(200);
      expect(response.body.recommendations).toHaveLength(1);
    });
  });

  describe('GET /api/diagnostics/stats', () => {
    it('should get diagnostic statistics for user', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ count: '15' }] })
        .mockResolvedValueOnce({ rows: [
          { status: 'analyzed', count: '10' },
          { status: 'pending', count: '3' },
          { status: 'resolved', count: '2' }
        ]})
        .mockResolvedValueOnce({ rows: [
          { crop_type: 'tomato', count: '8' },
          { crop_type: 'potato', count: '5' }
        ]})
        .mockResolvedValueOnce({ rows: [
          { crop_type: 'tomato', status: 'analyzed', created_at: new Date() }
        ]});

      const response = await request(app)
        .get('/api/diagnostics/stats')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.stats.total_diagnostics).toBe(15);
      expect(response.body.stats.by_status).toHaveLength(3);
      expect(response.body.stats.by_crop_type).toHaveLength(2);
      expect(response.body.stats.recent_diagnostics).toBeDefined();
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/diagnostics/stats');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/diagnostics/expert/assigned', () => {
    it('should get diagnostics assigned to expert', async () => {
      const mockDiagnostics = [
        {
          id: 1,
          crop_type: 'tomato',
          status: 'pending',
          expert_review_id: 2,
          username: 'farmer1'
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: mockDiagnostics })
        .mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/diagnostics/expert/assigned')
        .set('Authorization', `Bearer ${expertToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.diagnostics).toHaveLength(1);
      expect(response.body.diagnostics[0].expert_review_id).toBe(2);
    });

    it('should filter assigned diagnostics by status', async () => {
      const mockDiagnostics = [
        {
          id: 1,
          status: 'pending',
          expert_review_id: 2
        }
      ];

      db.query
        .mockResolvedValueOnce({ rows: mockDiagnostics })
        .mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/diagnostics/expert/assigned?status=pending')
        .set('Authorization', `Bearer ${expertToken}`);

      expect(response.status).toBe(200);
      expect(response.body.diagnostics).toHaveLength(1);
      expect(response.body.diagnostics[0].status).toBe('pending');
    });

    it('should return 403 without expert role', async () => {
      const response = await request(app)
        .get('/api/diagnostics/expert/assigned')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
    });
  });
});
