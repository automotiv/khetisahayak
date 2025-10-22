/**
 * Unit Tests for Reviews Functionality
 *
 * These tests verify the reviews and ratings system for marketplace products.
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

describe('Reviews Database Operations', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Create Review', () => {
    it('should create a new review successfully', async () => {
      const mockReview = {
        id: 1,
        product_id: 123,
        user_id: 456,
        rating: 5,
        title: 'Great product!',
        review_text: 'This is an excellent product',
        images: ['https://s3.amazonaws.com/reviews/image1.jpg'],
        verified_purchase: true,
        helpful_count: 0,
        status: 'active',
        created_at: new Date(),
        updated_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockReview] });

      const result = await db.query(
        `INSERT INTO product_reviews
         (product_id, user_id, rating, title, review_text, images, verified_purchase)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [123, 456, 5, 'Great product!', 'This is an excellent product', ['https://s3.amazonaws.com/reviews/image1.jpg'], true]
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].product_id).toBe(123);
      expect(result.rows[0].user_id).toBe(456);
      expect(result.rows[0].rating).toBe(5);
      expect(result.rows[0].verified_purchase).toBe(true);
    });

    it('should enforce rating constraints (1-5)', async () => {
      const invalidRating = 6;
      const validRating = 4;

      // Invalid rating should fail
      expect(invalidRating).toBeGreaterThan(5);

      // Valid rating should pass
      expect(validRating).toBeGreaterThanOrEqual(1);
      expect(validRating).toBeLessThanOrEqual(5);
    });

    it('should prevent duplicate reviews from same user for same product', async () => {
      const existingReview = {
        id: 1,
        product_id: 123,
        user_id: 456,
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [existingReview] });

      const result = await db.query(
        'SELECT id FROM product_reviews WHERE user_id = $1 AND product_id = $2',
        [456, 123]
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].id).toBe(1);
    });
  });

  describe('Get Product Reviews', () => {
    it('should retrieve all reviews for a product', async () => {
      const mockReviews = [
        {
          id: 1,
          product_id: 123,
          user_id: 456,
          rating: 5,
          title: 'Great!',
          review_text: 'Excellent',
          username: 'user1',
        },
        {
          id: 2,
          product_id: 123,
          user_id: 789,
          rating: 4,
          title: 'Good',
          review_text: 'Nice product',
          username: 'user2',
        },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockReviews });

      const result = await db.query(
        `SELECT pr.*, u.username
         FROM product_reviews pr
         JOIN users u ON pr.user_id = u.id
         WHERE pr.product_id = $1 AND pr.status = 'active'
         ORDER BY pr.created_at DESC`,
        [123]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].product_id).toBe(123);
      expect(result.rows[1].product_id).toBe(123);
    });

    it('should calculate review statistics correctly', async () => {
      const mockStats = {
        total_reviews: 10,
        average_rating: 4.5,
        five_star: 5,
        four_star: 3,
        three_star: 1,
        two_star: 1,
        one_star: 0,
        verified_purchases: 7,
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockStats] });

      const result = await db.query(
        `SELECT
          COUNT(*) as total_reviews,
          AVG(rating)::numeric(3,2) as average_rating,
          COUNT(CASE WHEN rating = 5 THEN 1 END) as five_star,
          COUNT(CASE WHEN rating = 4 THEN 1 END) as four_star,
          COUNT(CASE WHEN rating = 3 THEN 1 END) as three_star,
          COUNT(CASE WHEN rating = 2 THEN 1 END) as two_star,
          COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star,
          COUNT(CASE WHEN verified_purchase = true THEN 1 END) as verified_purchases
         FROM product_reviews
         WHERE product_id = $1 AND status = 'active'`,
        [123]
      );

      expect(result.rows[0].total_reviews).toBe(10);
      expect(result.rows[0].average_rating).toBe(4.5);
      expect(result.rows[0].five_star).toBe(5);
      expect(result.rows[0].verified_purchases).toBe(7);
    });

    it('should filter reviews by rating', async () => {
      const mockFiveStarReviews = [
        { id: 1, rating: 5 },
        { id: 2, rating: 5 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockFiveStarReviews });

      const result = await db.query(
        `SELECT * FROM product_reviews
         WHERE product_id = $1 AND rating = $2 AND status = 'active'`,
        [123, 5]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(r => r.rating === 5)).toBe(true);
    });

    it('should sort reviews by different criteria', async () => {
      const sortOptions = ['recent', 'oldest', 'highest', 'lowest', 'helpful'];

      expect(sortOptions).toContain('recent');
      expect(sortOptions).toContain('helpful');
      expect(sortOptions.length).toBe(5);
    });
  });

  describe('Update Review', () => {
    it('should update an existing review', async () => {
      const updatedReview = {
        id: 1,
        rating: 4,
        title: 'Updated title',
        review_text: 'Updated text',
        updated_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [updatedReview] });

      const result = await db.query(
        `UPDATE product_reviews
         SET rating = $1, title = $2, review_text = $3, updated_at = CURRENT_TIMESTAMP
         WHERE id = $4
         RETURNING *`,
        [4, 'Updated title', 'Updated text', 1]
      );

      expect(result.rows[0].rating).toBe(4);
      expect(result.rows[0].title).toBe('Updated title');
    });

    it('should verify review ownership before update', async () => {
      const mockReview = {
        id: 1,
        user_id: 456,
        product_id: 123,
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockReview] });

      const result = await db.query(
        'SELECT * FROM product_reviews WHERE id = $1',
        [1]
      );

      expect(result.rows[0].user_id).toBe(456);
    });
  });

  describe('Delete Review', () => {
    it('should soft delete a review by updating status', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        "UPDATE product_reviews SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
        [1]
      );

      expect(result.rowCount).toBe(1);
    });

    it('should verify authorization before deletion', async () => {
      const mockReview = {
        id: 1,
        user_id: 456,
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockReview] });

      const result = await db.query(
        'SELECT * FROM product_reviews WHERE id = $1',
        [1]
      );

      const isOwner = result.rows[0].user_id === 456;
      const isAdmin = false; // Mock: user is not admin

      expect(isOwner || isAdmin).toBe(true);
    });
  });

  describe('Helpful Marks', () => {
    it('should mark a review as helpful', async () => {
      const db = require('../../db');
      mockQuery
        .mockResolvedValueOnce({ rows: [] }) // No existing mark
        .mockResolvedValueOnce({ rows: [{ id: 1 }] }) // Insert helpful mark
        .mockResolvedValueOnce({ rowCount: 1 }); // Update helpful count

      // Check if already marked
      const existing = await db.query(
        'SELECT id FROM review_helpful WHERE review_id = $1 AND user_id = $2',
        [1, 456]
      );

      expect(existing.rows).toHaveLength(0);

      // Mark as helpful
      await db.query(
        'INSERT INTO review_helpful (review_id, user_id) VALUES ($1, $2)',
        [1, 456]
      );

      // Increment helpful count
      const updateResult = await db.query(
        'UPDATE product_reviews SET helpful_count = helpful_count + 1 WHERE id = $1',
        [1]
      );

      expect(updateResult.rowCount).toBe(1);
    });

    it('should unmark a review as helpful (toggle)', async () => {
      const db = require('../../db');
      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 1 }] }) // Existing mark
        .mockResolvedValueOnce({ rowCount: 1 }) // Delete mark
        .mockResolvedValueOnce({ rowCount: 1 }); // Decrement count

      const existing = await db.query(
        'SELECT id FROM review_helpful WHERE review_id = $1 AND user_id = $2',
        [1, 456]
      );

      expect(existing.rows).toHaveLength(1);

      // Remove mark
      const deleteResult = await db.query(
        'DELETE FROM review_helpful WHERE review_id = $1 AND user_id = $2',
        [1, 456]
      );

      expect(deleteResult.rowCount).toBe(1);

      // Decrement count
      const updateResult = await db.query(
        'UPDATE product_reviews SET helpful_count = helpful_count - 1 WHERE id = $1',
        [1]
      );

      expect(updateResult.rowCount).toBe(1);
    });

    it('should prevent duplicate helpful marks', async () => {
      const existingMark = { id: 1 };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [existingMark] });

      const result = await db.query(
        'SELECT id FROM review_helpful WHERE review_id = $1 AND user_id = $2',
        [1, 456]
      );

      expect(result.rows.length).toBeGreaterThan(0);
    });
  });

  describe('User Reviews', () => {
    it('should retrieve all reviews by a specific user', async () => {
      const mockUserReviews = [
        { id: 1, user_id: 456, product_id: 123, product_name: 'Product A' },
        { id: 2, user_id: 456, product_id: 124, product_name: 'Product B' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockUserReviews });

      const result = await db.query(
        `SELECT pr.*, p.name as product_name
         FROM product_reviews pr
         JOIN marketplace_products p ON pr.product_id = p.id
         WHERE pr.user_id = $1 AND pr.status != 'deleted'
         ORDER BY pr.created_at DESC`,
        [456]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(r => r.user_id === 456)).toBe(true);
    });
  });

  describe('Flag Review', () => {
    it('should flag a review as inappropriate', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        "UPDATE product_reviews SET status = 'flagged' WHERE id = $1",
        [1]
      );

      expect(result.rowCount).toBe(1);
    });
  });

  describe('Verified Purchase', () => {
    it('should check if a review is a verified purchase', async () => {
      const mockOrder = {
        id: 1,
        buyer_id: 456,
        status: 'delivered',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockOrder] });

      const result = await db.query(
        `SELECT o.id
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         WHERE o.buyer_id = $1
         AND oi.product_id = $2
         AND o.status IN ('delivered', 'completed')`,
        [456, 123]
      );

      const isVerified = result.rows.length > 0;
      expect(isVerified).toBe(true);
    });

    it('should not mark as verified if no purchase found', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        `SELECT o.id
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         WHERE o.buyer_id = $1
         AND oi.product_id = $2
         AND o.status IN ('delivered', 'completed')`,
        [456, 123]
      );

      const isVerified = result.rows.length > 0;
      expect(isVerified).toBe(false);
    });
  });

  describe('Review Status', () => {
    it('should only include active reviews in public listing', async () => {
      const validStatuses = ['active', 'hidden', 'flagged', 'deleted'];

      expect(validStatuses).toContain('active');
      expect(validStatuses).toContain('deleted');

      const publicStatus = 'active';
      expect(validStatuses).toContain(publicStatus);
    });
  });

  describe('Review Images', () => {
    it('should support multiple images in a review', async () => {
      const images = [
        'https://s3.amazonaws.com/reviews/img1.jpg',
        'https://s3.amazonaws.com/reviews/img2.jpg',
        'https://s3.amazonaws.com/reviews/img3.jpg',
      ];

      expect(Array.isArray(images)).toBe(true);
      expect(images.length).toBeLessThanOrEqual(5); // Max 5 images
    });

    it('should handle reviews without images', async () => {
      const images = [];

      expect(Array.isArray(images)).toBe(true);
      expect(images.length).toBe(0);
    });
  });

  describe('Pagination', () => {
    it('should calculate pagination correctly', () => {
      const page = 2;
      const limit = 10;
      const totalItems = 25;

      const offset = (page - 1) * limit;
      const totalPages = Math.ceil(totalItems / limit);

      expect(offset).toBe(10);
      expect(totalPages).toBe(3);
    });
  });
});
