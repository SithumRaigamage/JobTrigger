const mongoose = require('mongoose');

/**
 * NR-06 (BACKLOG-02): one registered device for server push.
 *
 * The app registers the token its push SDK gives it; the backend sends
 * notifications to those tokens when something the user cares about happens
 * (a watched build finishing, an input step waiting). No Jenkins URL or
 * credential is stored here — the token identifies the device, `userId` the
 * account, and nothing else.
 */
const deviceTokenSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  platform: {
    type: String,
    enum: ['ios', 'android'],
    required: true
  },
  // Unique across the whole collection: a device that signs into another
  // account must not keep receiving the previous account's notifications.
  token: {
    type: String,
    required: true,
    unique: true
  },
  lastSeenAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Every send asks "which devices does this user have?".
deviceTokenSchema.index({ userId: 1 });

module.exports = mongoose.model('DeviceToken', deviceTokenSchema);
