const mongoose = require('mongoose');
const GitHubCredential = require('../models/GitHubCredential');

exports.getCredentials = async (req, res, next) => {
  try {
    const credentials = await GitHubCredential.find({ userId: req.user.id });
    res.json(credentials);
  } catch (err) {
    next(err);
  }
};

exports.addCredential = async (req, res, next) => {
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
      return res.status(400).json({
        message: 'Invalid credential data',
        fields: Object.keys(err.errors ?? {}),
      });
    }
    next(err);
  }
};

exports.updateCredential = async (req, res, next) => {
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
    next(err);
  }
};

exports.deleteCredential = async (req, res, next) => {
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
    next(err);
  }
};

// Set a GitHub credential as the active/default one for the user
exports.setActiveCredential = async (req, res, next) => {
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
    next(err);
  }
};
