const mongoose = require('mongoose');

/**
 * AUD-31: one implementation of the credential CRUD that the Jenkins,
 * GitHub, and SonarQube controllers used to copy. [fields] are the
 * user-editable fields besides `isDefault`.
 *
 * - AUD-24: every lookup is scoped to `{ _id, userId }`, so another user's
 *   id is indistinguishable from a missing one: 404, never 401 (which
 *   confirmed the id existed and could read to the client as "session
 *   expired").
 * - AUD-23: updates run the schema validators, so a PUT can't blank a
 *   required field; `updatedAt` comes from the schemas' `timestamps`.
 * - AUD-24: switching the default is one ordered `bulkWrite` (unset all,
 *   then set one): a single round trip instead of two separate requests.
 *
 * Unexpected errors go to the central handler (AUD-06).
 */
function makeCredentialController(Model, fields) {
  // Only the fields the client sent; absent ones stay unchanged on update.
  const pick = (body) =>
    Object.fromEntries(
      fields.filter((f) => body[f] !== undefined).map((f) => [f, body[f]]),
    );

  const invalidId = (res) =>
    res.status(400).json({ message: 'Invalid credential id' });
  const notFound = (res) =>
    res.status(404).json({ message: 'Credential not found' });

  // Makes [id] the user's only default.
  const makeDefault = (userId, id) =>
    Model.bulkWrite(
      [
        { updateMany: { filter: { userId }, update: { $set: { isDefault: false } } } },
        { updateOne: { filter: { _id: id, userId }, update: { $set: { isDefault: true } } } },
      ],
      { ordered: true },
    );

  return {
    async list(req, res) {
      res.json(await Model.find({ userId: req.user.id }));
    },

    async create(req, res) {
      const credential = new Model({
        ...pick(req.body ?? {}),
        userId: req.user.id,
        isDefault: false,
      });
      try {
        await credential.save();
      } catch (err) {
        if (err.name !== 'ValidationError') throw err;
        return res.status(400).json({
          message: 'Invalid credential data',
          fields: Object.keys(err.errors ?? {}),
        });
      }
      if (req.body?.isDefault === true) {
        await makeDefault(req.user.id, credential._id);
        credential.isDefault = true;
      }
      res.status(201).json(credential);
    },

    async update(req, res) {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) return invalidId(res);
      const body = req.body ?? {};

      let credential;
      try {
        credential = await Model.findOneAndUpdate(
          { _id: id, userId: req.user.id },
          {
            $set: {
              ...pick(body),
              // Turning the default off is a plain field update; turning it
              // on goes through makeDefault below.
              ...(body.isDefault === false ? { isDefault: false } : {}),
            },
          },
          { returnDocument: 'after', runValidators: true },
        );
      } catch (err) {
        if (err.name !== 'ValidationError') throw err;
        return res.status(400).json({
          message: 'Invalid credential data',
          fields: Object.keys(err.errors ?? {}),
        });
      }
      if (!credential) return notFound(res);

      // Always re-run, which also repairs any legacy duplicate defaults.
      if (body.isDefault === true) {
        await makeDefault(req.user.id, credential._id);
        credential.isDefault = true;
      }
      res.json(credential);
    },

    async remove(req, res) {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) return invalidId(res);
      const deleted = await Model.findOneAndDelete({ _id: id, userId: req.user.id });
      if (!deleted) return notFound(res);
      res.json({ message: 'Credential removed' });
    },

    async setDefault(req, res) {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) return invalidId(res);
      const exists = await Model.exists({ _id: id, userId: req.user.id });
      if (!exists) return notFound(res);
      await makeDefault(req.user.id, id);
      res.json(await Model.findById(id));
    },
  };
}

module.exports = { makeCredentialController };
