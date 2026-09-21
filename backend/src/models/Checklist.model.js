// Checklist Submission Model
const mongoose = require('mongoose');

const checklistItemSchema = new mongoose.Schema({
  questionId: String,
  question: String,
  answer: Boolean,
  notes: { type: String, default: null },
});

const checklistSchema = new mongoose.Schema(
  {
    minerUid: {
      type: String,
      required: true,
      index: true,
    },
    minerName: String,
    zone: String,
    shiftId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shift',
      required: true,
    },
    date: {
      type: Date,
      required: true,
      index: true,
    },
    items: [checklistItemSchema],
    photoUrl: {
      type: String,
      default: null,
    },
    gpsLocation: {
      latitude: Number,
      longitude: Number,
      accuracy: Number,
    },
    isGpsValid: {
      type: Boolean,
      default: false,
    }, // Was GPS within zone boundary?
    xpAwarded: {
      type: Number,
      default: 50,
    },
    streakDay: Number,
    status: {
      type: String,
      enum: ['submitted', 'verified', 'flagged'],
      default: 'submitted',
    },
    supervisorUid: String,
    verifiedAt: { type: Date, default: null },
    // For offline-first: local SQLite ID
    localId: { type: String, default: null },
  },
  {
    timestamps: true,
  }
);

// Compound index for unique daily submission
checklistSchema.index({ minerUid: 1, date: 1 }, { unique: false });

module.exports = mongoose.model('Checklist', checklistSchema);
