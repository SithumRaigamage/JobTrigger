import Link from "next/link";

import { cn } from "@/components/cn";
import { EmailLink } from "@/components/email-link";
import { Card } from "@/components/layout";
import { detail } from "@/content/site-details";

import { routes } from "../site-links";

import { LegalSection, LegalShell } from "./legal-shell";

// US-WEB-06: must match what the backend actually stores (User,
// JenkinsCredential, GitHubCredential, SonarQubeCredential models) and that
// the app has no analytics or crash reporting today (backlog P6-08).
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
    label: "No tracking",
    tone: "bg-unstable-bg text-unstable-fg",
    text: "No analytics, crash reports or ad identifiers today.",
  },
];

const toc = [
  { id: "summary", label: "At a glance" },
  { id: "collect", label: "What we store" },
  { id: "use", label: "How it's used" },
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
        </ul>
      </LegalSection>

      <LegalSection id="use" title="How it's used">
        <p>
          Only to sign you in and hand your saved servers to your own phone. Build notifications are
          created on your phone, not sent by us. We don&apos;t sell or share your data.
        </p>
      </LegalSection>

      <LegalSection id="delete" title="Deleting your data">
        <p>
          Delete your account from the app&apos;s Profile screen or from{" "}
          <Link href={routes.account}>Account</Link> on this website. Your account and every saved
          server are removed. Backups keep deleted data for {detail("backupRetention")}.
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
