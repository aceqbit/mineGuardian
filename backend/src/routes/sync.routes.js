// Sync Routes — Offline-to-online data sync endpoint
const express = require('express');
const HazardReport = require('../models/HazardReport.model');
const Checklist = require('../models/Checklist.model');
const { authMiddleware } = require('../middleware/auth.middleware');
const { emitHazardReport, emitChecklistSubmission } = require('../services/socket.service');

const router = express.Router();

/**
 * POST /api/sync/batch
 * Batch sync all offline data (checklists + hazard reports) from SQLite queue
 */
router.post('/batch', authMiddleware, async (req, res) => {
  try {
    const { hazardReports = [], checklists = [] } = req.body;

    const results = {
      hazardReports: [],
      checklists: [],
      totalSynced: 0,
      errors: [],
    };

    // Sync hazard reports
    for (const report of hazardReports) {
      try {
        // Skip if already synced
        if (report.localId) {
          const existing = await HazardReport.findOne({ localId: report.localId });
          if (existing) {
            results.hazardReports.push({ localId: report.localId, status: 'already_synced' });
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

        emitHazardReport(req.user.zone, {
          hazardId: hazard._id,
          reporterName: req.user.name,
          zone: req.user.zone,
          description: report.description,
          isOfflineSync: true,
        });

        results.hazardReports.push({ localId: report.localId, status: 'synced', id: hazard._id });
        results.totalSynced++;
      } catch (err) {
        results.errors.push({ localId: report.localId, type: 'hazard', error: err.message });
      }
    }

    // Sync checklists
    for (const checklist of checklists) {
      try {
        if (checklist.localId) {
          const existing = await Checklist.findOne({ localId: checklist.localId });
          if (existing) {
            results.checklists.push({ localId: checklist.localId, status: 'already_synced' });
            continue;
          }
        }

        const cl = await Checklist.create({
          minerUid: req.user.uid,
          minerName: req.user.name,
          zone: req.user.zone,
          date: checklist.date ? new Date(checklist.date) : new Date(),
          items: checklist.items || [],
          gpsLocation: checklist.gpsLocation || null,
          photoUrl: checklist.photoUrl || null,
          localId: checklist.localId || null,
          submittedOffline: true,
          xpAwarded: checklist.xpAwarded || 50,
        });

        emitChecklistSubmission(req.user.zone, {
          checklistId: cl._id,
          minerName: req.user.name,
          zone: req.user.zone,
          isOfflineSync: true,
        });

        results.checklists.push({ localId: checklist.localId, status: 'synced', id: cl._id });
        results.totalSynced++;
      } catch (err) {
        results.errors.push({ localId: checklist.localId, type: 'checklist', error: err.message });
      }
    }

    res.json({
      success: true,
      results,
      message: `Synced ${results.totalSynced} items successfully`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/sync/status
 * Check sync status — returns server timestamp for clock sync
 */
router.get('/status', authMiddleware, (req, res) => {
  res.json({
    success: true,
    serverTime: new Date().toISOString(),
    status: 'online',
  });
});

module.exports = router;
