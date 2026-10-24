const mongoose = require('mongoose');

/**
 * @typedef {Object} ReelSchema
 * @property {mongoose.Schema.Types.ObjectId} userId - Creator user account ID
 * @property {string} authorName - Author display name
 * @property {string} caption - Video caption description
 * @property {string} videoUrl - Video streaming asset URL
 * @property {string} [audioTrack] - Audio label or track name
 * @property {mongoose.Schema.Types.ObjectId[]} likes - Array of user IDs who liked the reel
 * @property {Object[]} comments - Comments on the reel with likes and replies
 * @property {number} sharesCount - Number of times shared
 * @property {Date} createdAt - Reel publication timestamp
 */
const reelSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  authorName: {
    type: String,
    required: true,
  },
  avatarText: {
    type: String,
    default: '',
  },
  avatarColor: {
    type: String,
    default: '#0288D1', // Peacock hex
  },
  caption: {
    type: String,
    required: true,
  },
  videoUrl: {
    type: String,
    required: true,
  },
  audioTrack: {
    type: String,
    default: 'Original Audio',
  },
  likes: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  ],
  comments: [
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
      authorName: {
        type: String,
        required: true,
      },
      content: {
        type: String,
        required: true,
      },
      likes: [
        {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        }
      ],
      replies: [
        {
          userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
          },
          authorName: {
            type: String,
            required: true,
          },
          content: {
            type: String,
            required: true,
          },
          createdAt: {
            type: Date,
            default: Date.now,
          }
        }
      ],
      createdAt: {
        type: Date,
        default: Date.now,
      },
    },
  ],
  sharesCount: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Reel', reelSchema, 'reels');
