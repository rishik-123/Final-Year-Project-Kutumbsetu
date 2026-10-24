const mongoose = require('mongoose');

/**
 * @typedef {Object} CommunityEventSchema
 * @property {string} title - Event title
 * @property {'Samuh Lagna'|'Blood Donation'|'Youth Sports Meet'|'Trust Election'|'Festival'|'General'} category - Samaj event category
 * @property {string} date - Event date string
 * @property {string} [time] - Event scheduled time
 * @property {string} location - Physical venue or address
 * @property {string} description - Comprehensive event description
 * @property {string} [bannerUrl] - Graphic banner asset URL
 * @property {number} registeredCount - Total confirmed attendees
 * @property {number} capacity - Maximum capacity threshold
 * @property {boolean} isPublishedByAdmin - Moderation and display status
 * @property {Date} createdAt - Event creation timestamp
 */
const communityEventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    default: 'General',
  },
  date: {
    type: String,
    required: true,
  },
  time: {
    type: String,
    default: '',
  },
  location: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  bannerUrl: {
    type: String,
    default: '',
  },
  registeredCount: {
    type: Number,
    default: 0,
  },
  capacity: {
    type: Number,
    default: 100,
  },
  isPublishedByAdmin: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('CommunityEvent', communityEventSchema, 'community_events');
