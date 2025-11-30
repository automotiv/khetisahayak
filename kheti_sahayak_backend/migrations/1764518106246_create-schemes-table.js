/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    pgm.createTable('schemes', {
        id: 'id',
        name: { type: 'varchar(255)', notNull: true },
        name_hi: { type: 'varchar(255)' },
        description: { type: 'text', notNull: true },
        benefits: { type: 'text' },
        eligibility: { type: 'text' },
        application_process: { type: 'text' },
        documents_required: { type: 'text' },
        link: { type: 'varchar(255)' },
        category: { type: 'varchar(100)' },
        active: { type: 'boolean', default: true },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });
};

exports.down = pgm => {
    pgm.dropTable('schemes');
};
