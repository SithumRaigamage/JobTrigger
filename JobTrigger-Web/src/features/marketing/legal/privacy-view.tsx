import Link from "next/link";

import { cn } from "@/components/cn";
import { EmailLink } from "@/components/email-link";
import { Card } from "@/components/layout";
import { detail } from "@/content/site-details";

import { routes } from "../site-links";

import { LegalSection, LegalShell } from "./legal-shell";

// US-WEB-06: must match what the backend actually stores (User,
// JenkinsCredential, GitHubCredential, SonarQubeCredential,
// PasswordResetToken models), the anonymous server-side usage events of
// P20-75/77/78 (self-hosted Umami; website and backend only, the app sends
// none), and that there is still no crash reporting or ad identifier
// (backlog P6-08).
const glance = [
  {
    label: "We store",
    tone: "bg-running-bg text-running-fg",
    text: "Your email, a hashed password and your encrypted server details.",
  },
  {
    label: "We never see",
    tone: "bg-success-bg text-success-fg",
    text: "Your builds, logs or code. The app talks to your CI directly.",
  },
  {
    label: "No ad tracking",
    tone: "bg-unstable-bg text-unstable-fg",
    text: "Anonymous usage counts from the website only. No ad identifiers.",
  },
];

const toc = [
  { id: "summary", label: "At a glance" },
  { id: "collect", label: "What we store" },
  { id: "use", label: "How it's used" },
  { id: "subscriptions", label: "Subscriptions and payments" },
  { id: "student", label: "Student verification" },
  { id: "usage", label: "Anonymous usage data" },
  { id: "crash", label: "Crash reports" },
  { id: "demo", label: "Demo mode" },
  { id: "email", label: "Email" },
  { id: "delete", label: "Deleting your data" },
  { id: "contact", label: "Contact" },
];

/** Privacy policy (design 05; US-WEB-06). Draft for legal review. */
export function PrivacyView() {
  return (
    <LegalShell title="Privacy policy" current={routes.privacy} toc={toc}>
      <section id="summary" aria-label="At a glance" className="scroll-mt-24">
        <ul className="grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-3.5">
          {glance.map((item) => (
            <li key={item.label}>
              <Card flat className="flex h-full flex-col gap-2 p-5">
                <span
                  className={cn(
                    "self-start rounded-full px-2.5 py-0.75 text-xs font-bold",
                    item.tone,
                  )}
                >
                  {item.label}
                </span>
                <span className="text-[0.9375rem] leading-normal">{item.text}</span>
              </Card>
            </li>
          ))}
        </ul>
      </section>

      <p className="text-lg leading-[1.7] text-fg-secondary">
        JobTrigger is run by {detail("companyName")}. This policy explains what we keep about you
        when you use the JobTrigger app and website.
      </p>

      <LegalSection id="collect" title="What we store">
        <ul className="flex list-disc flex-col gap-2.5 pl-5.5">
          <li>
            <strong className="text-fg">Your account:</strong> your email address and a hashed
            version of your password.
          </li>
          <li>
            <strong className="text-fg">Your saved servers:</strong> names, URLs, usernames and
            tokens — tokens are encrypted before storage.
          </li>
          <li>
            <strong className="text-fg">Which server is active</strong> for each tool.
          </li>
          <li>
            <strong className="text-fg">Your plan,</strong> if you subscribe: whether you have Pro,
            its status and dates, where it was bought and which product. Never a card number.
          </li>
          <li>
            <strong className="text-fg">Student verification,</strong> only if you use the student
            plan: see Student verification below.
          </li>
          <li>
            <strong className="text-fg">A pending password reset</strong>, if you asked for one:
            only a fingerprint of the link, deleted once used or after 15 minutes.
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="use" title="How it's used">
        <p>
          Only to sign you in and hand your saved servers to your own phone. Build notifications are
          created on your phone, not sent by us. We don&apos;t sell your data, and we share it only
          with the payment services named under Subscriptions and payments.
        </p>
      </LegalSection>

      <LegalSection id="subscriptions" title="Subscriptions and payments">
        <p>
          Paying is optional. When you subscribe in the app, the App Store or Google Play takes the
          payment and tells us whether your subscription is active. We use{" "}
          <strong className="text-fg">RevenueCat</strong> to check purchases for us: it receives
          your JobTrigger account&apos;s random ID and the store receipt, and returns your plan. It
          does not receive your email address, your servers or your tokens. If you buy on this
          website, <strong className="text-fg">Paddle</strong> is the seller and collects your
          payment details and billing address; we receive your plan status and a customer reference,
          never your card number. RevenueCat and Paddle act for us as processors under their own
          privacy policies. We keep your plan record while your account exists; it is deleted with
          your account, but deleting your account does not cancel a subscription, which you cancel
          in your store or from the app.
        </p>
      </LegalSection>

      <LegalSection id="student" title="Student verification">
        <p>
          The student plan is optional and gives Pro free for one year. If you verify with a
          university email, we send a 6-digit code to that address; we keep a record that the
          address was verified, and only a one-way fingerprint of the code until it expires (10
          minutes). If you upload a student ID or enrolment letter instead, we store the file,
          encrypted, together with the full name you type as it appears on it, and the account it
          belongs to. A person reviews it on a private page of this website, and we email the site
          owner a notice with a link, never the file itself. We delete the file and the name{" "}
          <strong className="text-fg">30 days after we decide</strong>, whether we approve or reject
          it. The student plan is one free year per person: to keep that rule after the file or your
          account is gone, we keep a one-way fingerprint (a SHA-256 hash) of each university email
          and each document used for an approved year. A fingerprint cannot be turned back into the
          email or the file, and it is not linked to your account. We use the information only to
          decide whether to give you the free year.
        </p>
      </LegalSection>

      <LegalSection id="usage" title="Anonymous usage data">
        <p>
          This website and our server count a few anonymous events — for example that an account was
          created, a server was added, or a password reset was asked for — to decide what to build
          next. They never include your email, account, server addresses, repository names or
          tokens, and they aren&apos;t linked to your account. No tracking script or cookie is used
          for this: the counts are sent from our server to an analytics service we run ourselves,
          not to an advertising or analytics company. The mobile app sends no usage data.
        </p>
      </LegalSection>

      <LegalSection id="crash" title="Crash reports">
        <p>
          When the app or this website hits an unexpected error, it can send a crash report so we
          can fix the problem. A report holds the error, where in the code it happened, the app or
          site version and the type of phone or browser. It never holds passwords, tokens, what you
          typed, request contents or the address of your CI server: those are removed before a
          report leaves your device, and a report that can&apos;t be cleaned is not sent. Reports go
          to a service we run ourselves, not to an advertising or analytics company, and aren&apos;t
          linked to your email. In the app, turn this off under Profile → Privacy → Send crash
          reports; turning it off also deletes reports that were waiting to be sent.
        </p>
      </LegalSection>

      <LegalSection id="demo" title="Demo mode">
        <p>
          &ldquo;Try the demo&rdquo; on the app&apos;s sign-in screen and the{" "}
          <Link href={routes.demo}>demo page</Link> on this website show sample servers and builds
          that are built into the app and the site. They need no account, and they contact no server
          of ours or yours. In the app, the only thing kept is a setting that says the demo is on;
          it is removed when you choose Exit demo, along with the sample choices the demo made. No
          credentials are read, and nothing you tap in the demo is sent anywhere.
        </p>
      </LegalSection>

      <LegalSection id="email" title="Email">
        <p>
          We email you only about your account, such as a password reset link you asked for. A
          password is reset on this website: the link opens it, works once and expires after 15
          minutes. If you use the student plan, we also send the code that confirms your university
          email, and one reminder to your account email in the last 7 days of your free year. We
          don&apos;t send marketing email.
        </p>
      </LegalSection>

      <LegalSection id="delete" title="Deleting your data">
        <p>
          Delete your account from the app&apos;s Profile screen or from{" "}
          <Link href={routes.account}>Account</Link> on this website. Your account, every saved
          server and any student application (with its document) are removed. Only the one-way
          fingerprints described under Student verification stay. Backups keep deleted data for{" "}
          {detail("backupRetention")}.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="Contact">
        <p>
          Questions about this policy: <EmailLink field="privacyEmail" />
        </p>
      </LegalSection>
    </LegalShell>
  );
}
