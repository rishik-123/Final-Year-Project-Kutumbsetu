const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
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
  phoneNumber: {
    type: String,
    required: true,
    trim: true,
  },
  profilePhoto: {
    type: String,
    trim: true,
    default: '',
  },
  bloodGroup: {
    type: String,
    trim: true,
    default: '',
  },
  village: {
    type: String,
    trim: true,
    default: '',
  },
  city: {
    type: String,
    required: true,
    trim: true,
  },
  state: {
    type: String,
    trim: true,
    default: '',
  },
  address: {
    type: String,
    trim: true,
    default: '',
  },
  qualification: {
    type: String,
    trim: true,
    default: '',
  },
  college: {
    type: String,
    trim: true,
    default: '',
  },
  profession: {
    type: String,
    trim: true,
    default: '',
  },
  fatherName: {
    type: String,
    trim: true,
    default: '',
  },
  motherName: {
    type: String,
    trim: true,
    default: '',
  },
  grandfather: {
    type: String,
    trim: true,
    default: '',
  },
  grandmother: {
    type: String,
    trim: true,
    default: '',
  },
  nana: {
    type: String,
    trim: true,
    default: '',
  },
  nani: {
    type: String,
    trim: true,
    default: '',
  },
  bio: {
    type: String,
    trim: true,
    default: '',
  },
  familyId: {
    type: String,
    trim: true,
    default: '',
  },
  relationshipToHead: {
    type: String,
    trim: true,
    default: 'Other',
  },
  familyHeadPhone: {
    type: String,
    trim: true,
    default: '',
  },
  spouseName: {
    type: String,
    trim: true,
    default: '',
  },
  isDeceased: {
    type: Boolean,
    default: false,
  },
  addedMembers: [
    {
      name: { type: String, required: true },
      relation: { type: String, required: true },
      isDeceased: { type: Boolean, default: false },
    }
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Profile', profileSchema, 'profiles');
