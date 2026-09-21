// Hazard Report Model
const mongoose = require('mongoose');

const hazardSchema = new mongoose.Schema(
  {
    reporterUid: {
      type: String,
      required: true,
      index: true,
    },
    reporterName: String,
    zone: String,
    shiftId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shift',
      default: null,
    },

    // Report content
    description: {
      type: String,
      required: true,
    },
    audioUrl: {
      type: String,
      default: null,
    }, // Firebase Storage voice recording
    photoUrl: {
      type: String,
      default: null,
    }, // Firebase Storage photo

    // GPS location
    gpsLocation: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      accuracy: Number,
    },

    // AI classification (Phase 2 - pre-set for now)
    severity: {
      type: String,
      enum: ['low', 'medium', 'critical'],
      default: 'medium',
    },
    aiAnalysis: {
      type: Object,
      default: null,
    },

    // Status tracking
    status: {
      type: String,
      enum: ['open', 'acknowledged', 'resolved', 'escalated'],
      default: 'open',
    },
    supervisorUid: {
      type: String,
      default: null,
    },
    resolvedAt: { type: Date, default: null },
    resolutionNotes: { type: String, default: null },

    // SMS notification tracking
    smsSent: { type: Boolean, default: false },
    smsSentAt: { type: Date, default: null },
    smsMessageSid: { type: String, default: null },

    // Offline sync
    localId: { type: String, default: null },
    submittedOffline: { type: Boolean, default: false },
    syncedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
  }
);

hazardSchema.index({ zone: 1, status: 1 });
hazardSchema.index({ createdAt: -1 });

module.exports = mongoose.model('HazardReport', hazardSchema);
