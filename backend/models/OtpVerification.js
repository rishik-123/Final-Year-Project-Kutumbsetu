const mongoose = require('mongoose');

const otpVerificationSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
  },
  otp: {
    type: String,
    required: true,
    trim: true,
  },
  attempts: {
    type: Number,
    default: 0,
  },
  resends: {
    type: Number,
    default: 0,
  },
  lastResentAt: {
    type: Date,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  expiresAt: {
    type: Date,
    required: true,
  },
});

// TTL index to automatically delete expired OTP entries from MongoDB
otpVerificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('OtpVerification', otpVerificationSchema, 'otp_verifications');
