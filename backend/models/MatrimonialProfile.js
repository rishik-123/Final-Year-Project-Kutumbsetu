const mongoose = require('mongoose');

const matrimonialProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  gender: {
    type: String,
    required: true,
    trim: true
  },
  dob: {
    type: Date,
    required: true
  },
  heightCm: {
    type: Number,
    required: true
  },
  weightKg: {
    type: Number,
    required: true
  },
  bloodGroup: {
    type: String,
    trim: true
  },
  maritalStatus: {
    type: String,
    trim: true
  },
  education: {
    type: String,
    trim: true
  },
  occupation: {
    type: String,
    trim: true
  },
  company: {
    type: String,
    trim: true
  },
  annualIncome: {
    type: Number,
    default: 0
  },
  village: {
    type: String,
    trim: true
  },
  city: {
    type: String,
    trim: true
  },
  familyInformation: {
    fatherName: { type: String, trim: true, default: '' },
    motherName: { type: String, trim: true, default: '' },
    grandfather: { type: String, trim: true, default: '' },
    grandmother: { type: String, trim: true, default: '' },
    nana: { type: String, trim: true, default: '' },
    nani: { type: String, trim: true, default: '' },
    familyOccupation: { type: String, trim: true, default: '' }
  },
  lifestyle: {
    languages: { type: [String], default: [] },
    hobbies: { type: [String], default: [] },
    diet: { type: String, trim: true, default: 'Vegetarian' },
    smoking: { type: String, trim: true, default: 'No' },
    drinking: { type: String, trim: true, default: 'No' }
  },
  partnerPreferences: {
    ageMin: { type: Number, default: 18 },
    ageMax: { type: Number, default: 60 },
    heightMin: { type: Number, default: 120 },
    heightMax: { type: Number, default: 220 },
    education: { type: String, trim: true, default: '' },
    occupation: { type: String, trim: true, default: '' },
    city: { type: String, trim: true, default: '' },
    village: { type: String, trim: true, default: '' }
  },
  visibilitySettings: {
    showPhone: { type: Boolean, default: false },
    showAddress: { type: Boolean, default: false },
    showEmail: { type: Boolean, default: false }
  },
  profilePhoto: {
    type: String,
    trim: true,
    default: ''
  },
  introductionVideo: {
    type: String,
    trim: true,
    default: ''
  },
  profileStatus: {
    type: String,
    enum: ['Pending', 'Approved', 'Rejected'],
    default: 'Approved'
  },
  createdDate: {
    type: Date,
    default: Date.now
  },
  updatedDate: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('MatrimonialProfile', matrimonialProfileSchema, 'matrimonial_profiles');
