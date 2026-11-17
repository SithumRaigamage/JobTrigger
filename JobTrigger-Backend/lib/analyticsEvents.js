/**
 * P20-75: the backend's part of the analytics event catalogue
 * (docs/subscription/04-email-and-analytics.md §4.1). Only these names are
 * sent; anything else is dropped and logged, so a typo can't create a new
 * event in Umami and nobody can pass personal data as an event name.
 */
module.exports = Object.freeze([
  'password_reset_requested',
  'password_reset_completed',
  'trial_started',
  'subscription_renewed',
  'subscription_expired',
  'refund',
]);
