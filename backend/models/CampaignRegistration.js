const mongoose = require('mongoose');

const campaignRegistrationSchema = new mongoose.Schema(
  {
    campaignId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
      required: [true, 'Campaign ID is required'],
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
    },
    registrationNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    submittedData: {
      type: Map,
      of: mongoose.Schema.Types.Mixed,
      default: {},
    },
    registrationStatus: {
      type: String,
      enum: ['Registered', 'Pending', 'Approved', 'Rejected', 'Cancelled', 'Attended'],
      default: 'Registered',
    },
    registeredAt: {
      type: Date,
      default: Date.now,
    },
    cancellationTimestamp: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to quickly query registrations by campaign and user
campaignRegistrationSchema.index({ campaignId: 1, userId: 1 });

module.exports = mongoose.model('CampaignRegistration', campaignRegistrationSchema, 'campaign_registrations');
