const mongoose = require('mongoose');

/**
 * @typedef {Object} CounterSchema
 * @property {string} id - Identifier of the sequence (e.g. 'registrationNumber', 'memberSeq')
 * @property {number} seq - Atomic sequence integer counter
 */
const counterSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
  },
  seq: {
    type: Number,
    default: 0,
  },
});

module.exports = mongoose.model('Counter', counterSchema);
