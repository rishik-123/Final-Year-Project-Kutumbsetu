const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema({
  memberId: {
    type: String,
    required: true,
    unique: true,
    index: true,
    trim: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
    index: true,
  },
  fullName: {
    type: String,
    required: true,
    trim: true,
    index: true,
  },
  firstName: {
    type: String,
    default: '',
    trim: true,
  },
  middleName: {
    type: String,
    default: '',
    trim: true,
  },
  lastName: {
    type: String,
    default: '',
    trim: true,
  },
  maidenName: {
    type: String,
    default: '',
    trim: true,
    index: true,
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other'],
    default: 'Male',
  },
  dateOfBirth: {
    type: String,
    default: '',
  },
  phoneNumber: {
    type: String,
    default: '',
    trim: true,
  },
  email: {
    type: String,
    default: '',
    trim: true,
  },
  city: {
    type: String,
    default: '',
    trim: true,
  },
  village: {
    type: String,
    default: '',
    trim: true,
  },
  state: {
    type: String,
    default: 'Gujarat',
    trim: true,
  },
  profilePhoto: {
    type: String,
    default: '',
  },
  fatherId: {
    type: String,
    default: '',
    trim: true,
  },
  fatherName: {
    type: String,
    default: '',
    trim: true,
  },
  motherId: {
    type: String,
    default: '',
    trim: true,
  },
  motherName: {
    type: String,
    default: '',
    trim: true,
  },
  paternalGrandfatherId: {
    type: String,
    default: '',
    trim: true,
  },
  grandfather: {
    type: String,
    default: '',
    trim: true,
  },
  paternalGrandmotherId: {
    type: String,
    default: '',
    trim: true,
  },
  grandmother: {
    type: String,
    default: '',
    trim: true,
  },
  maternalGrandfatherId: {
    type: String,
    default: '',
    trim: true,
  },
  nana: {
    type: String,
    default: '',
    trim: true,
  },
  maternalGrandmotherId: {
    type: String,
    default: '',
    trim: true,
  },
  nani: {
    type: String,
    default: '',
    trim: true,
  },
  spouseId: {
    type: String,
    default: '',
    trim: true,
  },
  spouseName: {
    type: String,
    default: '',
    trim: true,
  },
  familyId: {
    type: String,
    default: '',
    trim: true,
    index: true,
  },
  relationshipToHead: {
    type: String,
    default: 'Self',
  },
  isDeceased: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Member', memberSchema);
