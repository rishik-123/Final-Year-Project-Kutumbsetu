const mongoose = require('mongoose');

/**
 * @typedef {Object} CampaignRegistrationSchema
 * @property {mongoose.Schema.Types.ObjectId} campaignId - Reference to associated Campaign
 * @property {mongoose.Schema.Types.ObjectId} userId - Reference to registering User
 * @property {string} registrationNumber - Formatted ticket ID (e.g. REG-2026-00042)
 * @property {'Participant'|'Volunteer'} participationType - Role of registrant
 * @property {number} numberOfParticipants - Headcount attending under this ticket
 * @property {string} [specialRequirements] - Dietary, medical, or accessibility notes
 * @property {string} [emergencyContactName] - Emergency contact person
 * @property {string} [emergencyContactNumber] - Emergency contact phone number
 * @property {Map<string, *>} submittedData - Responses to organizer-defined dynamic questions
 * @property {'Registered'|'Pending'|'Approved'|'Rejected'|'Cancelled'|'Attended'} registrationStatus - Status
 * @property {Date} registeredAt - Initial registration timestamp
 * @property {Date|null} cancellationTimestamp - Cancellation timestamp if revoked
 */
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
    participationType: {
      type: String,
      enum: ['Participant', 'Volunteer'],
      default: 'Participant',
    },
    numberOfParticipants: {
      type: Number,
      default: 1,
      min: 1,
    },
    specialRequirements: {
      type: String,
      trim: true,
      default: '',
    },
    emergencyContactName: {
      type: String,
      trim: true,
      default: '',
    },
    emergencyContactNumber: {
      type: String,
      trim: true,
      default: '',
    },
    heardFrom: {
      type: String,
      trim: true,
      default: 'KutumbSetu',
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
