/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    pgm.addColumns('logbook', {
        version: { type: 'integer', default: 1, notNull: true },
        deleted: { type: 'boolean', default: false, notNull: true },
        last_modified: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Create index on last_modified for efficient delta sync
    pgm.createIndex('logbook', 'last_modified');
};

exports.down = pgm => {
    pgm.dropColumns('logbook', ['version', 'deleted', 'last_modified']);
};
