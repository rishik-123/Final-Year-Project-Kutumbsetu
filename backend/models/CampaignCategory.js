const mongoose = require('mongoose');

/**
 * @typedef {Object} CampaignCategorySchema
 * @property {string} name - Display category name (e.g. Health Camp, Education, Cultural, Disaster Relief)
 * @property {string} [slug] - URL-friendly lowercase identifier
 * @property {string} [icon] - Material icon name for UI rendering
 * @property {string} [description] - Scope description for the category
 * @property {boolean} isActive - Active flag for category selector display
 * @property {Date} createdAt - Timestamp of category creation
 */
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
