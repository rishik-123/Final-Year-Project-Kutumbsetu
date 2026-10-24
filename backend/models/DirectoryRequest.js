const mongoose = require('mongoose');

/**
 * @typedef {Object} DirectoryRequestSchema
 * @property {string} senderId - ID of member sending connection request
 * @property {string} receiverId - ID of member receiving connection request
 * @property {string} senderName - Sender full display name
 * @property {string} receiverName - Receiver full display name
 * @property {'pending'|'accepted'|'rejected'} status - Request lifecycle state
 * @property {boolean} isPendingAlertSeenByReceiver - Flag for pending request modal on receiver home screen
 * @property {boolean} isAcceptedAlertSeenBySender - Flag for accepted celebration modal on sender home screen
 * @property {Date} createdAt - Request creation timestamp
 */
const directoryRequestSchema = new mongoose.Schema({
  senderId: {
    type: String,
    required: true,
    index: true,
  },
  receiverId: {
    type: String,
    required: true,
    index: true,
  },
  senderName: {
    type: String,
    required: true,
  },
  receiverName: {
    type: String,
    required: true,
  },
  senderEmail: {
    type: String,
    default: '',
  },
  receiverEmail: {
    type: String,
    default: '',
  },
  senderOccupation: {
    type: String,
    default: '',
  },
  senderCity: {
    type: String,
    default: '',
  },
  senderPhoto: {
    type: String,
    default: '',
  },
  status: {
    type: String, // 'pending', 'accepted', 'rejected'
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending',
    index: true,
  },
  isPendingAlertSeenByReceiver: {
    type: Boolean,
    default: false,
  },
  isAcceptedAlertSeenBySender: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('DirectoryRequest', directoryRequestSchema, 'directory_requests');
