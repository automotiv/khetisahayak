/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    pgm.createTable('logbook', {
        id: 'id',
        user_id: {
            type: 'uuid',
            notNull: true,
            references: '"users"',
            onDelete: 'CASCADE',
        },
        date: { type: 'date', notNull: true, default: pgm.func('current_date') },
        activity_type: { type: 'varchar(100)', notNull: true },
        description: { type: 'text' },
        cost: { type: 'numeric(10, 2)', default: 0 },
        income: { type: 'numeric(10, 2)', default: 0 },
        images: { type: 'text[]' },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    pgm.createIndex('logbook', 'user_id');
    pgm.createIndex('logbook', 'date');
};

exports.down = pgm => {
    pgm.dropTable('logbook');
};
