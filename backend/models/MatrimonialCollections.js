const mongoose = require('mongoose');

// Schema for interest/connection requests
const matrimonialRequestSchema = new mongoose.Schema({
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  receiverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['Pending', 'Accepted', 'Rejected'],
    default: 'Pending'
  },
  createdDate: {
    type: Date,
    default: Date.now
  }
});

// Compound index to prevent duplicate pending request objects
matrimonialRequestSchema.index({ senderId: 1, receiverId: 1 }, { unique: true });

// Schema for user shortlists
const matrimonialShortlistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  shortlistedUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdDate: {
    type: Date,
    default: Date.now
  }
});

matrimonialShortlistSchema.index({ userId: 1, shortlistedUserId: 1 }, { unique: true });

// Schema for marriage meetups, Samuh Lagna events
const matrimonialEventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: ''
  }
});

// Schema for community success stories
const successStorySchema = new mongoose.Schema({
  coupleName: {
    type: String,
    required: true
  },
  marriageDate: {
    type: Date,
    required: true
  },
  photo: {
    type: String,
    default: ''
  },
  description: {
    type: String,
    default: ''
  }
});

module.exports = {
  MatrimonialRequest: mongoose.model('MatrimonialRequest', matrimonialRequestSchema, 'matrimonial_requests'),
  MatrimonialShortlist: mongoose.model('MatrimonialShortlist', matrimonialShortlistSchema, 'matrimonial_shortlists'),
  MatrimonialEvent: mongoose.model('MatrimonialEvent', matrimonialEventSchema, 'matrimonial_events'),
  SuccessStory: mongoose.model('SuccessStory', successStorySchema, 'matrimonial_success_stories')
};
