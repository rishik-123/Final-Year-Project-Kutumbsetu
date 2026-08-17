const mongoose = require('mongoose');

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
