const db = require('../db');
const asyncHandler = require('express-async-handler');

const createQuestion = asyncHandler(async (req, res) => {
  const { title, body, tags } = req.body;
  const userId = req.user.id;

  if (!title || title.trim().length < 10) {
    res.status(400);
    throw new Error('Title must be at least 10 characters long');
  }

  if (!body || body.trim().length < 20) {
    res.status(400);
    throw new Error('Body must be at least 20 characters long');
  }

  const tagArray = Array.isArray(tags) ? tags.slice(0, 5) : [];

  const result = await db.query(
    `INSERT INTO community_questions (user_id, title, body, tags)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, title.trim(), body.trim(), tagArray]
  );

  for (const tag of tagArray) {
    await db.query(
      `INSERT INTO community_tags (name)
       VALUES ($1)
       ON CONFLICT (name) DO UPDATE SET questions_count = community_tags.questions_count + 1`,
      [tag.toLowerCase().trim()]
    );
  }

  res.status(201).json({
    success: true,
    message: 'Question created successfully',
    data: result.rows[0],
  });
});

const getQuestions = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, tag, answered, sort = 'recent', search } = req.query;
  const offset = (page - 1) * limit;

  let query = `
    SELECT
      q.*,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image
    FROM community_questions q
    JOIN users u ON q.user_id = u.id
    WHERE q.status = 'active'
  `;

  const queryParams = [];
  let paramCount = 0;

  if (tag) {
    paramCount++;
    query += ` AND $${paramCount} = ANY(q.tags)`;
    queryParams.push(tag.toLowerCase());
  }

  if (answered !== undefined) {
    paramCount++;
    query += ` AND q.is_answered = $${paramCount}`;
    queryParams.push(answered === 'true');
  }

  if (search) {
    paramCount++;
    query += ` AND (q.title ILIKE $${paramCount} OR q.body ILIKE $${paramCount})`;
    queryParams.push(`%${search}%`);
  }

  switch (sort) {
    case 'votes':
      query += ' ORDER BY (q.upvotes - q.downvotes) DESC, q.created_at DESC';
      break;
    case 'unanswered':
      query += ' ORDER BY q.is_answered ASC, q.created_at DESC';
      break;
    case 'views':
      query += ' ORDER BY q.views DESC, q.created_at DESC';
      break;
    case 'recent':
    default:
      query += ' ORDER BY q.created_at DESC';
  }

  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));

  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  const countQuery = `SELECT COUNT(*) FROM community_questions WHERE status = 'active'`;
  const countResult = await db.query(countQuery);

  res.json({
    success: true,
    data: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(countResult.rows[0].count / limit),
      total_items: parseInt(countResult.rows[0].count),
      items_per_page: parseInt(limit),
    },
  });
});

const getQuestion = asyncHandler(async (req, res) => {
  const { id } = req.params;

  await db.query(
    'UPDATE community_questions SET views = views + 1 WHERE id = $1',
    [id]
  );

  const questionResult = await db.query(
    `SELECT
      q.*,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image
     FROM community_questions q
     JOIN users u ON q.user_id = u.id
     WHERE q.id = $1 AND q.status = 'active'`,
    [id]
  );

  if (questionResult.rows.length === 0) {
    res.status(404);
    throw new Error('Question not found');
  }

  const answersResult = await db.query(
    `SELECT
      a.*,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image
     FROM community_answers a
     JOIN users u ON a.user_id = u.id
     WHERE a.question_id = $1 AND a.status = 'active'
     ORDER BY a.is_accepted DESC, (a.upvotes - a.downvotes) DESC, a.created_at ASC`,
    [id]
  );

  let userVote = null;
  if (req.user) {
    const voteResult = await db.query(
      `SELECT vote_type FROM community_votes
       WHERE user_id = $1 AND votable_id = $2 AND votable_type = 'question'`,
      [req.user.id, id]
    );
    if (voteResult.rows.length > 0) {
      userVote = voteResult.rows[0].vote_type;
    }
  }

  res.json({
    success: true,
    data: {
      ...questionResult.rows[0],
      user_vote: userVote,
      answers: answersResult.rows,
    },
  });
});

const updateQuestion = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { title, body, tags } = req.body;
  const userId = req.user.id;

  const questionResult = await db.query(
    'SELECT * FROM community_questions WHERE id = $1',
    [id]
  );

  if (questionResult.rows.length === 0) {
    res.status(404);
    throw new Error('Question not found');
  }

  if (questionResult.rows[0].user_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to update this question');
  }

  const tagArray = Array.isArray(tags) ? tags.slice(0, 5) : questionResult.rows[0].tags;

  const result = await db.query(
    `UPDATE community_questions
     SET title = COALESCE($1, title),
         body = COALESCE($2, body),
         tags = $3,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [title?.trim(), body?.trim(), tagArray, id]
  );

  res.json({
    success: true,
    message: 'Question updated successfully',
    data: result.rows[0],
  });
});

const deleteQuestion = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const questionResult = await db.query(
    'SELECT * FROM community_questions WHERE id = $1',
    [id]
  );

  if (questionResult.rows.length === 0) {
    res.status(404);
    throw new Error('Question not found');
  }

  if (questionResult.rows[0].user_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to delete this question');
  }

  await db.query(
    "UPDATE community_questions SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
    [id]
  );

  res.json({
    success: true,
    message: 'Question deleted successfully',
  });
});

const createAnswer = asyncHandler(async (req, res) => {
  const { questionId } = req.params;
  const { body } = req.body;
  const userId = req.user.id;

  if (!body || body.trim().length < 20) {
    res.status(400);
    throw new Error('Answer must be at least 20 characters long');
  }

  const questionResult = await db.query(
    'SELECT id FROM community_questions WHERE id = $1 AND status = $2',
    [questionId, 'active']
  );

  if (questionResult.rows.length === 0) {
    res.status(404);
    throw new Error('Question not found');
  }

  const result = await db.query(
    `INSERT INTO community_answers (question_id, user_id, body)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [questionId, userId, body.trim()]
  );

  await db.query(
    'UPDATE community_questions SET answers_count = answers_count + 1 WHERE id = $1',
    [questionId]
  );

  res.status(201).json({
    success: true,
    message: 'Answer created successfully',
    data: result.rows[0],
  });
});

const updateAnswer = asyncHandler(async (req, res) => {
  const { answerId } = req.params;
  const { body } = req.body;
  const userId = req.user.id;

  const answerResult = await db.query(
    'SELECT * FROM community_answers WHERE id = $1',
    [answerId]
  );

  if (answerResult.rows.length === 0) {
    res.status(404);
    throw new Error('Answer not found');
  }

  if (answerResult.rows[0].user_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to update this answer');
  }

  const result = await db.query(
    `UPDATE community_answers
     SET body = COALESCE($1, body),
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $2
     RETURNING *`,
    [body?.trim(), answerId]
  );

  res.json({
    success: true,
    message: 'Answer updated successfully',
    data: result.rows[0],
  });
});

const deleteAnswer = asyncHandler(async (req, res) => {
  const { answerId } = req.params;
  const userId = req.user.id;

  const answerResult = await db.query(
    'SELECT * FROM community_answers WHERE id = $1',
    [answerId]
  );

  if (answerResult.rows.length === 0) {
    res.status(404);
    throw new Error('Answer not found');
  }

  if (answerResult.rows[0].user_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to delete this answer');
  }

  const questionId = answerResult.rows[0].question_id;

  await db.query(
    "UPDATE community_answers SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
    [answerId]
  );

  await db.query(
    'UPDATE community_questions SET answers_count = answers_count - 1 WHERE id = $1',
    [questionId]
  );

  res.json({
    success: true,
    message: 'Answer deleted successfully',
  });
});

const acceptAnswer = asyncHandler(async (req, res) => {
  const { answerId } = req.params;
  const userId = req.user.id;

  const answerResult = await db.query(
    `SELECT a.*, q.user_id as question_owner_id
     FROM community_answers a
     JOIN community_questions q ON a.question_id = q.id
     WHERE a.id = $1`,
    [answerId]
  );

  if (answerResult.rows.length === 0) {
    res.status(404);
    throw new Error('Answer not found');
  }

  if (answerResult.rows[0].question_owner_id !== userId) {
    res.status(403);
    throw new Error('Only the question author can accept an answer');
  }

  const questionId = answerResult.rows[0].question_id;

  await db.query(
    'UPDATE community_answers SET is_accepted = false WHERE question_id = $1',
    [questionId]
  );

  await db.query(
    'UPDATE community_answers SET is_accepted = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
    [answerId]
  );

  await db.query(
    'UPDATE community_questions SET is_answered = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
    [questionId]
  );

  res.json({
    success: true,
    message: 'Answer accepted successfully',
  });
});

const vote = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { type, voteType } = req.body;
  const userId = req.user.id;

  if (!['question', 'answer'].includes(type)) {
    res.status(400);
    throw new Error('Invalid vote target type');
  }

  if (![-1, 1].includes(voteType)) {
    res.status(400);
    throw new Error('Vote type must be 1 (upvote) or -1 (downvote)');
  }

  const tableName = type === 'question' ? 'community_questions' : 'community_answers';

  const itemResult = await db.query(
    `SELECT id, user_id FROM ${tableName} WHERE id = $1 AND status = 'active'`,
    [id]
  );

  if (itemResult.rows.length === 0) {
    res.status(404);
    throw new Error(`${type.charAt(0).toUpperCase() + type.slice(1)} not found`);
  }

  if (itemResult.rows[0].user_id === userId) {
    res.status(400);
    throw new Error('You cannot vote on your own content');
  }

  const existingVote = await db.query(
    `SELECT vote_type FROM community_votes
     WHERE user_id = $1 AND votable_id = $2 AND votable_type = $3`,
    [userId, id, type]
  );

  if (existingVote.rows.length > 0) {
    const oldVoteType = existingVote.rows[0].vote_type;

    if (oldVoteType === voteType) {
      await db.query(
        `DELETE FROM community_votes
         WHERE user_id = $1 AND votable_id = $2 AND votable_type = $3`,
        [userId, id, type]
      );

      if (voteType === 1) {
        await db.query(
          `UPDATE ${tableName} SET upvotes = upvotes - 1 WHERE id = $1`,
          [id]
        );
      } else {
        await db.query(
          `UPDATE ${tableName} SET downvotes = downvotes - 1 WHERE id = $1`,
          [id]
        );
      }

      res.json({ success: true, message: 'Vote removed', vote: null });
      return;
    }

    await db.query(
      `UPDATE community_votes SET vote_type = $1
       WHERE user_id = $2 AND votable_id = $3 AND votable_type = $4`,
      [voteType, userId, id, type]
    );

    if (voteType === 1) {
      await db.query(
        `UPDATE ${tableName} SET upvotes = upvotes + 1, downvotes = downvotes - 1 WHERE id = $1`,
        [id]
      );
    } else {
      await db.query(
        `UPDATE ${tableName} SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = $1`,
        [id]
      );
    }
  } else {
    await db.query(
      `INSERT INTO community_votes (user_id, votable_id, votable_type, vote_type)
       VALUES ($1, $2, $3, $4)`,
      [userId, id, type, voteType]
    );

    if (voteType === 1) {
      await db.query(
        `UPDATE ${tableName} SET upvotes = upvotes + 1 WHERE id = $1`,
        [id]
      );
    } else {
      await db.query(
        `UPDATE ${tableName} SET downvotes = downvotes + 1 WHERE id = $1`,
        [id]
      );
    }
  }

  res.json({
    success: true,
    message: voteType === 1 ? 'Upvoted successfully' : 'Downvoted successfully',
    vote: voteType,
  });
});

const getTags = asyncHandler(async (req, res) => {
  const { limit = 50 } = req.query;

  const result = await db.query(
    `SELECT name, questions_count
     FROM community_tags
     ORDER BY questions_count DESC
     LIMIT $1`,
    [parseInt(limit)]
  );

  res.json({
    success: true,
    data: result.rows,
  });
});

const getMyQuestions = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const result = await db.query(
    `SELECT * FROM community_questions
     WHERE user_id = $1 AND status != 'deleted'
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, parseInt(limit), offset]
  );

  const countResult = await db.query(
    "SELECT COUNT(*) FROM community_questions WHERE user_id = $1 AND status != 'deleted'",
    [userId]
  );

  res.json({
    success: true,
    data: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(countResult.rows[0].count / limit),
      total_items: parseInt(countResult.rows[0].count),
      items_per_page: parseInt(limit),
    },
  });
});

module.exports = {
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
};
