// User Model — Mongoose Schema
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    uid: {
      type: String,
      required: true,
      unique: true,
      index: true,
    }, // Firebase UID
    phoneNumber: {
      type: String,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    role: {
      type: String,
      enum: ['miner', 'supervisor', 'admin'],
      required: true,
    },
    zone: {
      type: String,
      default: null,
    }, // Zone assignment (e.g., "Zone B")
    supervisorUid: {
      type: String,
      default: null,
    }, // Reference to supervisor's Firebase UID
    isActive: {
      type: Boolean,
      default: true,
    },

    // Gamification fields
    xpPoints: {
      type: Number,
      default: 0,
    },
    streak: {
      type: Number,
      default: 0,
    },
    lastChecklistDate: {
      type: Date,
      default: null,
    },
    badges: [
      {
        type: String,
      },
    ],

    // Risk profiling
    riskScore: {
      type: Number,
      default: 50,
      min: 0,
      max: 100,
    }, // 0-100: lower = safer
    riskLevel: {
      type: String,
      enum: ['green', 'amber', 'red'],
      default: 'green',
    },

    // FCM Token for push notifications
    fcmToken: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Virtual: display risk level based on score
userSchema.virtual('computedRiskLevel').get(function () {
  if (this.riskScore >= 70) return 'red';
  if (this.riskScore >= 40) return 'amber';
  return 'green';
});

module.exports = mongoose.model('User', userSchema);
