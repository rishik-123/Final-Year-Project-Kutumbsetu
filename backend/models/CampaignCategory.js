const mongoose = require('mongoose');

const campaignCategorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  slug: {
    type: String,
    trim: true,
  },
  icon: {
    type: String,
    default: 'campaign',
  },
  description: {
    type: String,
    default: '',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('CampaignCategory', campaignCategorySchema, 'campaign_categories');
