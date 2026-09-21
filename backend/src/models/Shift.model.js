// Shift Model — Supervisor shift windows
const mongoose = require('mongoose');

const shiftSchema = new mongoose.Schema(
  {
    supervisorUid: {
      type: String,
      required: true,
      index: true,
    },
    supervisorName: String,
    zone: {
      type: String,
      required: true,
    },

    // Shift timing
    shiftDate: {
      type: Date,
      required: true,
      index: true,
    },
    openedAt: {
      type: Date,
      default: null,
    }, // When supervisor opened the shift
    closedAt: {
      type: Date,
      default: null,
    },
    expectedOpenTime: {
      type: Date,
      required: true,
    }, // Scheduled start time

    status: {
      type: String,
      enum: ['pending', 'open', 'closed', 'auto_flagged'],
      default: 'pending',
    },

    // SLA tracking
    slaBreached: {
      type: Boolean,
      default: false,
    }, // True if supervisor didn't open in 30 min
    slaBreachedAt: {
      type: Date,
      default: null,
    },
    minerScoresProtected: {
      type: Boolean,
      default: false,
    }, // If sla breached, miners aren't penalized

    // Stats
    totalMiners: { type: Number, default: 0 },
    checkinsCount: { type: Number, default: 0 },
    hazardsCount: { type: Number, default: 0 },
  },
  {
    timestamps: true,
  }
);

shiftSchema.index({ supervisorUid: 1, shiftDate: -1 });
shiftSchema.index({ zone: 1, status: 1 });

module.exports = mongoose.model('Shift', shiftSchema);
