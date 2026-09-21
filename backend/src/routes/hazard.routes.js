// Hazard Report Routes
const express = require('express');
const HazardReport = require('../models/HazardReport.model');
const Shift = require('../models/Shift.model');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const { emitHazardReport } = require('../services/socket.service');
const { sendHazardReportSMS } = require('../services/twilio.service');

const router = express.Router();

/**
 * GET /api/hazard or /api/hazards
 * Get all hazards or filter by zone
 */
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { zone, status, limit = 50 } = req.query;
    const query = {};
    if (zone && zone !== 'All Zones') query.zone = zone;
    if (status) query.status = status;

    const hazards = await HazardReport.find(query).sort({ createdAt: -1 }).limit(parseInt(limit));
    res.json({ success: true, hazards, count: hazards.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/hazard or /api/hazards
 * Direct submit hazard report
 */
router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      title,
      description,
      hazardType,
      severity,
      zone,
      latitude,
      longitude,
      photos,
      voiceNotes,
      localId,
    } = req.body;

    const hazard = await HazardReport.create({
      reporterUid: req.user.uid,
      reporterName: req.user.name,
      zone: zone || req.user.zone || 'Zone-A',
      title: title || `${hazardType || 'Hazard'} reported`,
      description: description || 'No description provided',
      hazardType: hazardType || 'Other',
      severity: severity || 'medium',
      gpsLocation: latitude && longitude ? { latitude, longitude } : null,
      photos: Array.isArray(photos) ? photos : [],
      voiceNotes: voiceNotes || null,
      localId: localId || null,
    });

    emitHazardReport(hazard.zone, hazard);

    res.status(201).json({
      success: true,
      report: hazard,
      message: 'Hazard report submitted successfully',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/hazard/report
 * Submit a hazard report (online sync of offline SQLite queue)
 */
router.post('/report', authMiddleware, async (req, res) => {
  try {
    const {
      description,
      photoUrl,
      audioUrl,
      gpsLocation,
      severity,
      localId,
      submittedOffline,
      submittedAt, // Original timestamp if submitted offline
    } = req.body;

    if (!description || !gpsLocation) {
      return res.status(400).json({ error: 'Description and GPS location required' });
    }

    // Find today's shift for zone
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const shift = await Shift.findOne({
      zone: req.user.zone,
      status: { $in: ['open', 'auto_flagged'] },
      shiftDate: { $gte: today },
    });

    // Create hazard report
    const hazard = await HazardReport.create({
      reporterUid: req.user.uid,
      reporterName: req.user.name,
      zone: req.user.zone,
      shiftId: shift?._id || null,
      description,
      photoUrl: photoUrl || null,
      audioUrl: audioUrl || null,
      gpsLocation,
      severity: severity || 'medium',
      localId: localId || null,
      submittedOffline: submittedOffline || false,
      syncedAt: submittedOffline ? new Date() : null,
    });

    // Update shift hazard count
    if (shift) {
      shift.hazardsCount = (shift.hazardsCount || 0) + 1;
      await shift.save();
    }

    // Audit log
    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: 'hazard.report',
      entityType: 'hazard',
      entityId: hazard._id.toString(),
      metadata: {
        zone: req.user.zone,
        severity: hazard.severity,
        submittedOffline,
        gps: gpsLocation,
      },
    });

    // Emit to supervisor dashboard via Socket.io (real-time)
    emitHazardReport(req.user.zone, {
      hazardId: hazard._id,
      reporterUid: req.user.uid,
      reporterName: req.user.name,
      zone: req.user.zone,
      description,
      severity: hazard.severity,
      gpsLocation,
      photoUrl: photoUrl || null,
      submittedAt: hazard.createdAt,
    });

    // Send SMS to supervisor (async, non-blocking)
    (async () => {
      try {
        const supervisor = await User.findOne({
          zone: req.user.zone,
          role: 'supervisor',
          isActive: true,
        });

        if (supervisor && supervisor.phoneNumber) {
          const smsResult = await sendHazardReportSMS({
            hazardReport: { ...hazard.toObject(), reporterName: req.user.name },
            supervisorPhone: supervisor.phoneNumber,
            supervisorName: supervisor.name,
          });

          if (smsResult.success) {
            await HazardReport.findByIdAndUpdate(hazard._id, {
              smsSent: true,
              smsSentAt: new Date(),
              smsMessageSid: smsResult.messageSid,
            });
          }
        }
      } catch (smsError) {
        console.error('Background SMS error:', smsError.message);
      }
    })();

    res.status(201).json({
      success: true,
      hazard: {
        id: hazard._id,
        severity: hazard.severity,
        status: hazard.status,
        message: '⚠️ Hazard report submitted. Supervisor notified.',
      },
    });
  } catch (error) {
    console.error('Hazard report error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/hazard/sync-batch
 * Batch sync offline hazard reports from SQLite queue
 */
router.post('/sync-batch', authMiddleware, async (req, res) => {
  try {
    const { reports } = req.body;

    if (!Array.isArray(reports) || reports.length === 0) {
      return res.status(400).json({ error: 'Reports array required' });
    }

    const results = [];

    for (const report of reports) {
      try {
        // Check if already synced (by localId)
        if (report.localId) {
          const existing = await HazardReport.findOne({ localId: report.localId });
          if (existing) {
            results.push({ localId: report.localId, status: 'already_synced', id: existing._id });
            continue;
          }
        }

        const hazard = await HazardReport.create({
          reporterUid: req.user.uid,
          reporterName: req.user.name,
          zone: req.user.zone,
          description: report.description,
          photoUrl: report.photoUrl || null,
          audioUrl: report.audioUrl || null,
          gpsLocation: report.gpsLocation,
          severity: report.severity || 'medium',
          localId: report.localId || null,
          submittedOffline: true,
          syncedAt: new Date(),
        });

        // Emit to supervisor
        emitHazardReport(req.user.zone, {
          hazardId: hazard._id,
          reporterName: req.user.name,
          zone: req.user.zone,
          description: report.description,
          severity: hazard.severity,
          gpsLocation: report.gpsLocation,
          isOfflineSync: true,
        });

        results.push({ localId: report.localId, status: 'synced', id: hazard._id });
      } catch (reportError) {
        results.push({ localId: report.localId, status: 'error', error: reportError.message });
      }
    }

    res.json({ success: true, results, synced: results.filter((r) => r.status === 'synced').length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/hazard/my-reports
 * Get hazard reports submitted by current user
 */
router.get('/my-reports', authMiddleware, async (req, res) => {
  try {
    const { limit = 20, page = 1 } = req.query;
    const reports = await HazardReport.find({ reporterUid: req.user.uid })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((page - 1) * limit);

    res.json({ success: true, reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/hazard/zone/:zone
 * Get all hazard reports for a zone (supervisor access)
 */
router.get('/zone/:zone', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const { status, limit = 50 } = req.query;
    const query = { zone: req.params.zone };
    if (status) query.status = status;

    const reports = await HazardReport.find(query).sort({ createdAt: -1 }).limit(parseInt(limit));

    res.json({ success: true, reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/hazard/:id/resolve
 * Mark hazard as resolved (supervisor)
 */
router.patch('/:id/resolve', authMiddleware, requireRole('supervisor', 'admin'), async (req, res) => {
  try {
    const { resolutionNotes } = req.body;

    const hazard = await HazardReport.findByIdAndUpdate(
      req.params.id,
      {
        status: 'resolved',
        supervisorUid: req.user.uid,
        resolvedAt: new Date(),
        resolutionNotes: resolutionNotes || null,
      },
      { new: true }
    );

    if (!hazard) return res.status(404).json({ error: 'Hazard report not found' });

    await AuditLog.create({
      actorUid: req.user.uid,
      actorName: req.user.name,
      actorRole: req.user.role,
      action: 'hazard.resolve',
      entityType: 'hazard',
      entityId: hazard._id.toString(),
    });

    res.json({ success: true, hazard });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
