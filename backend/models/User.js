const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    trim: true,
  },
  surname: {
    type: String,
    trim: true,
  },
  fatherName: {
    type: String,
    trim: true,
  },
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  gender: {
    type: String,
    required: true,
    trim: true,
  },
  dateOfBirth: {
    type: String,
    required: true,
    trim: true,
  },
  nativePlace: {
    type: String,
    trim: true,
  },
  address: {
    type: String,
    trim: true,
  },
  city: {
    type: String,
    required: true,
    trim: true,
  },
  state: {
    type: String,
    trim: true,
  },
  maritalStatus: {
    type: String,
    trim: true,
  },
  occupation: {
    type: String,
    default: '',
    trim: true,
  },
  education: {
    type: String,
    default: '',
    trim: true,
  },
  bloodGroup: {
    type: String,
    default: '',
    trim: true,
  },
  familyId: {
    type: String,
    trim: true,
  },
  familyName: {
    type: String,
    trim: true,
  },
  relationshipToHead: {
    type: String,
    trim: true,
  },
  motherName: {
    type: String,
    trim: true,
  },
  spouseName: {
    type: String,
    trim: true,
  },
  familyHeadPhone: {
    type: String,
    trim: true,
  },
  profilePhoto: {
    type: String,
    trim: true,
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
