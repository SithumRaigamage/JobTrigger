const express = require('express');
const auth = require('../middleware/auth');
const teamOnly = require('../middleware/teamOnly');
const { credentialSecretLimiter } = require('../middleware/rateLimit');
const team = require('../controllers/teamController');

/** US-SUB-11: the team plan. 404 for everything while TEAM_PLAN_ENABLED is off. */
const router = express.Router();
router.use(teamOnly, auth);

router.get('/', team.get);
router.post('/', team.create);
router.delete('/', team.remove);
router.post('/invites', team.invite);
router.delete('/invites/:inviteId', team.cancelInvite);
router.post('/join', team.join);
router.delete('/members/:userId', team.removeMember);
router.post('/leave', team.leave);
router.put('/seats', team.setSeats);
router.post('/checkout', team.checkout);
router.get('/servers', team.listServers);
router.post('/servers', team.shareServer);
router.delete('/servers/:id', team.unshareServer);
router.get('/servers/jenkins/:id/secret', credentialSecretLimiter, team.serverSecret);

module.exports = router;
