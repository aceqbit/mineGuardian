// Auth Routes — Firebase Token verification + JWT issuance
const express = require('express');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * POST /api/auth/login
 * Phone + PIN login with demo mock support
 */
router.post('/login', async (req, res) => {
  try {
    const { phone, pin } = req.body;

    if (!phone || !pin) {
      return res.status(400).json({ error: 'Phone number and PIN are required' });
    }

    const isSupervisor = phone.endsWith('1') || phone.includes('543211') || pin === '9999';
    const role = isSupervisor ? 'supervisor' : 'miner';
    const name = isSupervisor ? 'Vikram Singh (Supervisor)' : 'Ramesh Kumar (Miner)';
    const employeeId = isSupervisor ? 'SUP-2026' : 'MIN-8812';
    const zone = 'Zone-A (Shaft 3)';
    const uid = isSupervisor ? 'sup_demo_uid_1' : 'miner_demo_uid_1';

    const token = jwt.sign(
      { uid, role, zone, name },
      process.env.JWT_SECRET || 'mine_guardian_secret_jwt_key_2026',
      { expiresIn: '7d' }
    );

    const user = {
      id: uid,
      employeeId,
      name,
      phone,
      role,
      zone,
      safetyScore: 98,
      streakDays: isSupervisor ? 12 : 5,
      xp: isSupervisor ? 1250 : 350,
      token,
    };

    res.json({
      success: true,
      token,
      user,
      message: 'Login successful',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/auth/verify-token
 * Verify Firebase ID token → issue app JWT + return user role
 */
router.post('/verify-token', async (req, res) => {
  try {
    const { firebaseToken, fcmToken } = req.body;

    if (!firebaseToken) {
      return res.status(400).json({ error: 'Firebase token required' });
    }

    let firebaseUser;

    // In dev mode (placeholder credentials), skip Firebase verification
    const isDevMode =
      process.env.FIREBASE_PROJECT_ID === 'mine-guardian-placeholder' ||
      !admin.apps.length;

    if (isDevMode) {
      // Dev mode: accept a mock token with format "dev:uid:role:name"
      const parts = firebaseToken.split(':');
      if (parts[0] === 'dev' && parts.length >= 4) {
        firebaseUser = { uid: parts[1], role: parts[2], name: parts[3] };
      } else {
        return res.status(400).json({ error: 'Dev mode: use format dev:uid:role:name' });
      }
    } else {
      // Production: verify real Firebase token
      const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
      firebaseUser = { uid: decodedToken.uid, phone: decodedToken.phone_number };
    }

    // Get or create user in MongoDB
    let user = await User.findOne({ uid: firebaseUser.uid });

    if (!user) {
      // New user — create with default miner role (admin can change later)
      user = await User.create({
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phone || `+91${firebaseUser.uid.substring(0, 10)}`,
        name: firebaseUser.name || 'New User',
        role: firebaseUser.role || 'miner',
        zone: 'Zone A',
      });
    }

    // Update FCM token if provided
    if (fcmToken && user.fcmToken !== fcmToken) {
      user.fcmToken = fcmToken;
      await user.save();
    }

    // Issue app JWT
    const appJwt = jwt.sign(
      {
        uid: user.uid,
        role: user.role,
        zone: user.zone,
        name: user.name,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Audit log
    await AuditLog.create({
      actorUid: user.uid,
      actorName: user.name,
      actorRole: user.role,
      action: 'auth.login',
      entityType: 'user',
      entityId: user._id.toString(),
    });

    res.json({
      success: true,
      token: appJwt,
      user: {
        uid: user.uid,
        name: user.name,
        role: user.role,
        zone: user.zone,
        xpPoints: user.xpPoints,
        streak: user.streak,
        riskLevel: user.riskLevel,
        badges: user.badges,
      },
    });
  } catch (error) {
    console.error('Auth error:', error);
    res.status(401).json({ error: 'Authentication failed', details: error.message });
  }
});

/**
 * GET /api/auth/me
 * Get current user profile
 */
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await User.findOne({ uid: req.user.uid }).select('-__v');
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/auth/fcm-token
 * Update FCM push token
 */
router.put('/fcm-token', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    await User.findOneAndUpdate({ uid: req.user.uid }, { fcmToken });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
