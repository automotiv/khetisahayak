/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    // Create questions table
    pgm.createTable('community_questions', {
        id: {
            type: 'uuid',
            primaryKey: true,
            default: pgm.func('gen_random_uuid()'),
        },
        user_id: {
            type: 'uuid',
            notNull: true,
            references: '"users"',
            onDelete: 'CASCADE',
        },
        title: {
            type: 'varchar(500)',
            notNull: true,
        },
        body: {
            type: 'text',
            notNull: true,
        },
        tags: {
            type: 'text[]',
            default: '{}',
        },
        views: {
            type: 'integer',
            default: 0,
        },
        upvotes: {
            type: 'integer',
            default: 0,
        },
        downvotes: {
            type: 'integer',
            default: 0,
        },
        is_answered: {
            type: 'boolean',
            default: false,
        },
        answers_count: {
            type: 'integer',
            default: 0,
        },
        status: {
            type: 'varchar(20)',
            default: 'active',
        },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
        updated_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Create indexes for questions
    pgm.createIndex('community_questions', 'user_id');
    pgm.createIndex('community_questions', 'created_at');
    pgm.createIndex('community_questions', 'is_answered');
    pgm.createIndex('community_questions', 'tags', { method: 'gin' });

    // Create answers table
    pgm.createTable('community_answers', {
        id: {
            type: 'uuid',
            primaryKey: true,
            default: pgm.func('gen_random_uuid()'),
        },
        question_id: {
            type: 'uuid',
            notNull: true,
            references: '"community_questions"',
            onDelete: 'CASCADE',
        },
        user_id: {
            type: 'uuid',
            notNull: true,
            references: '"users"',
            onDelete: 'CASCADE',
        },
        body: {
            type: 'text',
            notNull: true,
        },
        upvotes: {
            type: 'integer',
            default: 0,
        },
        downvotes: {
            type: 'integer',
            default: 0,
        },
        is_accepted: {
            type: 'boolean',
            default: false,
        },
        status: {
            type: 'varchar(20)',
            default: 'active',
        },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
        updated_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Create indexes for answers
    pgm.createIndex('community_answers', 'question_id');
    pgm.createIndex('community_answers', 'user_id');
    pgm.createIndex('community_answers', 'created_at');
    pgm.createIndex('community_answers', 'is_accepted');

    // Create votes table (polymorphic for both questions and answers)
    pgm.createTable('community_votes', {
        id: {
            type: 'uuid',
            primaryKey: true,
            default: pgm.func('gen_random_uuid()'),
        },
        user_id: {
            type: 'uuid',
            notNull: true,
            references: '"users"',
            onDelete: 'CASCADE',
        },
        votable_id: {
            type: 'uuid',
            notNull: true,
        },
        votable_type: {
            type: 'varchar(20)',
            notNull: true,
        },
        vote_type: {
            type: 'smallint',
            notNull: true,
        },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Create unique constraint to prevent duplicate votes
    pgm.createIndex('community_votes', ['user_id', 'votable_id', 'votable_type'], {
        unique: true,
        name: 'community_votes_user_votable_unique',
    });
    pgm.createIndex('community_votes', 'votable_id');
    pgm.createIndex('community_votes', 'votable_type');

    // Create question tags table for better tag querying
    pgm.createTable('community_tags', {
        id: 'id',
        name: {
            type: 'varchar(100)',
            notNull: true,
            unique: true,
        },
        description: {
            type: 'text',
        },
        questions_count: {
            type: 'integer',
            default: 0,
        },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    pgm.createIndex('community_tags', 'name');
};

exports.down = pgm => {
    pgm.dropTable('community_tags');
    pgm.dropTable('community_votes');
    pgm.dropTable('community_answers');
    pgm.dropTable('community_questions');
};
