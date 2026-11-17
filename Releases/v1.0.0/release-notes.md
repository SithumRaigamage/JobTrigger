# Release Notes — v1.0.0

- **Version**: `1.0.0`
- **Release Date**: 2026-11-17
- **Target Branch**: `main`
- **Shipped Tools**: **Jenkins**, **SonarQube**, and **GitHub Actions** (as defined in `release/tools.json`)

---

## Highlights & New Features

### 1. Multi-Tool CI/CD Management
* **Jenkins**: Full job tree exploration, parameterised triggers, live streaming console decoder with fold navigation, queue management, node health, and build history.
* **SonarQube**: Project quality gate overview, metric trend tracking without third-party chart dependencies, security hotspot and issue triage (comment, assign, change status), and language breakdown.
* **GitHub Actions**: Repository workflow exploration, run inspection, dispatch workflows with custom branch and inputs, and step-level status tracking.

### 2. Safety & Production Protection (`PI-01`, `PI-02`)
* **Read-Only Servers**: Mark any Jenkins, GitHub, or SonarQube credential as read-only in Settings to disable destructive triggers and mutations while retaining visibility.
* **Two-Step Production Confirmation**: "Protect this job" toggle requiring exact job/workflow name entry before confirmation unlocks.

### 3. Connection Diagnostics & Remote Access Guides (`PI-03`, `PI-04`)
* **Intelligent Diagnostics**: Detects LAN/private IPs on cellular, inactive VPNs, self-signed or expired TLS certificates (`BadCertificateFailure`), and invalid host URLs.
* **In-App Remote Access Guides**: Comprehensive interactive setup guides for Tailscale, WireGuard, and Cloudflare Tunnels.

### 4. Accessibility & Data Freshness (`PI-05`, `PI-06`)
* **Data Freshness Indicators**: Explicit "Updated Xm ago" and "Offline — showing data from HH:MM" banners across all tools.
* **Non-Color Status Marks (`StatusMark`)**: Replaces color-only indicators with distinct geometric shapes and visible textual labels meeting WCAG contrast standards.

### 5. Smart Notification Rules (`PI-07`)
* **Rule-Based Watches**: Configure build watches to alert on **All**, **Failures only**, **Back to green only**, or **Main branch only**.

### 6. First-Run Onboarding & Token Wizards (`PI-08`, `PI-09`, `PI-10`)
* **First-Run Checklist**: Dismissible 3-step checklist on Home: *Connect tool* → *Trigger a build* → *Turn on alerts*.
* **Token Wizards**: In-app "How do I get a token?" guides with pre-filled scopes (`repo`, `workflow` for GitHub, `/me/configure` for Jenkins, `/account/security` for SonarQube).
* **In-App "What's New" Sheet**: Automatic release notes popup on first launch following an update.

---

## Known Limitations & Exclusions

* **GitLab CI & CircleCI**: Scheduled for Release 1.3.0 (`release/tools.json`). Not included or supported in 1.0.0.
* **Apple Watch & Localised Languages**: Planned for future milestones.
* **Billing is switched off in this release.** The app shows no
  subscription UI at all — no Profile row, Subscription screen or paywall —
  and the website's `/pricing` Pro card is a disabled *coming soon* action
  (the account page hides its plan card). Purchases and the paywall stay
  disabled until the store listings, RevenueCat keys and the backend
  `BILLING_ENABLED` flag are configured. While billing is off everyone gets
  Pro entitlements, so the Free limits (one saved server, one CI tool,
  three pinned jobs) are not applied; the Pro cap of 25 servers per tool
  still is.
* **Student plan**: built and ships dark — the verification flow is
  unreachable in 1.0 while billing is off.
* **Notifications**: build notifications are local to the phone; server
  push (NR-06b) is not enabled yet.
* **Password reset**: built but not switched on in 1.0. The reset pages
  exist, and the app's *Forgot password* opens the website's page, but the
  website's sign-in link goes to support until the feature is marked live,
  and the backend sends no email unless SMTP is configured (it still
  answers 202 and logs `mail.disabled`).
* **Website test connection**: coming in a later release (US-WEB-19 needs a
  backend endpoint).
* **Store availability**: 1.0 is not yet listed on the App Store or Google
  Play; TestFlight and Play internal testing come first.
