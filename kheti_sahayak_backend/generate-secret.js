// A simple script to generate a strong, random secret key.
const crypto = require('crypto');

const secret = crypto.randomBytes(64).toString('hex');
console.log('Your new JWT secret is:');
console.log(secret);