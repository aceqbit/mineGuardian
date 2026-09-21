// AuditLog Model — Every action timestamped (for Phase 2 audit log, seeded now)
const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    actorUid: { type: String, required: true, index: true },
    actorName: String,
    actorRole: { type: String, enum: ['miner', 'supervisor', 'admin', 'system'] },
    action: {
      type: String,
      required: true,
    }, // e.g., 'checklist.submit', 'hazard.report', 'shift.open'
    entityType: String, // 'checklist', 'hazard', 'shift', 'user'
    entityId: String, // MongoDB ObjectId as string
    metadata: { type: Object, default: {} },
    ipAddress: { type: String, default: null },
  },
  {
    timestamps: true,
  }
);

auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ actorUid: 1, createdAt: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
