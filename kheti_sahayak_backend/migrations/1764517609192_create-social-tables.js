/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    // Experts Table
    pgm.createTable('experts', {
        id: 'id',
        name: { type: 'varchar(100)', notNull: true },
        specialization: { type: 'varchar(100)', notNull: true },
        qualification: { type: 'varchar(100)', notNull: true },
        experience_years: { type: 'integer', notNull: true },
        rating: { type: 'numeric(3, 1)', default: 5.0 },
        image_url: { type: 'text' },
        is_online: { type: 'boolean', default: false },
        contact_number: { type: 'varchar(20)' },
        email: { type: 'varchar(100)' },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Community Posts Table
    pgm.createTable('community_posts', {
        id: 'id',
        user_name: { type: 'varchar(100)', notNull: true },
        user_image: { type: 'text' },
        content: { type: 'text', notNull: true },
        image_url: { type: 'text' },
        likes: { type: 'integer', default: 0 },
        comments_count: { type: 'integer', default: 0 },
        timestamp: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    pgm.createIndex('community_posts', 'timestamp');
};

exports.down = pgm => {
    pgm.dropTable('community_posts');
    pgm.dropTable('experts');
};
