const mongoose = require('mongoose');

/**
 * P20-11: webhook events already handled, so a retried or duplicated
 * RevenueCat delivery is applied once. Ids and types only: no receipts,
 * prices or store transaction data. Kept 180 days.
 */
const billingEventSchema = new mongoose.Schema({
  eventId: { type: String, required: true },
  type: { type: String, default: null },
  receivedAt: { type: Date, default: Date.now },
});

billingEventSchema.index({ eventId: 1 }, { unique: true });
billingEventSchema.index({ receivedAt: 1 }, { expireAfterSeconds: 180 * 24 * 60 * 60 });

module.exports = mongoose.model('BillingEvent', billingEventSchema);
