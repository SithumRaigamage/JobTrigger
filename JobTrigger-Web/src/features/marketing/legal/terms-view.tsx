import Link from "next/link";

import { EmailLink } from "@/components/email-link";
import { detail } from "@/content/site-details";

import { routes } from "../site-links";

import { LegalSection, LegalShell } from "./legal-shell";

const toc = [
  { id: "service", label: "The service" },
  { id: "account", label: "Your account" },
  { id: "tokens", label: "Your servers and tokens" },
  { id: "subscriptions", label: "Subscriptions" },
  { id: "availability", label: "Availability" },
  { id: "changes", label: "Changes" },
  { id: "contact", label: "Contact" },
];

/**
 * Terms of use (US-WEB-06). No approved design or text exists: this uses
 * the privacy page's layout and a plain draft, marked for legal review like
 * the privacy policy. Every statement matches how the product works today.
 */
export function TermsView() {
  return (
    <LegalShell title="Terms of use" current={routes.terms} toc={toc}>
      <p className="text-lg leading-[1.7] text-fg-secondary">
        These terms cover your use of the JobTrigger app and website, provided by{" "}
        {detail("companyName")}. Our <Link href={routes.privacy}>privacy policy</Link> explains what
        we store.
      </p>

      <LegalSection id="service" title="The service">
        <p>
          JobTrigger lets you trigger and follow builds on CI servers you already use. The app talks
          to your CI servers directly; this website only stores the server details you save to your
          account.
        </p>
      </LegalSection>

      <LegalSection id="account" title="Your account">
        <p>
          Keep your password to yourself and sign out on shared computers. You can delete your
          account at any time from the app or from <Link href={routes.account}>Account</Link>.
        </p>
      </LegalSection>

      <LegalSection id="tokens" title="Your servers and tokens">
        <p>
          Only save servers and tokens you are allowed to use. JobTrigger can do only what your
          tokens allow, so give it the smallest token you can — see{" "}
          <Link href={routes.security}>Security</Link>.
        </p>
      </LegalSection>

      <LegalSection id="subscriptions" title="Subscriptions">
        <ul className="flex list-disc flex-col gap-2.5 pl-5.5">
          <li>
            JobTrigger is free for one saved server.{" "}
            <strong className="text-fg">JobTrigger Pro</strong> is an optional paid subscription
            that adds more tools, servers and features. What each plan includes is on the{" "}
            <Link href={routes.pricing}>pricing page</Link>.
          </li>
          <li>
            In the app, Pro is bought through the App Store or Google Play. Your payment is taken by
            that store, and the price, currency and any free trial are shown by the store before you
            confirm.
          </li>
          <li>
            A subscription <strong className="text-fg">renews automatically</strong> at the end of
            each period until you cancel it. Cancel at least a day before the period ends, in your
            App Store or Google Play subscription settings. Deleting the app or your JobTrigger
            account does not cancel it.
          </li>
          <li>
            Refunds for store purchases are handled by Apple or Google under their own rules; we
            cannot refund them. If you ever buy on this website, the seller is our payment provider,
            Paddle, and its refund terms are shown at checkout.
          </li>
          <li>
            If a subscription ends, nothing you saved is deleted. You keep one usable server and the
            rest wait, locked, until you subscribe again.
          </li>
          <li>
            We may change prices for new and renewing subscriptions. The store tells you first and
            asks for your agreement where it requires it.
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="availability" title="Availability">
        <p>
          JobTrigger is still in development. Features marked Beta or Coming soon may change, and
          the service may sometimes be unavailable.
        </p>
      </LegalSection>

      <LegalSection id="changes" title="Changes">
        <p>
          If these terms change, the date above changes with them and the{" "}
          <Link href={routes.changelog}>changelog</Link> says what changed.
        </p>
      </LegalSection>

      <LegalSection id="contact" title="Contact">
        <p>
          Questions about these terms: <EmailLink field="privacyEmail" />
        </p>
      </LegalSection>
    </LegalShell>
  );
}
