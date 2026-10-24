const mongoose = require('mongoose');

/**
 * @typedef {Object} DynamicFieldSchema
 * @property {string} fieldName - Technical identifier for the custom field
 * @property {string} label - Human-readable label displayed on the signup form
 * @property {'text'|'number'|'dropdown'|'radio'|'checkbox'|'date'} type - Input widget type
 * @property {boolean} required - Mandatory input flag
 * @property {string[]} [options] - Options list for dropdown/radio/checkbox
 * @property {number} order - Ordering index in the form layout
 */
const dynamicFieldSchema = new mongoose.Schema({
  fieldName: { type: String, required: true, trim: true },
  label: { type: String, required: true, trim: true },
  type: {
    type: String,
    enum: ['text', 'number', 'dropdown', 'radio', 'checkbox', 'date'],
    default: 'text',
  },
  required: { type: Boolean, default: false },
  options: [{ type: String, trim: true }],
  validationRules: { type: String, default: '' },
  order: { type: Number, default: 0 },
});

/**
 * @typedef {Object} CampaignSchema
 * @property {string} title - Title of the campaign or event
 * @property {string} description - Detailed objective and instructions
 * @property {string} category - Category tag (e.g. Health, Education, Cultural, Relief)
 * @property {'Draft'|'Upcoming'|'Active'|'Completed'|'Cancelled'} status - Lifecycle status
 * @property {number} targetAmount - Target fundraising goal (if applicable)
 * @property {number} amountRaised - Accumulated donations
 * @property {DynamicFieldSchema[]} dynamicFields - Custom signup questions designed by organizers
 */
const campaignSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Campaign title is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Campaign description is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Campaign category is required'],
      trim: true,
    },
    bannerUrl: {
      type: String,
      default: '',
      trim: true,
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    status: {
      type: String,
      enum: ['Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled'],
      default: 'Active',
    },
    targetAmount: {
      type: Number,
      default: 0,
      min: [0, 'Target amount cannot be negative'],
    },
    amountRaised: {
      type: Number,
      default: 0,
      min: [0, 'Amount raised cannot be negative'],
    },
    objective: {
      type: String,
      default: '',
      trim: true,
    },
    contactInfo: {
      phone: { type: String, default: '', trim: true },
      email: { type: String, default: '', trim: true },
      organizerName: { type: String, default: '', trim: true },
    },
    additionalNotes: {
      type: String,
      default: '',
      trim: true,
    },
    location: {
      type: String,
      default: '',
      trim: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false,
    },
    dynamicFields: [dynamicFieldSchema],
  },
  {
    timestamps: true,
  }
);

// Virtual property to dynamically compute effective status if not set to Cancelled or Draft
campaignSchema.methods.getEffectiveStatus = function () {
  if (this.status === 'Cancelled' || this.status === 'Draft') {
    return this.status;
  }
  const now = new Date();
  if (this.startDate > now) {
    return 'Upcoming';
  } else if (this.endDate < now) {
    return 'Completed';
  } else {
    return 'Active';
  }
};

module.exports = mongoose.model('Campaign', campaignSchema, 'campaigns');
