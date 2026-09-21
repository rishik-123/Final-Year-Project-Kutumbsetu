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
    trim: true,
    default: 'Male',
  },
  dateOfBirth: {
    type: String,
    trim: true,
    default: '',
  },
  age: {
    type: String,
    trim: true,
    default: '',
  },
  phoneNumber: {
    type: String,
    trim: true,
    default: '',
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
  willingToDonateBlood: {
    type: Boolean,
    default: false,
  },
  village: {
    type: String,
    trim: true,
    default: '',
  },
  city: {
    type: String,
    trim: true,
    default: '',
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
  memberId: {
    type: String,
    trim: true,
    default: '',
    index: true,
  },
  maidenName: {
    type: String,
    trim: true,
    default: '',
  },
  fatherId: {
    type: String,
    trim: true,
    default: '',
  },
  fatherName: {
    type: String,
    trim: true,
    default: '',
  },
  motherId: {
    type: String,
    trim: true,
    default: '',
  },
  motherName: {
    type: String,
    trim: true,
    default: '',
  },
  paternalGrandfatherId: {
    type: String,
    trim: true,
    default: '',
  },
  grandfather: {
    type: String,
    trim: true,
    default: '',
  },
  paternalGrandmotherId: {
    type: String,
    trim: true,
    default: '',
  },
  grandmother: {
    type: String,
    trim: true,
    default: '',
  },
  maternalGrandfatherId: {
    type: String,
    trim: true,
    default: '',
  },
  nana: {
    type: String,
    trim: true,
    default: '',
  },
  maternalGrandmotherId: {
    type: String,
    trim: true,
    default: '',
  },
  nani: {
    type: String,
    trim: true,
    default: '',
  },
  spouseId: {
    type: String,
    trim: true,
    default: '',
  },
  spouseName: {
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
  hasMatrimonialProfile: {
    type: Boolean,
    default: false,
  },
  matrimonialVisibility: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Profile', profileSchema, 'profiles');
