# Design note — US-WEB-19 Test connection from the website

Story: `docs/user-stories/web/17-website.md` (US-WEB-19). **Status: decision
needed from the owner. Nothing is built beyond the launch state.**

## The problem

A browser can't call a user's Jenkins, GitHub or SonarQube (CORS, and the
token would sit in the page). Testing from the website therefore means the
**backend** makes an outbound request to an address the user typed in. That
is server-side request forgery (SSRF) surface: on Render the backend could be
pointed at internal addresses or cloud metadata. And most Jenkins servers sit
on office networks or VPNs the cloud can never reach, so even a safe endpoint
would often answer "can't reach".

## Today (launch state, already built)

`web-test-connection` is `soon`: the button shows disabled with a "Coming
soon" badge and "You can test from the app after saving"; saving works.
That is the story's first scenario, and it is ticked.

## Options

### (a) Defer to 1.1
Keep the launch state for 1.0; revisit with real usage data (how many saves
are followed by a failed first connection in the app).
- Cost: none now. Risk: none.

### (b) Build with SSRF guards
`POST /api/credentials/test` (auth, rate-limited), never storing anything:
- https only; port 443 or an explicit allow-list (8443, 8080 over https).
- Resolve DNS **once**, reject if **any** resolved address is private
  (10/8, 172.16/12, 192.168/16, fc00::/7), loopback (127/8, ::1),
  link-local (169.254/16, fe80::/10, incl. 169.254.169.254 metadata),
  CGNAT 100.64/10, 0.0.0.0/8, multicast or reserved; then connect to that
  resolved IP (pinned, with the hostname as SNI/Host) so DNS rebinding
  can't swap it.
- No redirects (a 3xx is reported, not followed); 5 s connect / 8 s total
  timeout; response body capped (64 KB), never echoed back.
- Only the tool's own "who am I" path: Jenkins `/me/api/json`, GitHub
  `/user`, SonarQube `/api/authentication/validate` — no user-supplied path.
- Rate limit per user (e.g. 10 per 10 min) and per IP; log host only, never
  the token or full URL.
- Answers map to the app's copy (Auth, Network, NotFound, Server(status)),
  plus the "private network" message when the address is blocked or
  unreachable.
- Layers: backend endpoint + guard module + tests (blocked ranges, rebinding,
  redirects, timeouts); website button, states and copy; app unchanged.
- Cost: about 2–3 days with tests, plus a security review (it joins P20-53's
  scope). Value is limited for private-network Jenkins.

### (c) The website explains that testing happens in the app
Replace the disabled "Coming soon" button with a short explainer: "Your
phone tests the connection: after saving, open the app on the same network
and tap Test connection." Mark the story's success/failure scenarios
won't-do for the website.
- Cost: half a day (copy, feature-status, tests). Risk: none.

## Recommendation

**(c) for 1.0, and (a) for (b).** Ship the honest explainer now, because it
removes a "Coming soon" button that may never come. Revisit (b) in 1.1 only if
support tickets show people saving servers with typos; when built, build it
exactly as described in (b), never without the DNS-pinning and redirect rules.
