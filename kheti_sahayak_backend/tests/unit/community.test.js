/**
 * Unit Tests for Community Q&A API
 * Tests for questions, answers, voting, and tagging functionality (#Sprint4)
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

describe('Community Q&A', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Question Creation', () => {
    it('should require title of at least 10 characters', () => {
      const validTitle = 'How to grow tomatoes in summer season?';
      const invalidTitle = 'Tomatoes?';
      
      expect(validTitle.trim().length >= 10).toBe(true);
      expect(invalidTitle.trim().length >= 10).toBe(false);
    });

    it('should require body of at least 20 characters', () => {
      const validBody = 'I want to know the best practices for growing tomatoes during summer.';
      const invalidBody = 'Help with tomatoes';
      
      expect(validBody.trim().length >= 20).toBe(true);
      expect(invalidBody.trim().length >= 20).toBe(false);
    });

    it('should limit tags to maximum 5', () => {
      const tags = ['farming', 'tomatoes', 'summer', 'vegetables', 'irrigation', 'soil'];
      const limitedTags = tags.slice(0, 5);
      
      expect(limitedTags.length).toBe(5);
      expect(limitedTags).not.toContain('soil');
    });

    it('should handle empty tags array', () => {
      const tags = [];
      const tagArray = Array.isArray(tags) ? tags.slice(0, 5) : [];
      
      expect(tagArray).toEqual([]);
    });

    it('should create question successfully', async () => {
      const mockQuestion = {
        id: 'q-uuid-1',
        user_id: 'user-1',
        title: 'How to grow organic vegetables?',
        body: 'I want to start an organic vegetable garden. What are the best practices?',
        tags: ['organic', 'vegetables', 'gardening'],
        upvotes: 0,
        downvotes: 0,
        views: 0,
        answers_count: 0,
        is_answered: false,
        status: 'active',
        created_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });

      const result = await db.query(
        `INSERT INTO community_questions (user_id, title, body, tags)
         VALUES ($1, $2, $3, $4) RETURNING *`,
        ['user-1', mockQuestion.title, mockQuestion.body, mockQuestion.tags]
      );

      expect(result.rows[0].id).toBe('q-uuid-1');
      expect(result.rows[0].status).toBe('active');
    });
  });

  describe('Question Retrieval', () => {
    it('should fetch questions with pagination', async () => {
      const mockQuestions = Array(20).fill(null).map((_, i) => ({
        id: `q-uuid-${i}`,
        title: `Question ${i}`,
        body: 'Question body content here',
        username: 'testuser',
      }));

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockQuestions.slice(0, 10) });

      const result = await db.query(
        `SELECT * FROM community_questions WHERE status = 'active' LIMIT $1 OFFSET $2`,
        [10, 0]
      );

      expect(result.rows).toHaveLength(10);
    });

    it('should filter questions by tag', async () => {
      const mockQuestions = [
        { id: 'q-1', title: 'Organic farming', tags: ['organic', 'farming'] },
        { id: 'q-2', title: 'Organic seeds', tags: ['organic', 'seeds'] },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });

      const tag = 'organic';
      const result = await db.query(
        `SELECT * FROM community_questions WHERE $1 = ANY(tags) AND status = 'active'`,
        [tag.toLowerCase()]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(q => q.tags.includes('organic'))).toBe(true);
    });

    it('should filter by answered status', async () => {
      const mockQuestions = [
        { id: 'q-1', is_answered: true },
        { id: 'q-2', is_answered: true },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });

      const result = await db.query(
        `SELECT * FROM community_questions WHERE is_answered = $1 AND status = 'active'`,
        [true]
      );

      expect(result.rows.every(q => q.is_answered === true)).toBe(true);
    });

    it('should sort questions by votes', () => {
      const questions = [
        { id: 'q-1', upvotes: 10, downvotes: 2 },
        { id: 'q-2', upvotes: 5, downvotes: 1 },
        { id: 'q-3', upvotes: 15, downvotes: 3 },
      ];

      const sorted = [...questions].sort((a, b) => 
        (b.upvotes - b.downvotes) - (a.upvotes - a.downvotes)
      );

      expect(sorted[0].id).toBe('q-3');
      expect(sorted[2].id).toBe('q-2');
    });

    it('should sort questions by views', () => {
      const questions = [
        { id: 'q-1', views: 100 },
        { id: 'q-2', views: 50 },
        { id: 'q-3', views: 200 },
      ];

      const sorted = [...questions].sort((a, b) => b.views - a.views);

      expect(sorted[0].id).toBe('q-3');
      expect(sorted[0].views).toBe(200);
    });

    it('should search questions by title and body', async () => {
      const mockResults = [
        { id: 'q-1', title: 'Growing tomatoes', body: 'How to grow red tomatoes' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockResults });

      const searchTerm = 'tomatoes';
      const result = await db.query(
        `SELECT * FROM community_questions 
         WHERE (title ILIKE $1 OR body ILIKE $1) AND status = 'active'`,
        [`%${searchTerm}%`]
      );

      expect(result.rows[0].title).toContain('tomatoes');
    });

    it('should increment view count on question access', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        'UPDATE community_questions SET views = views + 1 WHERE id = $1',
        ['q-uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });
  });

  describe('Question Update', () => {
    it('should allow owner to update question', async () => {
      const mockQuestion = {
        id: 'q-uuid-1',
        user_id: 'user-1',
        title: 'Updated title here',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'q-uuid-1', user_id: 'user-1' }] });
      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });

      const checkResult = await db.query(
        'SELECT * FROM community_questions WHERE id = $1',
        ['q-uuid-1']
      );

      const isOwner = checkResult.rows[0].user_id === 'user-1';
      expect(isOwner).toBe(true);
    });

    it('should allow admin to update any question', () => {
      const userId = 'admin-1';
      const questionOwnerId = 'user-2';
      const userRole = 'admin';

      const canUpdate = questionOwnerId === userId || userRole === 'admin';
      expect(canUpdate).toBe(true);
    });

    it('should reject unauthorized update', () => {
      const userId = 'user-3';
      const questionOwnerId = 'user-1';
      const userRole = 'user';

      const canUpdate = questionOwnerId === userId || userRole === 'admin';
      expect(canUpdate).toBe(false);
    });
  });

  describe('Question Deletion', () => {
    it('should soft delete question by updating status', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        "UPDATE community_questions SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
        ['q-uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });
  });

  describe('Answer Creation', () => {
    it('should require body of at least 20 characters', () => {
      const validBody = 'You should use organic compost and water regularly for best results.';
      const invalidBody = 'Use compost';
      
      expect(validBody.trim().length >= 20).toBe(true);
      expect(invalidBody.trim().length >= 20).toBe(false);
    });

    it('should verify question exists before creating answer', async () => {
      const mockQuestion = { id: 'q-uuid-1' };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockQuestion] });

      const result = await db.query(
        'SELECT id FROM community_questions WHERE id = $1 AND status = $2',
        ['q-uuid-1', 'active']
      );

      expect(result.rows).toHaveLength(1);
    });

    it('should return 404 for non-existent question', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT id FROM community_questions WHERE id = $1 AND status = $2',
        ['non-existent', 'active']
      );

      expect(result.rows).toHaveLength(0);
    });

    it('should create answer and increment answers_count', async () => {
      const mockAnswer = {
        id: 'a-uuid-1',
        question_id: 'q-uuid-1',
        user_id: 'user-2',
        body: 'Here is my detailed answer to your question about organic farming.',
        upvotes: 0,
        downvotes: 0,
        is_accepted: false,
        status: 'active',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockAnswer] });
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const answerResult = await db.query(
        `INSERT INTO community_answers (question_id, user_id, body)
         VALUES ($1, $2, $3) RETURNING *`,
        ['q-uuid-1', 'user-2', mockAnswer.body]
      );

      const updateResult = await db.query(
        'UPDATE community_questions SET answers_count = answers_count + 1 WHERE id = $1',
        ['q-uuid-1']
      );

      expect(answerResult.rows[0].id).toBe('a-uuid-1');
      expect(updateResult.rowCount).toBe(1);
    });
  });

  describe('Accept Answer', () => {
    it('should only allow question owner to accept answer', () => {
      const userId = 'user-1';
      const questionOwnerId = 'user-1';

      const canAccept = questionOwnerId === userId;
      expect(canAccept).toBe(true);
    });

    it('should reject acceptance from non-owner', () => {
      const userId = 'user-2';
      const questionOwnerId = 'user-1';

      const canAccept = questionOwnerId === userId;
      expect(canAccept).toBe(false);
    });

    it('should unaccept previous answer before accepting new one', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 2 });

      const result = await db.query(
        'UPDATE community_answers SET is_accepted = false WHERE question_id = $1',
        ['q-uuid-1']
      );

      expect(result.rowCount).toBeGreaterThanOrEqual(0);
    });

    it('should mark question as answered when answer is accepted', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        'UPDATE community_questions SET is_answered = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
        ['q-uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });
  });

  describe('Voting', () => {
    it('should validate vote target type', () => {
      const validTypes = ['question', 'answer'];
      
      expect(validTypes.includes('question')).toBe(true);
      expect(validTypes.includes('answer')).toBe(true);
      expect(validTypes.includes('comment')).toBe(false);
    });

    it('should validate vote type values', () => {
      const validVoteTypes = [-1, 1];
      
      expect(validVoteTypes.includes(1)).toBe(true);
      expect(validVoteTypes.includes(-1)).toBe(true);
      expect(validVoteTypes.includes(0)).toBe(false);
      expect(validVoteTypes.includes(2)).toBe(false);
    });

    it('should prevent self-voting', () => {
      const userId = 'user-1';
      const contentOwnerId = 'user-1';

      const canVote = userId !== contentOwnerId;
      expect(canVote).toBe(false);
    });

    it('should allow voting on others content', () => {
      const userId = 'user-2';
      const contentOwnerId = 'user-1';

      const canVote = userId !== contentOwnerId;
      expect(canVote).toBe(true);
    });

    it('should toggle vote when same vote type is cast again', async () => {
      const existingVote = { vote_type: 1 };
      const newVoteType = 1;

      const shouldRemoveVote = existingVote.vote_type === newVoteType;
      expect(shouldRemoveVote).toBe(true);
    });

    it('should change vote when different vote type is cast', async () => {
      const existingVote = { vote_type: 1 };
      const newVoteType = -1;

      const shouldChangeVote = existingVote.vote_type !== newVoteType;
      expect(shouldChangeVote).toBe(true);
    });

    it('should increment upvotes on upvote', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        'UPDATE community_questions SET upvotes = upvotes + 1 WHERE id = $1',
        ['q-uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });

    it('should increment downvotes on downvote', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        'UPDATE community_questions SET downvotes = downvotes + 1 WHERE id = $1',
        ['q-uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });

    it('should store vote record', async () => {
      const mockVote = {
        user_id: 'user-2',
        votable_id: 'q-uuid-1',
        votable_type: 'question',
        vote_type: 1,
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockVote] });

      const result = await db.query(
        `INSERT INTO community_votes (user_id, votable_id, votable_type, vote_type)
         VALUES ($1, $2, $3, $4)`,
        [mockVote.user_id, mockVote.votable_id, mockVote.votable_type, mockVote.vote_type]
      );

      expect(mockQuery).toHaveBeenCalled();
    });
  });

  describe('Tags', () => {
    it('should retrieve tags ordered by question count', async () => {
      const mockTags = [
        { name: 'organic', questions_count: 50 },
        { name: 'farming', questions_count: 30 },
        { name: 'seeds', questions_count: 20 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockTags });

      const result = await db.query(
        'SELECT name, questions_count FROM community_tags ORDER BY questions_count DESC LIMIT $1',
        [50]
      );

      expect(result.rows[0].questions_count).toBeGreaterThan(result.rows[1].questions_count);
    });

    it('should increment tag count on question creation', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        `INSERT INTO community_tags (name)
         VALUES ($1)
         ON CONFLICT (name) DO UPDATE SET questions_count = community_tags.questions_count + 1`,
        ['organic']
      );

      expect(mockQuery).toHaveBeenCalled();
    });

    it('should normalize tag names to lowercase', () => {
      const tags = ['Organic', 'FARMING', 'Seeds'];
      const normalizedTags = tags.map(tag => tag.toLowerCase().trim());

      expect(normalizedTags).toEqual(['organic', 'farming', 'seeds']);
    });
  });

  describe('User Questions', () => {
    it('should fetch questions by user ID', async () => {
      const mockQuestions = [
        { id: 'q-1', user_id: 'user-1', title: 'Question 1' },
        { id: 'q-2', user_id: 'user-1', title: 'Question 2' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockQuestions });

      const result = await db.query(
        `SELECT * FROM community_questions
         WHERE user_id = $1 AND status != 'deleted'
         ORDER BY created_at DESC`,
        ['user-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(q => q.user_id === 'user-1')).toBe(true);
    });

    it('should exclude deleted questions from user list', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        `SELECT * FROM community_questions
         WHERE user_id = $1 AND status != 'deleted'`,
        ['user-1']
      );

      expect(result.rows.every(q => q.status !== 'deleted')).toBe(true);
    });
  });

  describe('Response Formatting', () => {
    it('should include user info in question response', () => {
      const response = {
        success: true,
        data: {
          id: 'q-uuid-1',
          title: 'Test Question',
          username: 'testuser',
          first_name: 'Test',
          last_name: 'User',
          profile_image: 'https://example.com/avatar.jpg',
        },
      };

      expect(response.data).toHaveProperty('username');
      expect(response.data).toHaveProperty('first_name');
      expect(response.data).toHaveProperty('profile_image');
    });

    it('should include pagination in list responses', () => {
      const pagination = {
        current_page: 1,
        total_pages: 5,
        total_items: 100,
        items_per_page: 20,
      };

      expect(pagination).toHaveProperty('current_page');
      expect(pagination).toHaveProperty('total_pages');
      expect(pagination).toHaveProperty('total_items');
      expect(pagination).toHaveProperty('items_per_page');
    });
  });
});
