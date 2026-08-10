const mongoose = require('mongoose');

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
