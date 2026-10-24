const mongoose = require('mongoose');

/**
 * @typedef {Object} MemberSchema
 * @property {string} memberId - Unique alphanumeric Member ID (e.g., MEM001)
 * @property {mongoose.Schema.Types.ObjectId} [userId] - Reference to associated User account
 * @property {string} fullName - Full display name of the member
 * @property {string} [maidenName] - Maiden/original family surname (crucial for Gujarati samaj lineage)
 * @property {'Male'|'Female'|'Other'} gender - Member gender
 * @property {string} [fatherId] - Member ID of father for Vanshavali hierarchy
 * @property {string} [motherId] - Member ID of mother for Vanshavali hierarchy
 * @property {string} [paternalGrandfatherId] - Member ID of paternal grandfather (Dada)
 * @property {string} [paternalGrandmotherId] - Member ID of paternal grandmother (Dadi)
 * @property {string} [maternalGrandfatherId] - Member ID of maternal grandfather (Nana)
 * @property {string} [maternalGrandmotherId] - Member ID of maternal grandmother (Nani)
 * @property {string} [spouseId] - Member ID of spouse
 * @property {string} [familyId] - Unique ID grouping all members of a single household
 * @property {boolean} isDeceased - Flag indicating deceased status (for ancestor markers)
 */
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
  address: {
    type: String,
    default: '',
    trim: true,
  },
  age: {
    type: String,
    default: '',
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
  hasMatrimonialProfile: {
    type: Boolean,
    default: false,
  },
  matrimonialVisibility: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Member', memberSchema);
