/**
 * Integration Tests for Community Q&A API
 * Tests end-to-end question, answer, and voting flows (#Sprint4)
 */

const request = require('supertest');

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

const express = require('express');
const communityRoutes = require('../../routes/community');

const app = express();
app.use(express.json());

const mockProtect = (req, res, next) => {
  req.user = { id: 'test-user-id', role: 'user' };
  next();
};

const mockOptionalAuth = (req, res, next) => {
  if (req.headers.authorization) {
    req.user = { id: 'test-user-id', role: 'user' };
  }
  next();
};

app.use('/api/community', communityRoutes);

describe('Community Q&A Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Question Flow', () => {
    it('should create question with valid data', async () => {
      const mockQuestion = {
        id: 'q-uuid-1',
        user_id: 'test-user-id',
        title: 'How to grow organic vegetables in summer?',
        body: 'I want to start organic vegetable farming during summer season. What are the best practices and crop recommendations?',
        tags: ['organic', 'vegetables', 'summer'],
        upvotes: 0,
        downvotes: 0,
        views: 0,
        answers_count: 0,
        is_answered: false,
        status: 'active',
        created_at: new Date(),
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });
      mockQuery.mockResolvedValue({ rowCount: 1 });

      const response = await request(app)
        .post('/api/community/questions')
        .set('Authorization', 'Bearer test-token')
        .send({
          title: 'How to grow organic vegetables in summer?',
          body: 'I want to start organic vegetable farming during summer season. What are the best practices and crop recommendations?',
          tags: ['organic', 'vegetables', 'summer'],
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe('How to grow organic vegetables in summer?');
    });

    it('should list questions with pagination', async () => {
      const mockQuestions = Array(10).fill(null).map((_, i) => ({
        id: `q-uuid-${i}`,
        title: `Question ${i}`,
        body: 'Question body content here',
        username: 'testuser',
        upvotes: i,
        downvotes: 0,
        views: i * 10,
        status: 'active',
      }));

      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '50' }] });

      const response = await request(app)
        .get('/api/community/questions')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination).toBeDefined();
    });

    it('should filter questions by tag', async () => {
      const mockQuestions = [
        { id: 'q-1', title: 'Organic farming', tags: ['organic'] },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/community/questions')
        .query({ tag: 'organic' });

      expect(response.status).toBe(200);
    });

    it('should get single question with answers', async () => {
      const mockQuestion = {
        id: 'q-uuid-1',
        title: 'Test Question',
        body: 'Test body content',
        username: 'testuser',
        upvotes: 5,
        downvotes: 1,
        views: 100,
      };

      const mockAnswers = [
        { id: 'a-1', body: 'Answer 1', is_accepted: true },
        { id: 'a-2', body: 'Answer 2', is_accepted: false },
      ];

      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });
      mockQuery.mockResolvedValueOnce({ rows: mockAnswers });

      const response = await request(app)
        .get('/api/community/questions/q-uuid-1');

      expect(response.status).toBe(200);
      expect(response.body.data.answers).toBeDefined();
    });

    it('should return 404 for non-existent question', async () => {
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/community/questions/non-existent');

      expect(response.status).toBe(404);
    });
  });

  describe('Answer Flow', () => {
    it('should create answer for existing question', async () => {
      const mockQuestion = { id: 'q-uuid-1' };
      const mockAnswer = {
        id: 'a-uuid-1',
        question_id: 'q-uuid-1',
        user_id: 'test-user-id',
        body: 'Here is my detailed answer to help you with organic vegetable farming.',
        upvotes: 0,
        downvotes: 0,
        is_accepted: false,
        status: 'active',
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });
      mockQuery.mockResolvedValueOnce({ rows: [mockAnswer] });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/community/questions/q-uuid-1/answers')
        .set('Authorization', 'Bearer test-token')
        .send({
          body: 'Here is my detailed answer to help you with organic vegetable farming.',
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
    });

    it('should reject answer for non-existent question', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/community/questions/non-existent/answers')
        .set('Authorization', 'Bearer test-token')
        .send({
          body: 'This is my answer to the question about farming.',
        });

      expect(response.status).toBe(404);
    });

    it('should accept answer by question owner', async () => {
      const mockAnswer = {
        id: 'a-uuid-1',
        question_id: 'q-uuid-1',
        question_owner_id: 'test-user-id',
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockAnswer] });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/community/answers/a-uuid-1/accept')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('Voting Flow', () => {
    it('should upvote question', async () => {
      const mockQuestion = { id: 'q-uuid-1', user_id: 'other-user' };

      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });
      mockQuery.mockResolvedValueOnce({ rows: [] });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/community/vote/q-uuid-1')
        .set('Authorization', 'Bearer test-token')
        .send({ type: 'question', voteType: 1 });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should prevent self-voting', async () => {
      const mockQuestion = { id: 'q-uuid-1', user_id: 'test-user-id' };

      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });

      const response = await request(app)
        .post('/api/community/vote/q-uuid-1')
        .set('Authorization', 'Bearer test-token')
        .send({ type: 'question', voteType: 1 });

      expect(response.status).toBe(400);
    });

    it('should toggle vote when voting again with same type', async () => {
      const mockQuestion = { id: 'q-uuid-1', user_id: 'other-user' };
      const existingVote = { vote_type: 1 };

      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });
      mockQuery.mockResolvedValueOnce({ rows: [existingVote] });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/community/vote/q-uuid-1')
        .set('Authorization', 'Bearer test-token')
        .send({ type: 'question', voteType: 1 });

      expect(response.status).toBe(200);
      expect(response.body.vote).toBeNull();
    });
  });

  describe('Tags', () => {
    it('should get popular tags', async () => {
      const mockTags = [
        { name: 'organic', questions_count: 50 },
        { name: 'farming', questions_count: 30 },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockTags });

      const response = await request(app)
        .get('/api/community/tags');

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(2);
    });
  });

  describe('User Questions', () => {
    it('should get questions by current user', async () => {
      const mockQuestions = [
        { id: 'q-1', user_id: 'test-user-id', title: 'My Question 1' },
        { id: 'q-2', user_id: 'test-user-id', title: 'My Question 2' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const response = await request(app)
        .get('/api/community/my-questions')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(2);
    });
  });
});
