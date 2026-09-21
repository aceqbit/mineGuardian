// node-cron Service — Shift SLA & scheduled tasks
const Shift = require('../models/Shift.model');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { emitShiftUpdate } = require('./socket.service');

/**
 * Run every 30 minutes: Check if supervisors have opened their shifts.
 * If a shift is 30+ minutes past expected open time and still 'pending', auto-flag it.
 * Protect miner scores when supervisor SLA is breached.
 */
const runShiftSLACheck = async () => {
  try {
    const now = new Date();
    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60 * 1000);

    // Find pending shifts where expected open time was > 30 min ago
    const overdueShifts = await Shift.find({
      status: 'pending',
      expectedOpenTime: { $lte: thirtyMinutesAgo },
      slaBreached: false,
    });

    for (const shift of overdueShifts) {
      // Mark SLA as breached
      shift.status = 'auto_flagged';
      shift.slaBreached = true;
      shift.slaBreachedAt = now;
      shift.minerScoresProtected = true; // Miners won't be penalized
      await shift.save();

      // Emit alert to supervisor
      emitShiftUpdate(shift.zone, {
        shiftId: shift._id,
        status: 'auto_flagged',
        message: 'Shift not opened within 30 minutes. Miner scores protected.',
        supervisorUid: shift.supervisorUid,
      });

      // Log to audit
      await AuditLog.create({
        actorUid: 'system',
        actorName: 'MineGuardian System',
        actorRole: 'system',
        action: 'shift.auto_flagged',
        entityType: 'shift',
        entityId: shift._id.toString(),
        metadata: {
          zone: shift.zone,
          supervisorUid: shift.supervisorUid,
          expectedOpenTime: shift.expectedOpenTime,
          slaBreachedAt: now,
        },
      });

      console.log(
        `⚠️  [CRON] Shift auto-flagged: ${shift._id} | Zone: ${shift.zone} | Supervisor: ${shift.supervisorUid}`
      );
    }

    if (overdueShifts.length > 0) {
      console.log(`[CRON] ${overdueShifts.length} shift(s) auto-flagged for SLA breach`);
    }
  } catch (error) {
    console.error('[CRON] Shift SLA check error:', error.message);
  }
};

/**
 * Nightly risk profiling aggregation (Phase 2 foundation — skeleton only)
 * Runs at midnight
 */
const runNightlyRiskProfiling = async () => {
  try {
    console.log('[CRON] Running nightly risk profiling...');
    // Phase 2: Aggregate checklist miss rates, hazard proximity, etc.
    // Placeholder: just log for now
    console.log('[CRON] Risk profiling complete (Phase 2 implementation pending)');
  } catch (error) {
    console.error('[CRON] Risk profiling error:', error.message);
  }
};

module.exports = { runShiftSLACheck, runNightlyRiskProfiling };
