const JenkinsCredential = require('../models/JenkinsCredential');

exports.getCredentials = async (req, res) => {
  try {
    const credentials = await JenkinsCredential.find({ userId: req.user.id });
    res.json(credentials);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.addCredential = async (req, res) => {
  try {
    const { serverName, jenkinsURL, username, password, paramToken, isDefault } = req.body;

    // If setting as default, unset others first
    if (isDefault) {
      await JenkinsCredential.updateMany({ userId: req.user.id }, { isDefault: false });
    }

    const newCredential = new JenkinsCredential({
      userId: req.user.id,
      serverName,
      jenkinsURL,
      username,
      password,
      paramToken,
      isDefault
    });

    const credential = await newCredential.save();
    res.status(201).json(credential);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.updateCredential = async (req, res) => {
  try {
    const { serverName, jenkinsURL, username, password, paramToken, isDefault } = req.body;

    // If setting as default, unset others first
    if (isDefault) {
      await JenkinsCredential.updateMany({ userId: req.user.id }, { isDefault: false });
    }

    let credential = await JenkinsCredential.findById(req.params.id);
    if (!credential) return res.status(404).json({ message: 'Credential not found' });

    // Verify ownership
    if (credential.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'User not authorized' });
    }

    credential = await JenkinsCredential.findByIdAndUpdate(
      req.params.id,
      { $set: { serverName, jenkinsURL, username, password, paramToken, isDefault } },
      { new: true }
    );

    res.json(credential);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.deleteCredential = async (req, res) => {
  try {
    const credential = await JenkinsCredential.findById(req.params.id);
    if (!credential) return res.status(404).json({ message: 'Credential not found' });

    // Verify ownership
    if (credential.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'User not authorized' });
    }

    await JenkinsCredential.findByIdAndDelete(req.params.id);
    res.json({ message: 'Credential removed' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
