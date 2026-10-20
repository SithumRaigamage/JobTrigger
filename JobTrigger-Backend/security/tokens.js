const jwt = require('jsonwebtoken');

/**
 * AUD-26: short-lived access tokens plus a refresh token, both carrying
 * the user's `tokenVersion` (`tv`). Bumping `User.tokenVersion` (logout
 * everywhere, and in future a password change) revokes every token issued
 * before it, which a plain 7-day JWT couldn't.
 *
 * `typ` keeps the two apart: a refresh token is refused where an access
 * token is expected, and the reverse. Tokens issued before this change
 * have neither claim; they're treated as access tokens at version 0, so a
 * deploy doesn't sign anyone out and they still expire on schedule.
 */
const ACCESS_TTL = '15m';
const REFRESH_TTL = '30d';

function issueTokens(user) {
  const claims = { id: user._id.toString(), tv: user.tokenVersion ?? 0 };
  const secret = process.env.JWT_SECRET;
  return {
    token: jwt.sign({ ...claims, typ: 'access' }, secret, { expiresIn: ACCESS_TTL }),
    refreshToken: jwt.sign({ ...claims, typ: 'refresh' }, secret, { expiresIn: REFRESH_TTL }),
  };
}

/**
 * The verified payload of [token] when it's a valid token of [typ], else
 * null. Doesn't check the user; see [isCurrent].
 */
function verifyToken(token, typ) {
  if (typeof token !== 'string' || !token) return null;
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const actualTyp = payload.typ ?? 'access'; // Pre-AUD-26 tokens.
    return actualTyp === typ ? payload : null;
  } catch {
    return null;
  }
}

/** False once the user's tokenVersion has moved past the token's. */
const isCurrent = (payload, user) => (payload.tv ?? 0) === (user.tokenVersion ?? 0);

module.exports = { issueTokens, verifyToken, isCurrent, ACCESS_TTL, REFRESH_TTL };
