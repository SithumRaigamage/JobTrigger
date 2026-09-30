const AppInfo = require('../models/AppInfo');

// @desc    Get application information
// @route   GET /api/appinfo
// @access  Public
const getAppInfo = async (req, res, next) => {
  try {
    // We only ever expect one AppInfo document
    const info = await AppInfo.findOne();
    if (!info) {
      return res.status(404).json({ message: 'App information not found' });
    }
    res.json(info);
  } catch (error) {
    next(error); // AUD-06: logged server-side, generic body to the client.
  }
};

module.exports = {
  getAppInfo,
};
