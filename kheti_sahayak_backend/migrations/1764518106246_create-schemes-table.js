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
        min_farm_size: { type: 'float' },
        max_farm_size: { type: 'float' },
        crops: { type: 'text' }, // JSON string of supported crops
        states: { type: 'text' }, // JSON string of applicable states
        districts: { type: 'text' }, // JSON string of applicable districts
        min_income: { type: 'float' },
        max_income: { type: 'float' },
        land_ownership_type: { type: 'varchar(100)' },
        deadline: { type: 'timestamp' },
        benefits_matrix: { type: 'json' }, // Structured benefits data
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
