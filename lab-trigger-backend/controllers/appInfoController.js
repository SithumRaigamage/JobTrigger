const AppInfo = require('../models/AppInfo');

// @desc    Get application information
// @route   GET /api/appinfo
// @access  Public
const getAppInfo = async (req, res) => {
  try {
    // We only ever expect one AppInfo document
    const info = await AppInfo.findOne();
    if (!info) {
      return res.status(404).json({ message: 'App information not found' });
    }
    res.json(info);
  } catch (error) {
    res.status(500).json({ message: 'Server error retrieving app info', error: error.message });
  }
};

module.exports = {
  getAppInfo,
};
