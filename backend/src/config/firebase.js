// Firebase Admin SDK initialization
const admin = require('firebase-admin');

let firebaseApp = null;

const initFirebase = () => {
  if (firebaseApp) return firebaseApp;

  try {
    const serviceAccount = {
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    };

    // Only initialize if credentials look valid
    if (
      serviceAccount.project_id === 'mine-guardian-placeholder' ||
      !serviceAccount.private_key ||
      serviceAccount.private_key.includes('PLACEHOLDER')
    ) {
      console.warn('⚠️  Firebase: Using placeholder credentials — Auth verification disabled in dev mode');
      return null;
    }

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: `${process.env.FIREBASE_PROJECT_ID}.appspot.com`,
    });

    console.log('✅ Firebase Admin SDK initialized');
    return firebaseApp;
  } catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
    console.warn('⚠️  Running without Firebase Auth verification');
    return null;
  }
};

const getFirebaseAdmin = () => admin;

module.exports = initFirebase;
module.exports.getAdmin = getFirebaseAdmin;
