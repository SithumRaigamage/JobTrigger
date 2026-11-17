import Link from "next/link";

import { cn } from "@/components/cn";
import { Card, Container, Kicker, Section } from "@/components/layout";

import { routes } from "../site-links";

// Each claim is true today: AUD-03 encryption at rest, secure storage in
// the app, BFF masking on the web (docs/web-architecture.md §2), and the
// app calling each CI tool directly.
const facts = [
  {
    title: "Encrypted at rest",
    body: "Tokens are encrypted before they are stored.",
    tone: "bg-running-bg text-running-fg",
  },
  {
    title: "Secure storage",
    body: "iOS Keychain and Android Keystore on the phone.",
    tone: "bg-success-bg text-success-fg",
  },
  {
    title: "Masked on the web",
    body: "Saved tokens are never sent back to your browser.",
    tone: "bg-unstable-bg text-unstable-fg",
  },
  {
    title: "Direct to your CI",
    body: "No JobTrigger proxy between you and Jenkins.",
    tone: "bg-failed-bg text-failed-fg",
  },
];

function LockIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect x="4" y="10" width="16" height="11" rx="2" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </svg>
  );
}

/** Home security summary with four trust cards (US-WEB-01, links to US-WEB-05). */
export function Trust() {
  return (
    <Section aria-labelledby="trust-heading">
      <Container className="flex flex-wrap items-center gap-14 pt-10 pb-28">
        <div className="flex min-w-0 flex-[1_1_440px] flex-col gap-4.5">
          <Kicker>Security</Kicker>
          <h2 id="trust-heading" className="text-h2 tracking-[-0.03em]">
            Built by people who guard tokens for a living.
          </h2>
          <p className="text-[1.0625rem] leading-[1.65] text-muted">
            The app talks to your CI directly — never through us. Saved tokens are encrypted at rest
            and kept in your phone&apos;s secure storage.
          </p>
          <Link href={routes.security} className="self-start font-semibold">
            How we handle your tokens →
          </Link>
        </div>
        <ul className="grid min-w-0 flex-[1_1_440px] grid-cols-1 gap-4 sm:grid-cols-2">
          {facts.map((fact) => (
            <li key={fact.title}>
              <Card radius="lg" className="flex h-full flex-col gap-3 p-5.5">
                <span
                  className={cn("flex size-10 items-center justify-center rounded-xl", fact.tone)}
                >
                  <LockIcon />
                </span>
                <h3 className="font-bold">{fact.title}</h3>
                <p className="text-sm leading-normal text-muted">{fact.body}</p>
              </Card>
            </li>
          ))}
        </ul>
      </Container>
    </Section>
  );
}
