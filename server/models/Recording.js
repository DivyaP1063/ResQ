const mongoose = require('mongoose');

const recordingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  filename: {
    type: String,
    required: true
  },
  originalName: {
    type: String,
    required: true
  },
  filePath: {
    type: String,
    required: true
  },
  duration: {
    type: Number, // Duration in seconds
    default: 0
  },
  transcription: {
    type: String,
    default: ''
  },
  isEmergency: {
    type: Boolean,
    default: false
  },
  emergencyType: {
    type: String,
    enum: ['help', 'medical', 'fire', 'police', 'accident', 'other'],
    default: null
  },
  confidence: {
    type: Number,
    min: 0,
    max: 1,
    default: 0
  },
  keywords: [{
    type: String
  }],
  status: {
    type: String,
    enum: ['processing', 'completed', 'failed'],
    default: 'processing'
  },
  assemblyAiId: {
    type: String,
    default: null
  },
  metadata: {
    fileSize: Number,
    mimeType: String,
    sampleRate: Number
  }
}, {
  timestamps: true
});

// Index for better query performance
recordingSchema.index({ userId: 1, createdAt: -1 });
recordingSchema.index({ isEmergency: 1, createdAt: -1 });

module.exports = mongoose.model('Recording', recordingSchema);