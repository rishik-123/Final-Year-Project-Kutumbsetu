const mongoose = require('mongoose');

/**
 * @typedef {Object} MatrimonialProfileSchema
 * @property {mongoose.Schema.Types.ObjectId} userId - Reference to associated User account
 * @property {string} name - Candidate full name
 * @property {'Male'|'Female'} gender - Candidate gender
 * @property {Date} dob - Candidate date of birth
 * @property {number} heightCm - Height in centimeters
 * @property {number} weightKg - Weight in kilograms
 * @property {string} bloodGroup - Blood group
 * @property {string} maritalStatus - Marital status (Never Married, Divorced, Widowed)
 * @property {string} education - Qualification degree
 * @property {string} occupation - Current job/profession
 * @property {number} annualIncome - Annual compensation in INR
 * @property {string} village - Native village/gam
 * @property {string} city - Current residence city
 * @property {Object} familyInformation - Lineage details (Parents, Dada/Dadi, Nana/Nani)
 * @property {Object} privacySettings - Field-level privacy and contact number visibility
 * @property {boolean} isVerified - Samaj verification approval badge
 */
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
  workingCountry: {
    type: String,
    trim: true,
    default: ''
  },
  description: {
    type: String,
    trim: true,
    default: ''
  },
  partnerExpectations: {
    type: String,
    trim: true,
    default: ''
  },
  partnerExpectationsHobbies: {
    type: [String],
    default: []
  },
  additionalPhotos: {
    type: [String],
    default: []
  },
  socialLinks: {
    showSocialLinks: { type: Boolean, default: false },
    instagramUrl: { type: String, trim: true, default: '' },
    facebookUrl: { type: String, trim: true, default: '' }
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
  memberId: {
    type: String,
    trim: true,
    default: '',
    index: true,
  },
  hasMatrimonialProfile: {
    type: Boolean,
    default: true,
  },
  visibility: {
    type: Boolean,
    default: true,
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
