const mongoose = require('mongoose');
const { createProblem, sendPlanLimit, unlockedIds, MESSAGES } = require('../billing/limits');
const { maskSecret } = require('../security/secretMask');

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
 * - P20-12/13: [tool] names the CI tool for plan limits. Saving a new
 *   credential past the plan answers 403 `PLAN_LIMIT`; editing and
 *   deleting are never limited. Lists mark credentials beyond the plan
 *   `locked` (US-SUB-05) — nothing is deleted on a downgrade.
 *
 * - E4 (PE-32): no response except `secret` carries a secret. [secrets] names
 *   the secret fields, the main one first. Every other response drops
 *   them and carries `secretMask` (the main one, masked) and, for each
 *   further secret, `has<Name>` (e.g. `hasParamToken`). The decrypted
 *   values come only from GET /:id/secret: owner-only, rate-limited (the
 *   route), `Cache-Control: no-store`. The app needs them because it
 *   calls Jenkins/GitHub/SonarQube directly; the website never asks.
 *
 * Unexpected errors go to the central handler (AUD-06).
 */
function makeCredentialController(Model, fields, { tool, secrets }) {
  const [mainSecret, ...otherSecrets] = secrets;

  // The response shape of a credential: metadata and masks, never a secret.
  const present = (doc, extra = {}) => {
    const json = { ...doc.toJSON(), ...extra };
    const shown = { ...json };
    for (const name of secrets) delete shown[name];
    shown.secretMask = maskSecret(json[mainSecret]);
    for (const name of otherSecrets) {
      shown[`has${name[0].toUpperCase()}${name.slice(1)}`] = Boolean(json[name]);
    }
    return shown;
  };

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
      const [docs, unlocked] = await Promise.all([
        Model.find({ userId: req.user.id }),
        unlockedIds(req.user.id),
      ]);
      res.json(docs.map((doc) => present(doc, { locked: !unlocked.has(String(doc._id)) })));
    },

    async create(req, res) {
      const problem = await createProblem(req.user.id, tool);
      if (problem) return sendPlanLimit(res, problem.limit, problem.message);
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
      res.status(201).json(present(credential));
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
      res.json(present(credential));
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
      if (!(await unlockedIds(req.user.id)).has(String(id))) {
        return sendPlanLimit(res, 'locked', MESSAGES.locked);
      }
      await makeDefault(req.user.id, id);
      res.json(present(await Model.findById(id)));
    },

    // E4 (PE-32): the one place a decrypted secret leaves the backend.
    async secret(req, res) {
      const { id } = req.params;
      if (!mongoose.Types.ObjectId.isValid(id)) return invalidId(res);
      const credential = await Model.findOne({ _id: id, userId: req.user.id });
      if (!credential) return notFound(res);
      if (!(await unlockedIds(req.user.id)).has(String(id))) {
        return sendPlanLimit(res, 'locked', MESSAGES.locked);
      }
      const json = credential.toJSON();
      res.set('Cache-Control', 'no-store');
      res.set('Pragma', 'no-cache');
      res.json({
        ...Object.fromEntries(secrets.map((name) => [name, json[name] ?? null])),
        needsReentry: json.needsReentry,
        // Changes whenever the credential is saved, so the app can tell
        // whether the copy it stored is still current.
        version: new Date(json.updatedAt).toISOString(),
      });
    },
  };
}

module.exports = { makeCredentialController };
