const express = require('express');
const router = express.Router();
const db = require('../db');
const { protect } = require('../middleware/authMiddleware');
const {
  communityPostValidation,
  validatePagination,
  handleValidationErrors,
  validateUUID,
  sanitizeString,
  sanitizeText,
  validateArray,
  validateEnum,
} = require('../middleware/validationMiddleware');
const {
  createQuestion,
  getQuestions,
  getQuestion,
  updateQuestion,
  deleteQuestion,
  createAnswer,
  updateAnswer,
  deleteAnswer,
  acceptAnswer,
  vote,
  getTags,
  getMyQuestions,
} = require('../controllers/communityController');

const questionValidation = [
  sanitizeString('title', { maxLength: 500 }),
  sanitizeText('body', { maxLength: 10000 }),
  validateArray('tags', { required: false, maxLength: 5 }),
  handleValidationErrors,
];

const answerValidation = [
  sanitizeText('body', { maxLength: 10000 }),
  handleValidationErrors,
];

const voteValidation = [
  validateEnum('type', ['question', 'answer']),
  handleValidationErrors,
];

router.get('/questions', [...validatePagination, handleValidationErrors], getQuestions);
router.get('/questions/my', protect, getMyQuestions);
router.get('/questions/:id', [validateUUID('id'), handleValidationErrors], getQuestion);
router.post('/questions', protect, questionValidation, createQuestion);
router.put('/questions/:id', protect, [validateUUID('id'), ...questionValidation], updateQuestion);
router.delete('/questions/:id', protect, [validateUUID('id'), handleValidationErrors], deleteQuestion);

router.post('/questions/:questionId/answers', protect, [validateUUID('questionId'), ...answerValidation], createAnswer);
router.put('/answers/:answerId', protect, [validateUUID('answerId'), ...answerValidation], updateAnswer);
router.delete('/answers/:answerId', protect, [validateUUID('answerId'), handleValidationErrors], deleteAnswer);
router.post('/answers/:answerId/accept', protect, [validateUUID('answerId'), handleValidationErrors], acceptAnswer);

router.post('/vote/:id', protect, [validateUUID('id'), ...voteValidation], vote);

router.get('/tags', getTags);

router.get('/posts', [...validatePagination, handleValidationErrors], async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const result = await db.query(
      'SELECT * FROM community_posts ORDER BY timestamp DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    res.json({
      success: true,
      data: result.rows,
      pagination: { page, limit },
    });
  } catch (error) {
    console.error('Error fetching community posts:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching community posts',
    });
  }
});

router.post('/posts', communityPostValidation, async (req, res) => {
  try {
    const { user_name, content, image_url } = req.body;

    const result = await db.query(
      'INSERT INTO community_posts (user_name, content, image_url) VALUES ($1, $2, $3) RETURNING *',
      [user_name, content, image_url]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({
      success: false,
      message: 'Server error creating post',
    });
  }
});

module.exports = router;
