const mongoose = require('mongoose');
const GitHubCredential = require('../models/GitHubCredential');

exports.getCredentials = async (req, res) => {
  try {
    const credentials = await GitHubCredential.find({ userId: req.user.id });
    res.json(credentials);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.addCredential = async (req, res) => {
  try {
    const { label, token, defaultOwner, isDefault } = req.body;

    // If setting as default, unset others first
    if (isDefault) {
      await GitHubCredential.updateMany({ userId: req.user.id }, { isDefault: false });
    }

    const newCredential = new GitHubCredential({
      userId: req.user.id,
      label,
      token,
      defaultOwner,
      isDefault
    });

    const credential = await newCredential.save();
    res.status(201).json(credential);
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: 'Invalid credential data', error: err.message });
    }
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.updateCredential = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid credential id' });
    }

    const { label, token, defaultOwner, isDefault } = req.body;

    let credential = await GitHubCredential.findById(req.params.id);
    if (!credential) return res.status(404).json({ message: 'Credential not found' });

    // Verify ownership
    if (credential.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'User not authorized' });
    }

    // If setting as default, unset others first
    if (isDefault) {
      await GitHubCredential.updateMany({ userId: req.user.id }, { isDefault: false });
    }

    credential = await GitHubCredential.findByIdAndUpdate(
      req.params.id,
      { $set: { label, token, defaultOwner, isDefault } },
      { new: true }
    );

    res.json(credential);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.deleteCredential = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid credential id' });
    }

    const credential = await GitHubCredential.findById(req.params.id);
    if (!credential) return res.status(404).json({ message: 'Credential not found' });

    // Verify ownership
    if (credential.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'User not authorized' });
    }

    await GitHubCredential.findByIdAndDelete(req.params.id);
    res.json({ message: 'Credential removed' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Set a GitHub credential as the active/default one for the user
exports.setActiveCredential = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid credential id' });
    }
    const credential = await GitHubCredential.findById(id);
    if (!credential) return res.status(404).json({ message: 'Credential not found' });
    if (credential.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'User not authorized' });
    }
    // Unset all as default, then set this one as default
    await GitHubCredential.updateMany({ userId: req.user.id }, { isDefault: false });
    credential.isDefault = true;
    await credential.save();
    res.json(credential);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
