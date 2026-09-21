// Supervisor Routes — Shift management + dashboard
const express = require('express');
const Shift = require('../models/Shift.model');
const Checklist = require('../models/Checklist.model');
const HazardReport = require('../models/HazardReport.model');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const { emitShiftUpdate } = require('../services/socket.service');

const router = express.Router();

// Direct aliases for shift actions
router.post('/open', authMiddleware, requireRole('supervisor', 'admin'), (req, res, next) => {
  req.url = '/shift/open';
  router.handle(req, res, next);
});

router.post('/close/:id', authMiddleware, requireRole('supervisor', 'admin'), (req, res, next) => {
  req.url = '/shift/close';
  router.handle(req, res, next);
});

router.patch('/verify/:id', authMiddleware, requireRole('supervisor', 'admin'), (req, res, next) => {
  req.url = `/checklist/${req.params.id}/verify`;
  req.body.action = 'verify';
  router.handle(req, res, next);
});

router.patch('/flag/:id', authMiddleware, requireRole('supervisor', 'admin'), (req, res, next) => {
  req.url = `/checklist/${req.params.id}/verify`;
  req.body.action = 'flag';
  router.handle(req, res, next);
});

/**
 * POST /api/supervisor/shift/open
 * Open today's shift for the supervisor's zone
 */
router.post('/shift/open', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const { zone } = req.body;
    const supervisorZone = zone || req.user.zone;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if shift already exists today
    let shift = await Shift.findOne({
      supervisorUid: req.user.uid,
      shiftDate: { $gte: today },
    });

    if (shift && shift.status === 'open') {
      return res.status(409).json({ error: 'Shift already open', shift });
    }

    if (!shift) {
      // Create new shift
      const expectedOpen = new Date(today);
      expectedOpen.setHours(8, 0, 0, 0); // Default: shift starts at 8 AM

      shift = await Shift.create({
        supervisorUid: req.user.uid,
        supervisorName: req.user.name,
        zone: supervisorZone,
        shiftDate: today,
        expectedOpenTime: expectedOpen,
      });
    }

    // Open the shift
    shift.status = 'open';
    shift.openedAt = new Date();
    await shift.save();

    // Audit log
    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: 'shift.open',
      entityType: 'shift',
      entityId: shift._id.toString(),
      metadata: { zone: supervisorZone },
    });

    // Broadcast shift open to zone via Socket.io
    emitShiftUpdate(supervisorZone, {
      shiftId: shift._id,
      status: 'open',
      supervisorName: req.user.name,
      openedAt: shift.openedAt,
      zone: supervisorZone,
    });

    res.json({
      success: true,
      shift,
      message: `✅ Shift opened for ${supervisorZone}`,
    });
  } catch (error) {
    console.error('Shift open error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/supervisor/shift/close
 * Close the current shift
 */
router.post('/shift/close', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const shift = await Shift.findOne({
      supervisorUid: req.user.uid,
      status: 'open',
      shiftDate: { $gte: today },
    });

    if (!shift) {
      return res.status(404).json({ error: 'No open shift found' });
    }

    shift.status = 'closed';
    shift.closedAt = new Date();
    await shift.save();

    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: 'shift.close',
      entityType: 'shift',
      entityId: shift._id.toString(),
    });

    emitShiftUpdate(shift.zone, {
      shiftId: shift._id,
      status: 'closed',
      closedAt: shift.closedAt,
      zone: shift.zone,
      stats: {
        checkinsCount: shift.checkinsCount,
        hazardsCount: shift.hazardsCount,
      },
    });

    res.json({ success: true, shift, message: '✅ Shift closed' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/supervisor/shift/current
 * Get current active shift status
 */
router.get('/shift/current', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const shift = await Shift.findOne({
      supervisorUid: req.user.uid,
      shiftDate: { $gte: today },
    }).sort({ createdAt: -1 });

    res.json({ success: true, shift: shift || null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/supervisor/dashboard
 * Full dashboard data: compliance list, hazard feed, shift stats
 */
router.get('/dashboard', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const zone = req.user.zone;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get all miners in this zone
    const miners = await User.find({ zone, role: 'miner', isActive: true }).select(
      'uid name xpPoints streak riskLevel riskScore badges'
    );

    // Get today's check-ins
    const todayCheckins = await Checklist.find({
      zone,
      date: { $gte: today, $lt: tomorrow },
    }).select('minerUid minerName status xpAwarded streakDay createdAt');

    // Map check-in status per miner
    const checkinMap = {};
    todayCheckins.forEach((c) => {
      checkinMap[c.minerUid] = c;
    });

    const complianceList = miners.map((miner) => ({
      uid: miner.uid,
      name: miner.name,
      xpPoints: miner.xpPoints,
      streak: miner.streak,
      riskLevel: miner.riskLevel,
      riskScore: miner.riskScore,
      badges: miner.badges,
      todayCheckin: checkinMap[miner.uid] || null,
      checkedIn: !!checkinMap[miner.uid],
    }));

    // Get recent hazard reports
    const recentHazards = await HazardReport.find({ zone })
      .sort({ createdAt: -1 })
      .limit(20)
      .select('reporterName description severity status gpsLocation createdAt smsSent');

    // Get current shift
    const currentShift = await Shift.findOne({
      supervisorUid: req.user.uid,
      shiftDate: { $gte: today },
    });

    // Stats
    const totalMiners = miners.length;
    const checkedIn = complianceList.filter((m) => m.checkedIn).length;
    const openHazards = recentHazards.filter((h) => h.status === 'open').length;
    const complianceRate = totalMiners > 0 ? Math.round((checkedIn / totalMiners) * 100) : 0;

    res.json({
      success: true,
      dashboard: {
        zone,
        shift: currentShift,
        stats: {
          totalMiners,
          checkedIn,
          complianceRate,
          openHazards,
          pendingHazards: openHazards,
        },
        complianceList,
        recentHazards,
        lastUpdated: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/supervisor/checklist/:id/verify
 * Supervisor verifies a miner's checklist
 */
router.patch('/checklist/:id/verify', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const { action } = req.body; // 'verify' or 'flag'

    const checklist = await Checklist.findByIdAndUpdate(
      req.params.id,
      {
        status: action === 'flag' ? 'flagged' : 'verified',
        supervisorUid: req.user.uid,
        verifiedAt: new Date(),
      },
      { new: true }
    );

    if (!checklist) return res.status(404).json({ error: 'Checklist not found' });

    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: `checklist.${action}`,
      entityType: 'checklist',
      entityId: checklist._id.toString(),
    });

    res.json({ success: true, checklist });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/supervisor/leaderboard
 * Zone leaderboard by XP points
 */
router.get('/leaderboard', authMiddleware, async (req, res) => {
  try {
    const zone = req.query.zone || req.user.zone;

    const leaderboard = await User.find({ zone, role: 'miner', isActive: true })
      .sort({ xpPoints: -1 })
      .limit(20)
      .select('uid name xpPoints streak badges riskLevel');

    const rankedLeaderboard = leaderboard.map((user, index) => ({
      rank: index + 1,
      uid: user.uid,
      name: user.name,
      xpPoints: user.xpPoints,
      streak: user.streak,
      badges: user.badges,
      riskLevel: user.riskLevel,
    }));

    res.json({ success: true, leaderboard: rankedLeaderboard, zone });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
