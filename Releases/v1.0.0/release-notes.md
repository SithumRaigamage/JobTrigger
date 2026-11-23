# Release Notes — v1.0.0

- **Version**: `1.0.0`
- **Release Date**: TBD (store review and production deployment pending)
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

### 7. Support & Account Safety
* **Support requests**: Send a redacted diagnostic report from the app and
  follow its status under Support → Your reports.
* **Credential context**: Each tool screen shows its active server/account
  and lets you switch without losing your place.

### 8. Promo codes and student review
* **Promo and voucher codes**: redeem a configured code in the app or on the
  website for Pro time, or use a checkout discount on the website. A local
  reminder warns three days before a promo grant ends (US-PROMO-01…06).
* **Student applications are approved by hand**: confirming a university
  code verifies the email but no longer grants Pro by itself. A super admin
  approves or rejects each application in the app or on the website
  (US-STU-01…03).

### 9. Privacy
* **Personal data is encrypted at rest** (NFR-SEC-08): emails, names, URLs
  and credentials are encrypted with keyed hashes for exact lookups. Admin
  account search is therefore exact-email only, with no partial or name
  search. Existing data is backfilled with the first production deploy.

---

## Known Limitations & Exclusions

* **GitLab CI & CircleCI**: Scheduled for Release 1.3.0 (`release/tools.json`). Not included or supported in 1.0.0.
* **Apple Watch & Localised Languages**: Planned for future milestones.
* **Billing is enabled in this release.** Free is the default for every new
  account; Pro is a paid subscription via the App Store / Google Play
  (RevenueCat) or the website (Paddle). Prices: **$9.99/month** or
  **$29.99/year** with a 7-day free trial on the yearly plan. The owner
  account (`developer@jobtrigger.app`) has a permanent Pro grant and is
  never billed. Free limits (one saved server, one CI tool, three pinned
  jobs) apply to unpaid accounts; on cancellation or downgrade Pro stays
  active until the paid period ends, then locks (never deletes) excess
  servers. Publishing requires the store products, the public RevenueCat
  keys and backend `BILLING_ENABLED=true` with the secret key + webhook auth.
* **Student plan**: built and ships with billing; the verification flow is
  available to free users.
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
