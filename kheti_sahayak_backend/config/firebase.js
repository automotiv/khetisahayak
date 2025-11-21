/**
 * Firebase Admin SDK Configuration
 *
 * Setup Instructions:
 * 1. Go to https://console.firebase.google.com
 * 2. Create a project named "Kheti Sahayak" (or use existing)
 * 3. Go to Project Settings > Service Accounts
 * 4. Click "Generate new private key"
 * 5. Save as 'firebase-service-account.json' in this directory
 * 6. Add to .gitignore: config/firebase-service-account.json
 *
 * OR set environment variables:
 * - FIREBASE_PROJECT_ID
 * - FIREBASE_CLIENT_EMAIL
 * - FIREBASE_PRIVATE_KEY (base64 encoded)
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let firebaseApp = null;

const initializeFirebase = () => {
  if (firebaseApp) {
    return firebaseApp;
  }

  try {
    // Try to load service account from file
    const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('Firebase initialized with service account file');
    }
    // Try environment variables
    else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
      const privateKey = Buffer.from(process.env.FIREBASE_PRIVATE_KEY, 'base64').toString('utf-8');

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey.replace(/\\n/g, '\n')
        })
      });
      console.log('Firebase initialized with environment variables');
    }
    // Mock mode for development
    else {
      console.warn('Firebase credentials not found. Push notifications will be simulated.');
      firebaseApp = null;
    }
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    firebaseApp = null;
  }

  return firebaseApp;
};

const getFirebaseAdmin = () => {
  if (!firebaseApp) {
    initializeFirebase();
  }
  return firebaseApp ? admin : null;
};

const isFirebaseEnabled = () => {
  return firebaseApp !== null;
};

module.exports = {
  initializeFirebase,
  getFirebaseAdmin,
  isFirebaseEnabled,
  admin
};
