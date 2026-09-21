// Checklist Routes
const express = require('express');
const Checklist = require('../models/Checklist.model');
const Shift = require('../models/Shift.model');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const { emitChecklistSubmission } = require('../services/socket.service');

const router = express.Router();

// Role-specific checklist questions
const CHECKLIST_QUESTIONS = {
  miner: [
    { id: 'q1', question: 'Are you inside Zone B boundary?', category: 'location' },
    { id: 'q2', question: 'PPE check — helmet, gloves, boots worn?', category: 'ppe' },
    { id: 'q3', question: 'Equipment check — tools inspected and safe?', category: 'equipment' },
    { id: 'q4', question: 'Ventilation check — air quality normal?', category: 'ventilation' },
    { id: 'q5', question: 'Gas level check — CO/methane within safe range?', category: 'gas' },
    { id: 'q6', question: 'Any visible structural hazards in your area?', category: 'structural' },
    { id: 'q7', question: 'Emergency exit route clear and accessible?', category: 'emergency' },
  ],
  supervisor: [
    { id: 'sq1', question: 'All assigned miners reported to duty?', category: 'headcount' },
    { id: 'sq2', question: 'Zone safety equipment stocked?', category: 'equipment' },
    { id: 'sq3', question: 'Evacuation routes verified clear?', category: 'evacuation' },
    { id: 'sq4', question: 'Previous shift hazard reports reviewed?', category: 'handover' },
    { id: 'sq5', question: 'Communication devices functional?', category: 'comms' },
  ],
};

/**
 * GET /api/checklist/questions
 * Get today's checklist questions for the authenticated user's role
 */
router.get('/questions', authMiddleware, (req, res) => {
  const questions = CHECKLIST_QUESTIONS[req.user.role] || CHECKLIST_QUESTIONS.miner;
  res.json({ success: true, questions, role: req.user.role });
});

/**
 * GET /api/checklist/today
 * Check if user has already submitted today's checklist
 */
router.get('/today', authMiddleware, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const existing = await Checklist.findOne({
      minerUid: req.user.uid,
      date: { $gte: today, $lt: tomorrow },
    });

    res.json({
      success: true,
      submitted: !!existing,
      submission: existing || null,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/checklist/submit
 * Submit daily checklist
 */
router.post('/submit', authMiddleware, async (req, res) => {
  try {
    const { items, gpsLocation, photoUrl, localId, shiftId } = req.body;

    // Validate required fields
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Checklist items required' });
    }

    // Check if shift is open
    let shift = null;
    if (shiftId) {
      shift = await Shift.findById(shiftId);
    } else {
      // Find today's open shift for the user's zone
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      shift = await Shift.findOne({
        zone: req.user.zone,
        status: 'open',
        shiftDate: { $gte: today },
      });
    }

    if (!shift) {
      // Allow submission without shift in dev mode
      if (process.env.NODE_ENV !== 'development') {
        return res.status(400).json({
          error: 'No open shift found. Supervisor must open the shift first.',
        });
      }
      // In dev mode, create a mock shift reference
    }

    // GPS validation (simplified: check if coordinates are provided)
    let isGpsValid = false;
    if (gpsLocation && gpsLocation.latitude && gpsLocation.longitude) {
      isGpsValid = true; // Phase 2: validate against actual zone polygon
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check for duplicate submission today
    const existing = await Checklist.findOne({
      minerUid: req.user.uid,
      date: { $gte: today },
    });

    if (existing) {
      return res.status(409).json({ error: 'Checklist already submitted today' });
    }

    // Get user for streak calculation
    const user = await User.findOne({ uid: req.user.uid });

    // Calculate streak
    let newStreak = 1;
    if (user && user.lastChecklistDate) {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const lastDate = new Date(user.lastChecklistDate);
      lastDate.setHours(0, 0, 0, 0);
      if (lastDate.getTime() === yesterday.getTime()) {
        newStreak = (user.streak || 0) + 1;
      }
    }

    // XP calculation (base + streak bonus)
    const baseXP = 50;
    const streakBonus = Math.min(newStreak * 5, 50); // Max 50 bonus XP for streak
    const totalXP = baseXP + streakBonus;

    // Create checklist submission
    const checklist = await Checklist.create({
      minerUid: req.user.uid,
      minerName: req.user.name,
      zone: req.user.zone,
      shiftId: shift?._id || null,
      date: new Date(),
      items,
      photoUrl: photoUrl || null,
      gpsLocation: gpsLocation || null,
      isGpsValid,
      xpAwarded: totalXP,
      streakDay: newStreak,
      localId: localId || null,
    });

    // Update user XP and streak
    if (user) {
      user.xpPoints = (user.xpPoints || 0) + totalXP;
      user.streak = newStreak;
      user.lastChecklistDate = new Date();
      await user.save();
    }

    // Update shift check-in count
    if (shift) {
      shift.checkinsCount = (shift.checkinsCount || 0) + 1;
      await shift.save();
    }

    // Audit log
    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: 'checklist.submit',
      entityType: 'checklist',
      entityId: checklist._id.toString(),
      metadata: { zone: req.user.zone, xpAwarded: totalXP, streak: newStreak },
    });

    // Emit to supervisor dashboard via Socket.io
    emitChecklistSubmission(req.user.zone, {
      checklistId: checklist._id,
      minerUid: req.user.uid,
      minerName: req.user.name,
      zone: req.user.zone,
      xpAwarded: totalXP,
      streak: newStreak,
      submittedAt: checklist.createdAt,
    });

    res.status(201).json({
      success: true,
      checklist: {
        id: checklist._id,
        xpAwarded: totalXP,
        streak: newStreak,
        message: `✅ Checklist submitted! +${totalXP} XP | Streak: ${newStreak} days`,
      },
    });
  } catch (error) {
    console.error('Checklist submit error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/checklist/history
 * Get checklist submission history for current user
 */
router.get('/history', authMiddleware, async (req, res) => {
  try {
    const { limit = 30, page = 1 } = req.query;
    const skip = (page - 1) * limit;

    const submissions = await Checklist.find({ minerUid: req.user.uid })
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .skip(skip)
      .select('-items'); // Omit detailed items for list view

    const total = await Checklist.countDocuments({ minerUid: req.user.uid });

    res.json({ success: true, submissions, total, page: parseInt(page) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
