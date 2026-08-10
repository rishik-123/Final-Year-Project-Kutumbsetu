const mongoose = require('mongoose');

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
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const User = mongoose.model('User', userSchema, 'users');
const DirectoryUser = mongoose.model('DirectoryUser', userSchema, 'directory');
User.DirectoryUser = DirectoryUser;

module.exports = User;
