import Link from "next/link";

import { Container, Section } from "@/components/layout";

import { routes } from "../site-links";

/** Laptop form → arrow → the same server in the app. One image to AT. */
function SetupIllustration() {
  return (
    <div
      role="img"
      aria-label="A browser form with Jenkins details on a laptop, an arrow, and the same server appearing in the JobTrigger app on a phone"
      className="flex min-w-0 flex-[1_1_520px] flex-col items-center justify-center gap-5 md:flex-row md:flex-wrap"
    >
      <div
        data-surface="light"
        className="w-full max-w-90 min-w-0 overflow-hidden rounded-2xl bg-card shadow-device md:flex-[1_1_300px]"
      >
        <div className="flex items-center gap-2 border-b border-line bg-raised px-3.5 py-2.5">
          <span className="size-2.5 rounded-full bg-failed-fg/50" />
          <span className="size-2.5 rounded-full bg-unstable-fg/50" />
          <span className="size-2.5 rounded-full bg-success-fg/50" />
          <span className="ml-2 min-w-0 flex-1 truncate rounded-md bg-card px-2.5 py-1 font-mono text-[0.6875rem] text-muted">
            jobtrigger.app/servers/new
          </span>
        </div>
        <div className="flex flex-col gap-2.5 p-4.5 font-mono text-xs">
          <span className="font-sans text-[0.9375rem] font-bold">Add a Jenkins server</span>
          <span className="rounded-[10px] border border-line-strong px-3 py-2.5">
            https://ci.acme.dev
          </span>
          <span className="rounded-[10px] border border-line-strong px-3 py-2.5">sam</span>
          <span className="rounded-[10px] border-2 border-accent px-3 py-2.5">
            ••••••••••••a91f
          </span>
          <span className="flex h-9.5 items-center justify-center rounded-[10px] bg-accent font-sans text-[0.8125rem] font-semibold text-on-accent">
            Save
          </span>
        </div>
      </div>

      {/* Points down when the illustration stacks on phones. */}
      <span className="flex size-13 flex-none rotate-90 items-center justify-center rounded-full bg-on-accent text-accent shadow-float md:rotate-0">
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.4"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M5 12h14M13 6l6 6-6 6" />
        </svg>
      </span>

      {/* The phone frame is the dark page colour; the screen is a card. */}
      <div data-surface="dark" className="w-50 flex-none rounded-[34px] p-2 shadow-device">
        <div className="flex flex-col gap-2.5 rounded-[27px] bg-card px-3.5 py-5.5">
          <span className="text-xs font-semibold tracking-[0.06em] text-muted uppercase">
            Servers
          </span>
          <span className="flex flex-col gap-1 rounded-[14px] bg-running-bg p-3">
            <span className="text-[0.8125rem] font-bold">Acme production</span>
            <span className="text-[0.6875rem] text-success-fg">✓ Just added</span>
          </span>
          <span className="rounded-[14px] bg-raised p-3 text-[0.8125rem] text-fg-secondary">
            Home lab
          </span>
        </div>
      </div>
    </div>
  );
}

/** "Setup, solved": the slanted accent band (US-WEB-01, the portal pitch). */
export function SetupBand() {
  return (
    <Section aria-labelledby="setup-heading" className="relative overflow-hidden">
      <div aria-hidden="true" className="absolute inset-x-[-5%] inset-y-20 -skew-y-4 bg-accent" />
      <Container className="relative flex flex-wrap items-center gap-14 py-40">
        <div className="flex min-w-0 flex-[1_1_400px] flex-col gap-4.5 text-on-accent">
          <p className="text-kicker text-on-accent-muted uppercase">Setup, solved</p>
          <h2 id="setup-heading" className="text-h2 md:text-5xl md:leading-[1.05]">
            Paste tokens on your laptop. Your phone already has them.
          </h2>
          <p className="text-lg leading-relaxed">
            No emailing yourself tokens. Sign in on the web, paste once, open the app.
          </p>
          <Link
            href={routes.signIn}
            className="flex h-13 items-center self-start rounded-[14px] bg-on-accent px-6 font-bold text-accent-hover no-underline hover:text-accent-hover"
          >
            Set up a server →
          </Link>
        </div>
        <SetupIllustration />
      </Container>
    </Section>
  );
}
