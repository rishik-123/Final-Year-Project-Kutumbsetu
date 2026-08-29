const mongoose = require('mongoose');

const communityEventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  category: {
    type: String, // 'Samuh Lagna', 'Blood Donation', 'Youth Sports Meet', 'Trust Election', 'Festival', 'General'
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
