// JobTrigger 1.0.0 release checklist data, read by release-checklist.html.
// Sources: manually/M-*.md, Releases/v1.0.0/workplan.md (tracks A–I),
// pre-release-checklist.md, deployment-instructions.md, play-store-release.md,
// post-release.md, docs/deployment-render.md, tasks/backlog.md
// ("Owner to-dos for the 1.0 go-live"). Update this file whenever a task moves
// (Releases/README.md). Ids are permanent: never reuse one.
window.CHECKLIST = {
  project: "JobTrigger",
  version: "1.0.0",
  targetDate: "not set",
  updated: "2026-11-22",
  intro: "Everything still between the code on `develop` and JobTrigger 1.0.0 in both stores. 1.0.0 ships Jenkins, SonarQube and GitHub Actions; the team plan waits for 1.0.1.",
  people: { me: "Me", claude: "Claude", both: "Me, then Claude" },
  sections: [
    // ------------------------------------------------------------------
    {
      id: "accounts",
      title: "Accounts to create",
      intro: "Accounts only you can open. Most other tasks wait for one of these.",
      tasks: [
        {
          id: "domain",
          title: "Buy the jobtrigger.app domain",
          who: "me",
          cost: "about $10–14 a year",
          must: true,
          steps: [
            "Check whether you already own `jobtrigger.app` (on 2026-11-19 it did not point anywhere). If you do, just tick this.",
            "If not, buy it at a registrar such as [Cloudflare Registrar](https://dash.cloudflare.com) or [Porkbun](https://porkbun.com).",
            "Keep the registrar login safe: you will add DNS records there later (DNS = the settings that point your domain at a server)."
          ],
          note: "`.app` domains only work over HTTPS, which the hosts below set up for you."
        },
        {
          id: "emails",
          title: "Set up the support, security and privacy email addresses",
          who: "me",
          cost: "free with email forwarding",
          must: true,
          waitsFor: ["domain"],
          steps: [
            "Pick the addresses: `support@jobtrigger.app` (the app and website already use this one), plus one for security reports and one for privacy requests.",
            "Turn on free forwarding to your own inbox, for example [Cloudflare Email Routing](https://dash.cloudflare.com) (Email → Email Routing) if the domain is on Cloudflare.",
            "Send a test email to each address and check it arrives.",
            "Tell Claude the security and privacy addresses for the website (task \"Fill in the website's legal details\")."
          ]
        },
        {
          id: "apple-dev",
          title: "Join the Apple Developer Program",
          who: "me",
          cost: "$99 a year",
          must: true,
          steps: [
            "Enrol at [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) with your Apple ID.",
            "Wait for Apple's confirmation email (can take a day or two).",
            "In Xcode, sign in with that Apple ID so it can create the iOS distribution certificate and profiles (the files that prove a build is yours)."
          ]
        },
        {
          id: "play-account",
          title: "Create a Google Play developer account",
          who: "me",
          cost: "$25 one time",
          must: true,
          steps: [
            "Sign up at [play.google.com/console/signup](https://play.google.com/console/signup) and pay the fee.",
            "Finish identity checks when Google asks (ID, and sometimes a phone).",
            "Read the testing rule for new personal accounts: before you can publish, a **closed test** must have **at least 12 testers opted in for the last 14 days in a row** ([Google's rule](https://support.google.com/googleplay/android-developer/answer/14151465)). Testers who leave early don't count; internal testing doesn't count."
          ],
          note: "This rule applies to personal accounts made after 13 November 2023. Start the closed test early: it adds at least two weeks."
        },
        {
          id: "render-account",
          title: "Create a Render account and connect GitHub",
          who: "me",
          cost: "free account",
          must: true,
          steps: [
            "Sign up at [dashboard.render.com](https://dashboard.render.com) (a Hobby workspace is enough).",
            "Connect your GitHub account and give Render access to the JobTrigger repository.",
            "Check that the **Singapore** region is offered when you create a service (closest to Sri Lanka)."
          ]
        },
        {
          id: "vercel-account",
          title: "Create a Vercel account and connect GitHub",
          who: "me",
          cost: "free (Hobby plan)",
          must: true,
          steps: [
            "Sign up at [vercel.com](https://vercel.com/signup) with GitHub.",
            "Allow Vercel to read the JobTrigger repository."
          ]
        },
        {
          id: "discord",
          title: "Create the Discord community server",
          who: "both",
          cost: "free",
          must: false,
          steps: [
            "In [Discord](https://discord.com/app), create a server with channels: announcements, help, feature-requests, jenkins, github-actions, sonarqube.",
            "Turn on Community mode, a rules screen and AutoMod (automatic filtering of spam and abuse).",
            "Make an invite link that never expires and test it from a fresh account.",
            "Send Claude the link; Claude adds it to the website's support page and the app's Support screen (one setting, with a test)."
          ],
          note: "Optional for 1.0: nothing links to Discord today (M-21)."
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "money",
      title: "Money and payments",
      intro: "Pro ships turned on in 1.0. These make buying, the free trial and restoring a purchase work for real.",
      tasks: [
        {
          id: "apple-paid",
          title: "Set up Apple payments and the Pro subscriptions",
          who: "me",
          must: true,
          waitsFor: ["apple-dev"],
          steps: [
            "In [App Store Connect](https://appstoreconnect.apple.com) → Business, sign the Paid Apps agreement and add tax and bank details (check the Sri Lanka payout details).",
            "Join the App Store Small Business Program (lower fee).",
            "Create a subscription group with the monthly and yearly Pro products; add the 7-day free trial to yearly.",
            "Product ids and prices are in `tasks/phase-20-subscriptions.md` (P20-40)."
          ]
        },
        {
          id: "play-paid",
          title: "Set up Google Play payments and the Pro subscriptions",
          who: "me",
          must: true,
          waitsFor: ["play-account"],
          steps: [
            "In [Play Console](https://play.google.com/console) → Settings → Payments profile, add your payout details.",
            "Under Monetize → Subscriptions, create Pro with monthly and yearly base plans; add the free trial to yearly.",
            "Under Setup → License testing, add your tester Google accounts (they are never charged)."
          ]
        },
        {
          id: "revenuecat",
          title: "Set up RevenueCat and get the app keys",
          who: "me",
          cost: "free under $2,500 a month in sales",
          must: true,
          waitsFor: ["apple-paid", "play-paid"],
          steps: [
            "In [RevenueCat](https://app.revenuecat.com), create the JobTrigger project and add the iOS app (`Sraig.Lab-Trigger-frontend`) and Android app (`com.sraig.jobtrigger`).",
            "Create the entitlement `pro` and the offering `default` with both products.",
            "Add the webhook to the backend with a secret, and add sandbox testers.",
            "Put the public app keys in the git-ignored `JobTrigger-Frontend/config/billing.json` and the secret key on Render (never in the repository)."
          ]
        },
        {
          id: "paddle",
          title: "Set up Paddle and check the website checkout",
          who: "me",
          cost: "5% + 50¢ per sale, nothing up front",
          must: true,
          waitsFor: ["domain"],
          steps: [
            "Create a [Paddle sandbox](https://sandbox-vendors.paddle.com) account (sandbox = test mode, no real money).",
            "Create the Pro product with monthly and yearly prices, approve the `jobtrigger.app` domain, add the webhook to `/api/billing/paddle/webhook`, and make a client-side token.",
            "Do one test purchase on `/account/billing`, then open the browser console and check there are no blocked-script errors (CSP).",
            "Repeat the setup in [live Paddle](https://vendors.paddle.com) for launch."
          ]
        },
        {
          id: "sandbox-iphone",
          title: "Test buying Pro on the iPhone with a test account",
          who: "me",
          must: true,
          waitsFor: ["revenuecat", "backend-live"],
          steps: [
            "Install with `scripts/run-on-iphone.sh` and sign in with an Apple sandbox tester.",
            "Buy Pro, check the trial, let it renew (sandbox renews in minutes), cancel.",
            "Delete and reinstall, then tap Restore purchases: Pro comes back.",
            "After it ends, check Pro-only features lock again."
          ],
          note: "P20-51; the Android half waits for an Android device (After launch)."
        },
        {
          id: "billing-on",
          title: "Check App Review rules and switch billing on in production",
          who: "both",
          must: true,
          waitsFor: ["sandbox-iphone", "paddle"],
          steps: [
            "Read Apple's current rules on linking to outside payment before any iOS screen points at the website (the app does not link to it today).",
            "Set `BILLING_ENABLED=true` on Render (already set in `render.yaml`).",
            "Claude: check the pricing page and add the changelog line (P20-62)."
          ]
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "hosting",
      title: "Hosting and deploy",
      intro: "Production backend on Render (Singapore), database on MongoDB Atlas (Singapore), website on Vercel.",
      tasks: [
        {
          id: "atlas-prod",
          title: "Create the production database on MongoDB Atlas (Singapore)",
          who: "me",
          cost: "paid tier with backups (check the Atlas pricing page)",
          must: true,
          steps: [
            "In [Atlas](https://cloud.mongodb.com), make a **new, separate project** `jobtrigger-prod`.",
            "Create a cluster in **Singapore** on a paid tier that includes backups; keep backups as long as the website promises (`backupRetention`).",
            "Add a database user `jobtrigger-prod-app` that can only read and write the JobTrigger database, with a long random password.",
            "Never allow `0.0.0.0/0` (everyone). Network access is set in \"Lock the production database to the backend only\"."
          ]
        },
        {
          id: "backend-live",
          title: "Host the backend on Render (Singapore)",
          who: "me",
          cost: "about $7 a month (Starter)",
          must: true,
          waitsFor: ["render-account", "atlas-prod"],
          steps: [
            "In the [Render dashboard](https://dashboard.render.com), choose New → Blueprint and pick this repository; it reads `render.yaml` (Docker, **Singapore**, Starter, health check `/healthz`).",
            "Fill every secret it asks for (database address, JWT secret, encryption key, mail, billing). Values stay in Render, never in the repository.",
            "Deploy, then open `https://<your-service>.onrender.com/healthz`: it should say OK.",
            "Turn on auto-deploy for `main` only, after checks pass."
          ],
          note: "`render.yaml` already sets `TEAM_PLAN_ENABLED=false` (team plan is 1.0.1)."
        },
        {
          id: "api-domain",
          title: "Point api.jobtrigger.app at the backend",
          who: "me",
          must: true,
          waitsFor: ["backend-live", "domain"],
          steps: [
            "In Render → the service → Settings → Custom Domains, add `api.jobtrigger.app`.",
            "At your registrar, add the DNS record Render shows (a CNAME: a pointer from one name to another).",
            "Wait until Render shows the certificate as issued, then open `https://api.jobtrigger.app/healthz`."
          ]
        },
        {
          id: "encrypt-key",
          title: "Store the encryption key safely and run the key check",
          who: "me",
          must: true,
          waitsFor: ["backend-live"],
          steps: [
            "Put `CREDENTIALS_ENCRYPTION_KEY` in Render's secret settings only; keep a second key id ready for rotation.",
            "Take a database backup in Atlas.",
            "In the Render Shell run `npm run encrypt-credentials -- --dry-run`, then without `--dry-run`. On a new database it reports 0.",
            "Check the startup log reports no unreadable key ids."
          ]
        },
        {
          id: "seed-appinfo",
          title: "Load the App Info links into the production database",
          who: "me",
          must: true,
          waitsFor: ["backend-live", "website-live"],
          steps: [
            "Make sure `SITE_URL=https://jobtrigger.app` is set on Render.",
            "In the Render Shell run `node scripts/seedAppInfo.js`.",
            "Open `https://api.jobtrigger.app/api/appinfo` and check the privacy, terms and release-notes links open real pages. Store review fails on a blank page."
          ]
        },
        {
          id: "website-live",
          title: "Put the website on Vercel at jobtrigger.app",
          who: "me",
          cost: "free (Hobby plan)",
          must: true,
          waitsFor: ["vercel-account", "domain"],
          steps: [
            "In [Vercel](https://vercel.com/new), import the repository with root folder `JobTrigger-Web`.",
            "Add the environment variables from `docs/deployment.md` → Website (session secret, `SITE_URL`, public keys). `JOBTRIGGER_BACKEND_URL` is set in the next task.",
            "Add the domain `jobtrigger.app` and the DNS records Vercel shows at your registrar.",
            "Open the site and check the home, pricing and changelog pages."
          ]
        },
        {
          id: "portal-backend",
          title: "Connect the website's setup portal to the live backend",
          who: "me",
          must: true,
          waitsFor: ["website-live", "api-domain"],
          steps: [
            "In Vercel → Settings → Environment Variables, set `JOBTRIGGER_BACKEND_URL=https://api.jobtrigger.app` and redeploy.",
            "Sign up on the website, add a Jenkins server there, and check it shows up in the app."
          ]
        },
        {
          id: "prod-mail",
          title: "Turn on production email (password reset, student codes)",
          who: "me",
          cost: "free tier (e.g. Resend: 3,000 emails a month)",
          must: true,
          waitsFor: ["domain", "backend-live"],
          steps: [
            "Sign up with a mail provider such as [Resend](https://resend.com) and add `jobtrigger.app`.",
            "Add the SPF, DKIM and DMARC records it shows at your registrar (DNS records that prove the mail is really from you).",
            "On Render set `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` (e.g. `JobTrigger <no-reply@jobtrigger.app>`), `RESET_PASSWORD_URL` and `STUDENT_ADMIN_EMAIL`.",
            "Send a password reset and a student email code to a real inbox."
          ],
          note: "Without this the backend answers normally but sends nothing (M-19)."
        },
        {
          id: "password-reset-decision",
          title: "Decide whether password reset is live in 1.0",
          who: "both",
          must: true,
          waitsFor: ["prod-mail"],
          steps: [
            "Decide yes or no once production mail works.",
            "Tell Claude; Claude switches the website's sign-in link from \"contact support\" to the reset page and updates the release notes if yes."
          ]
        },
        {
          id: "crash-prod",
          title: "Set up crash reporting for production (GlitchTip)",
          who: "me",
          cost: "free or small plan",
          must: false,
          waitsFor: ["backend-live"],
          steps: [
            "Create an account on [hosted GlitchTip](https://app.glitchtip.com) (the lab one on the Mac can't be reached from Render).",
            "Create three projects: app, website, backend. Copy each DSN (the address crash reports are sent to).",
            "Put the backend DSN on Render (`SENTRY_DSN`), the website one in Vercel (`NEXT_PUBLIC_SENTRY_DSN`), and the app one in the git-ignored `JobTrigger-Frontend/config/sentry.json`.",
            "Name GlitchTip in the privacy policy's crash-reports section."
          ],
          note: "Can ship without it (reports are then simply not sent), but you would be flying blind. The lab projects already exist (M-07)."
        },
        {
          id: "backups-drill",
          title: "Do a real database restore test",
          who: "me",
          must: true,
          waitsFor: ["atlas-prod"],
          steps: [
            "In Atlas → Backup, restore the latest snapshot into a new, throwaway cluster.",
            "Check the data is there and note how long it took.",
            "Delete the throwaway cluster and write the time in `Releases/v1.0.0/deployment-log.md`."
          ]
        },
        {
          id: "alerts",
          title: "Turn on production alerts",
          who: "me",
          must: false,
          waitsFor: ["backend-live"],
          steps: [
            "In Atlas → Alerts, add alerts for disk space and connection count.",
            "In Render → Notifications, turn on failed-deploy and service-down emails.",
            "Check the rate limits work behind Render's proxy (`TRUST_PROXY=1`)."
          ]
        },
        {
          id: "analytics",
          title: "Set up website analytics (Umami)",
          who: "me",
          cost: "free tier",
          must: false,
          waitsFor: ["website-live"],
          steps: [
            "Create a site at [Umami Cloud](https://cloud.umami.is) for `jobtrigger.app`.",
            "Copy the Website ID into Vercel (`UMAMI_URL`, `UMAMI_WEBSITE_ID`) and redeploy."
          ],
          note: "Cookie-free, so no cookie banner is needed."
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "stores",
      title: "App stores",
      tasks: [
        {
          id: "screenshots",
          title: "Make the store screenshots",
          who: "claude",
          must: true,
          done: true,
          steps: [
            "7 iPhone 6.9\" images (1320×2868) in `release/store-screenshots/ios-6.9/`.",
            "7 Android images (1080×2160) in `release/store-screenshots/android-2by1/` (M-05, done 2026-11-17)."
          ]
        },
        {
          id: "store-text",
          title: "Write the store text and privacy answers",
          who: "claude",
          must: true,
          done: true,
          steps: [
            "Subtitle, short and full description, screenshot captions, App Review notes and the privacy / Data safety answers are drafted in `tasks/release-checklist.md`.",
            "They name only Jenkins, GitHub Actions and SonarQube."
          ]
        },
        {
          id: "android-key",
          title: "Make the Android upload key",
          who: "me",
          must: true,
          done: true,
          steps: [
            "Done: `android/app/upload-keystore.jks` and the git-ignored `android/key.properties` exist on this Mac.",
            "Keep a backup of the keystore and its password somewhere safe outside the repository."
          ]
        },
        {
          id: "app-config",
          title: "Fill in the app's production settings",
          who: "me",
          must: true,
          waitsFor: ["api-domain", "revenuecat"],
          steps: [
            "Check `JobTrigger-Frontend/config/prod.json` points at `https://api.jobtrigger.app`.",
            "Fill the git-ignored `config/sentry.json` and `config/billing.json` (copy from the `.example.json` files).",
            "Run `scripts/build-release.sh --check all`: it must pass (on 2026-11-21 it failed because those two files had no keys)."
          ]
        },
        {
          id: "review-account",
          title: "Create the App Review test account",
          who: "me",
          must: true,
          waitsFor: ["api-domain"],
          steps: [
            "Sign up a normal account on the production backend, with no saved servers.",
            "Put its email and password only in the stores' own review fields, never in the repository."
          ]
        },
        {
          id: "appstore-listing",
          title: "Fill in the App Store listing and privacy labels",
          who: "me",
          must: true,
          waitsFor: ["apple-dev", "review-account", "website-live"],
          steps: [
            "In [App Store Connect](https://appstoreconnect.apple.com), create the app with bundle id `Sraig.Lab-Trigger-frontend`.",
            "Paste the text from `tasks/release-checklist.md`, add the line \"Try the in-app demo without an account or a server.\" and upload the 7 iPhone screenshots.",
            "Fill App Privacy (the privacy labels): Diagnostics → Crash Data: collected, not linked to the user, not used for tracking.",
            "Check `ios/Runner/PrivacyInfo.xcprivacy` still matches those answers, and paste the App Review notes and review account."
          ]
        },
        {
          id: "testflight",
          title: "Upload the iPhone build to TestFlight",
          who: "me",
          must: true,
          waitsFor: ["app-config", "appstore-listing", "version-bump"],
          steps: [
            "On the Mac: `flutter build ipa --release --dart-define-from-file=config/prod.json`.",
            "Upload with Transporter (drag the `.ipa` in) or the `xcrun altool` command in `docs/store-submission.md`.",
            "In App Store Connect → TestFlight, add the build to the internal testers group."
          ]
        },
        {
          id: "play-listing",
          title: "Fill in the Play listing and Data safety form",
          who: "me",
          must: true,
          waitsFor: ["play-account", "review-account", "website-live"],
          steps: [
            "In [Play Console](https://play.google.com/console), All apps → Create app (`com.sraig.jobtrigger`).",
            "Paste the store text and upload the 7 Android screenshots.",
            "Fill App content: Data safety form (from `tasks/release-checklist.md`), content rating, target audience, privacy policy URL."
          ]
        },
        {
          id: "play-closed-test",
          title: "Run the Play closed test: 12 testers for 14 days",
          who: "me",
          must: true,
          waitsFor: ["play-listing", "app-config", "version-bump"],
          steps: [
            "Build: `flutter build appbundle --release --dart-define-from-file=config/prod.json`.",
            "Play Console → Testing → **Closed testing** → create a track, upload the `.aab`, add a tester list with at least 12 Google accounts.",
            "Send testers the opt-in link; make sure at least 12 stay opted in for **14 days in a row** (count from the day the 12th joins).",
            "Then Dashboard → Apply for production access, and answer Google's questions about the test."
          ],
          note: "Rule for personal accounts made after 13 Nov 2023 ([Google's page](https://support.google.com/googleplay/android-developer/answer/14151465)). An internal test alone doesn't count."
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "website",
      title: "Website and legal",
      tasks: [
        {
          id: "site-details",
          title: "Fill in the website's legal details",
          who: "both",
          must: true,
          waitsFor: ["emails"],
          steps: [
            "Decide: company name (or your own name), security email, privacy email, how many days you take to reply to security reports, how long backups are kept (e.g. \"30 days\", matching Atlas), and the go-live date.",
            "Send the six values to Claude (the ones sent on 2026-11-21 were placeholders).",
            "Claude fills `JobTrigger-Web/src/content/site-details.ts`; `launch-readiness.test.ts` must then pass."
          ]
        },
        {
          id: "legal-review",
          title: "Review the privacy policy and terms",
          who: "me",
          must: true,
          waitsFor: ["site-details", "crash-prod"],
          steps: [
            "Read `/privacy` and `/terms` on the website from start to end.",
            "Check every service named is the one you really use (Render, Atlas, Vercel, GlitchTip, RevenueCat, Paddle, the mail provider).",
            "Get a legal check if you can (PE-04), then tell Claude about any change."
          ]
        },
        {
          id: "coming-soon-check",
          title: "Check every \"coming soon\" note on the site is right for 1.0",
          who: "claude",
          must: true,
          steps: [
            "Run `npm run check` and `npm run e2e` in `JobTrigger-Web` on the release branch.",
            "Check GitLab CI, CircleCI and the team plan say coming later, and no page promises push notifications.",
            "Check Paddle's script loads only on `/account/billing`."
          ]
        },
        {
          id: "store-links",
          title: "Add the store links and QR code to the website",
          who: "claude",
          must: false,
          waitsFor: ["public-release"],
          steps: [
            "Once both listings are live, send Claude the two store URLs.",
            "Claude sets `storeLinks` in `site-links.ts` and adds the QR code (a pre-built image, or a QR library with your approval)."
          ]
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "security",
      title: "Security",
      tasks: [
        {
          id: "atlas-dev-lockdown",
          title: "Lock the development database to your Mac only",
          who: "me",
          must: true,
          steps: [
            "In [Atlas](https://cloud.mongodb.com) → the dev project → Security → Network Access, **delete** the `0.0.0.0/0` entry (it lets anyone on the internet try to connect).",
            "Add IP Address → Add Current IP Address, tick \"This entry is temporary\", pick 1 week.",
            "If the backend later logs `Server selection timed out`, repeat the last step (your public address changed)."
          ],
          note: "The iPhone never talks to Atlas; only the backend on the Mac does (M-20, \"do now\")."
        },
        {
          id: "atlas-prod-lockdown",
          title: "Lock the production database to the backend only",
          who: "me",
          cost: "optional paid add-on for dedicated addresses",
          must: true,
          waitsFor: ["atlas-prod", "backend-live"],
          steps: [
            "In Render → the service → Connect → Outbound, copy the outbound IP addresses for Singapore.",
            "In Atlas → `jobtrigger-prod` → Network Access, allow only those addresses. Never `0.0.0.0/0`, never your own IP.",
            "Better, if you want it: buy Render's dedicated outbound IPs so no other Render customer shares them."
          ]
        },
        {
          id: "team-plan-off",
          title: "Keep the team plan switched off in 1.0.0",
          who: "both",
          must: true,
          waitsFor: ["backend-live"],
          steps: [
            "Done by Claude: `render.yaml` sets `TEAM_PLAN_ENABLED=false`, and a test fails if it changes.",
            "After deploying, open `https://api.jobtrigger.app/api/team` while signed in: it must answer 404 (not found).",
            "The team plan ships in 1.0.1 (`Releases/v1.0.1/`)."
          ]
        },
        {
          id: "security-scans",
          title: "Scan for leaked secrets and risky packages",
          who: "claude",
          must: true,
          done: true,
          steps: [
            "Done: gitleaks scans on every commit and the release diff; OSV and `npm audit` checks with reasoned, dated exceptions in `osv-scanner.toml` (revisit before 2027-01-31)."
          ]
        },
        {
          id: "branch-protection",
          title: "Protect the develop and main branches",
          who: "claude",
          must: false,
          done: true,
          steps: [
            "Done: required checks, admins included, no force-push or deletion, conversations must be resolved.",
            "Checks are lifted only for a merge you approve, then restored."
          ]
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "iphone",
      title: "Testing on my iPhone",
      intro: "Do these in one sitting. Install with `scripts/run-on-iphone.sh`; anything the phone connects to uses the Mac's Wi-Fi address (`ipconfig getifaddr en0`), never localhost.",
      tasks: [
        {
          id: "relaunch",
          title: "Check you stay signed in after closing the app",
          who: "me",
          must: true,
          steps: [
            "Mac: allow the terminal under System Settings → Privacy & Security → **Local Network**.",
            "Phone: sign in with **Remember my email** on.",
            "Swipe the app away, wait 2 seconds, open it again.",
            "You should land on the tool picker or Home, not the login screen. Take a screenshot (M-01)."
          ]
        },
        {
          id: "sonarqube-phone",
          title: "Check SonarQube on the phone (your server and SonarCloud)",
          who: "me",
          cost: "SonarCloud is free for public projects",
          must: true,
          steps: [
            "Add the lab SonarQube (`http://<Mac Wi-Fi address>:9000`) with your token; use a wrong token once and check you stay signed in to JobTrigger and Jenkins keeps working.",
            "Walk projects, measures, issues, quality gate and file view.",
            "Sign in to [SonarCloud](https://sonarcloud.io) with GitHub, create an organization and token, add it in the app and repeat the walk (M-03, M-04)."
          ]
        },
        {
          id: "github-phone",
          title: "Check GitHub Actions on the phone",
          who: "me",
          must: true,
          steps: [
            "Create a [fine-grained token](https://github.com/settings/personal-access-tokens/new) (a password just for one repo) with read and Actions write on a test repository.",
            "Add it in the app; use a wrong token once and check JobTrigger, Jenkins and SonarQube stay signed in.",
            "List workflows, run one with inputs, open the run, its jobs, steps and log, then the run history (M-06)."
          ],
          note: "If a blocking bug shows up, decide with Claude whether to ship 1.0 without GitHub Actions (M-17)."
        },
        {
          id: "jenkins-phone",
          title: "Check Jenkins on two different servers",
          who: "me",
          must: true,
          steps: [
            "Add two Jenkins servers set up differently (one with CSRF protection on, one off; one with folders).",
            "On each: open jobs in folders, trigger a build, watch the log and fold sections.",
            "On an inline pipeline job: History → replay icon → **Replay with edits…**, change one `echo`, replay; the new build shows your edit and \"Replayed #N\" (M-22)."
          ]
        },
        {
          id: "app-features-phone",
          title: "Check the everyday screens on the phone",
          who: "me",
          must: true,
          steps: [
            "With all three tools added: the dashboard, switching servers from each screen, and long server names in the header.",
            "Read-only mode, and the two-step confirm before anything destructive.",
            "Forms (server form, token wizard, support form): the keyboard never hides the field you are typing in."
          ]
        },
        {
          id: "support-phone",
          title: "Send a support report from the phone",
          who: "me",
          must: true,
          steps: [
            "Profile → **Support** → Bug, fill it in, keep **Attach app details** on, tap **Send report**: it says \"Report sent\".",
            "It appears under **Your reports**; App Info → **Contact support** opens the same screen.",
            "Turn on Airplane mode and try again: you see a network error and your text stays (M-18)."
          ]
        },
        {
          id: "extras-phone",
          title: "Check notifications, Face ID lock and the home-screen widget",
          who: "me",
          must: false,
          steps: [
            "Watch a build, close the app, and check the notification arrives when it finishes.",
            "Turn on the app lock and check Face ID (with passcode fallback).",
            "Add the pinned-jobs widget to the home screen and check it updates."
          ]
        },
        {
          id: "crash-test",
          title: "Send a test crash report from the phone",
          who: "me",
          must: false,
          waitsFor: ["crash-prod"],
          steps: [
            "Copy the DSNs into the three apps' `.env` files yourself (Claude never touches `.env`).",
            "Phone: Profile → Privacy → **Send test crash report**.",
            "In GlitchTip, check the event shows `token=[redacted]` and no email, user or query string (M-07)."
          ]
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "launch",
      title: "Launch day",
      tasks: [
        {
          id: "prs-merged",
          title: "Merge the finished work into develop",
          who: "claude",
          must: true,
          done: true,
          steps: [
            "Done by 2026-11-22: every open PR up to #160 merged into `develop`, with every suite green on each merged result."
          ]
        },
        {
          id: "release-branch",
          title: "Freeze the code: cut the release branch",
          who: "claude",
          must: true,
          steps: [
            "When you say go, Claude creates `release/v1.0.0` from `develop` (only bug fixes after this).",
            "Claude re-runs every suite on it and `node scripts/sync-tools.mjs --check`."
          ],
          note: "Held until you say so (your instruction, 2026-11-21)."
        },
        {
          id: "version-bump",
          title: "Set the store build number",
          who: "claude",
          must: true,
          waitsFor: ["release-branch"],
          steps: [
            "Claude sets `pubspec.yaml` to `1.0.0+N` (N goes up with every store upload).",
            "Claude updates the release notes and \"What's new\" if anything changed."
          ]
        },
        {
          id: "dogfood",
          title: "Use the test builds for a while before going public",
          who: "me",
          must: true,
          waitsFor: ["testflight", "play-closed-test"],
          steps: [
            "Install from TestFlight and the Play test, and use the app for real with the production backend.",
            "Watch the crash-free rate in GlitchTip.",
            "Tell Claude about anything odd; fixes go on the release branch before going public (M-10)."
          ]
        },
        {
          id: "public-release",
          title: "Publish in both stores",
          who: "me",
          must: true,
          waitsFor: ["dogfood", "billing-on", "seed-appinfo", "site-details"],
          steps: [
            "App Store Connect: submit the TestFlight build for review, then release it.",
            "Play Console: promote the tested build to Production with a **staged rollout** (start at 10%).",
            "Keep the old SwiftUI app archived (not deleted) for a while, in case you need to roll back (M-11)."
          ]
        },
        {
          id: "tag",
          title: "Tag v1.0.0 and merge to main",
          who: "both",
          must: true,
          waitsFor: ["public-release"],
          steps: [
            "Claude refreshes `Releases/v1.0.0/deployment-log.md` with the real commit and dates.",
            "With your approval, Claude tags `v1.0.0` and merges `release/v1.0.0` into `main` and back into `develop`."
          ]
        }
      ]
    },
    // ------------------------------------------------------------------
    {
      id: "after",
      title: "After launch",
      tasks: [
        {
          id: "smoke",
          title: "Check the live app end to end",
          who: "me",
          must: true,
          waitsFor: ["public-release"],
          steps: [
            "Install from the stores, sign up a new account, reset its password by email.",
            "Connect a real Jenkins, SonarQube and GitHub account.",
            "Check \"What's new\" shows on first launch and opens again from Profile (`post-release.md`)."
          ]
        },
        {
          id: "watch-72h",
          title: "Watch crashes for the first 3 days",
          who: "both",
          must: true,
          waitsFor: ["public-release"],
          steps: [
            "Check GlitchTip daily: keep the crash-free rate above 99.5%.",
            "Check no event contains a token, password or private header.",
            "Widen the Play rollout step by step if all is well; Claude records any hotfix in `post-release.md`."
          ]
        },
        {
          id: "conversion-review",
          title: "Review how many people choose Pro",
          who: "both",
          must: false,
          waitsFor: ["public-release"],
          steps: [
            "After about 200 views of the Pro screen, look at RevenueCat's numbers with Claude.",
            "Decide whether prices or wording should change (P20-63)."
          ]
        },
        {
          id: "android-device",
          title: "Test on a real Android phone when you have one",
          who: "me",
          must: false,
          steps: [
            "Install the build and open a very long build log (the fixture `big-log` job); check scrolling stays smooth.",
            "Do the Android test purchase with a Play license tester (M-02, P20-52)."
          ],
          note: "On hold: no Android device yet."
        }
      ]
    }
  ]
};
