const mongoose = require('mongoose');

/**
 * @typedef {Object} NotificationSchema
 * @property {mongoose.Schema.Types.ObjectId|null} [userId] - Recipient user ID (null for broadcast to all samaj members)
 * @property {string} title - Notification alert header
 * @property {string} message - Notification message body
 * @property {'CAMPAIGN_ANNOUNCEMENT'|'CAMPAIGN_ACTIVE'|'CAMPAIGN_COMPLETED'|'REGISTRATION_CONFIRMATION'|'REGISTRATION_CANCELLED'|'SYSTEM'} type - Category
 * @property {string} [referenceId] - Associated entity ID for deep linking
 * @property {boolean} isRead - Read status indicator
 * @property {Date} createdAt - Notification dispatch timestamp
 */
const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null, // null means broadcast to all users
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  message: {
    type: String,
    required: true,
    trim: true,
  },
  type: {
    type: String,
    enum: [
      'CAMPAIGN_ANNOUNCEMENT',
      'CAMPAIGN_ACTIVE',
      'CAMPAIGN_COMPLETED',
      'REGISTRATION_CONFIRMATION',
      'REGISTRATION_CANCELLED',
      'SYSTEM',
    ],
    default: 'SYSTEM',
  },
  referenceId: {
    type: String,
    default: '',
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Notification', notificationSchema, 'notifications');
