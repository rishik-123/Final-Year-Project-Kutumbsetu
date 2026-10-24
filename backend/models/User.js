const mongoose = require('mongoose');

/**
 * @typedef {Object} UserSchema
 * @property {string} fullName - Full legal name of the community member
 * @property {string} [email] - Unique email address used for OTP authentication
 * @property {string} [phoneNumber] - Unique contact mobile number
 * @property {'user'|'admin'|'organizer'} role - Access control role within KutumbSetu
 * @property {boolean} isApproved - Admin verification status flag for platform access
 * @property {Date} createdAt - Timestamp when account was initially registered
 */
const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    index: { unique: true, sparse: true },
  },
  phoneNumber: {
    type: String,
    trim: true,
    index: { unique: true, sparse: true },
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'organizer'],
    default: 'user',
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Primary model mapped to 'users' collection for authentication & core identity
const User = mongoose.model('User', userSchema, 'users');

// Secondary directory model mapped to 'directory' collection for public searches
const DirectoryUser = mongoose.model('DirectoryUser', userSchema, 'directory');
User.DirectoryUser = DirectoryUser;

module.exports = User;
