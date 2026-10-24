const mongoose = require('mongoose');

/**
 * @typedef {Object} PostSchema
 * @property {mongoose.Schema.Types.ObjectId} userId - Author member user ID
 * @property {string} authorName - Display name of post creator
 * @property {string} [avatarText] - Initials for circular avatar
 * @property {string} content - Post body text / announcement
 * @property {string} [mediaUrl] - Image attachment URL or base64 storage path
 * @property {mongoose.Schema.Types.ObjectId[]} likes - Array of user IDs who liked the post
 * @property {Object[]} comments - Threaded comments with likes and replies
 * @property {number} sharesCount - Count of shares across external apps
 * @property {Date} createdAt - Timestamp of post publication
 */
const postSchema = new mongoose.Schema({
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
    default: '#F57C00', // Saffron hex
  },
  content: {
    type: String,
    required: true,
  },
  mediaUrl: {
    type: String,
    default: '',
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

module.exports = mongoose.model('Post', postSchema, 'posts');
