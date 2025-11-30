/* eslint-disable camelcase */

exports.shorthands = undefined;

exports.up = pgm => {
    pgm.createTable('app_menu_items', {
        id: 'id',
        label: { type: 'varchar(100)', notNull: true },
        icon_name: { type: 'varchar(100)', notNull: true },
        route_id: { type: 'varchar(100)', notNull: true, unique: true },
        display_order: { type: 'integer', notNull: true },
        is_active: { type: 'boolean', default: true },
        created_at: {
            type: 'timestamp',
            notNull: true,
            default: pgm.func('current_timestamp'),
        },
    });

    // Create index on display_order for faster sorting
    pgm.createIndex('app_menu_items', 'display_order');
};

exports.down = pgm => {
    pgm.dropTable('app_menu_items');
};
