const express = require('express');
const router = express.Router();
const { getAppInfo } = require('../controllers/appInfoController');

router.get('/', getAppInfo);

module.exports = router;
