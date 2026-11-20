const { teamPlanEnabled } = require('../config/env');

/** US-SUB-11 AC1: the team routes don't exist unless the plan is switched on. */
module.exports = (req, res, next) => {
  if (!teamPlanEnabled()) return res.status(404).json({ message: 'Not found' });
  next();
};
