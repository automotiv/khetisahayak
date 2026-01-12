exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.addColumns('users', {
    google_id: { type: 'varchar(255)', unique: true },
    facebook_id: { type: 'varchar(255)', unique: true },
    auth_provider: { type: 'varchar(50)', default: 'email' },
    email_verified: { type: 'boolean', default: false },
    phone_verified: { type: 'boolean', default: false },
  });

  pgm.alterColumn('users', 'password_hash', { notNull: false });

  pgm.addColumns('user_sessions', {
    auth_provider: { type: 'varchar(50)', default: 'email' },
  });

  pgm.createIndex('users', 'google_id');
  pgm.createIndex('users', 'facebook_id');
};

exports.down = (pgm) => {
  pgm.dropIndex('users', 'facebook_id');
  pgm.dropIndex('users', 'google_id');
  
  pgm.dropColumns('user_sessions', ['auth_provider']);
  
  pgm.alterColumn('users', 'password_hash', { notNull: true });
  
  pgm.dropColumns('users', [
    'google_id',
    'facebook_id', 
    'auth_provider',
    'email_verified',
    'phone_verified',
  ]);
};
