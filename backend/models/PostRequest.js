const mongoose = require('mongoose');

const postRequestSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  userName: {
    type: String,
    required: true,
  },
  userPhone: {
    type: String,
    default: '',
  },
  purpose: {
    type: String, // 'General Post', 'Marriage Announcement', 'Birthday Wish', 'Samaj News / Event', 'Achievement'
    required: true,
  },
  contentType: {
    type: String, // 'post' or 'reel'
    enum: ['post', 'reel'],
    default: 'post',
  },
  description: {
    type: String,
    required: true,
  },
  mediaUrl: {
    type: String,
    default: '',
  },
  // Specific fields for marriage announcements
  brideName: {
    type: String,
    default: '',
  },
  groomName: {
    type: String,
    default: '',
  },
  weddingDate: {
    type: String,
    default: '',
  },
  venue: {
    type: String,
    default: '',
  },
  // Specific fields for birthday announcements
  birthdayPersonName: {
    type: String,
    default: '',
  },
  ageTurning: {
    type: String,
    default: '',
  },
  status: {
    type: String, // 'pending', 'approved', 'rejected'
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  adminNotes: {
    type: String,
    default: '',
  },
  publishedId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null,
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

module.exports = mongoose.model('PostRequest', postRequestSchema, 'post_requests');
