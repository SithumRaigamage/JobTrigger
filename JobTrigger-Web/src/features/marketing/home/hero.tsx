import Link from "next/link";

import { Container, Section } from "@/components/layout";
import { StaticImage } from "@/components/static-image";
import { StatusBadge } from "@/components/status-badge";
import { statusOf } from "@/content/feature-status";

import appHome from "@/assets/screens/app-home-dark.png";

import { routes } from "../site-links";

function ArrowIcon() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

const ctaBase =
  "flex h-14 items-center gap-2.5 rounded-[14px] text-[1.0625rem] font-semibold no-underline";

/** The phone with three floating cards around it. One image to assistive tech. */
function HeroIllustration() {
  return (
    <div
      role="img"
      aria-label="JobTrigger on a phone, with a build-succeeded notification, a pipeline stage strip and a live console snippet around it"
      className="relative h-150 min-w-0 flex-[1_1_500px]"
    >
      <div className="absolute top-0 left-1/2 w-67.5 -translate-x-1/2 rounded-[44px] bg-raised p-2.25 shadow-device">
        <StaticImage
          image={appHome}
          alt=""
          priority
          className="block h-auto w-full rounded-[35px]"
        />
      </div>

      {/* A light card on the dark hero: its own surface. */}
      <div
        data-surface="light"
        className="absolute top-16 left-0 flex min-w-66 items-start gap-3 rounded-card bg-card px-4 py-3.5 whitespace-nowrap shadow-float"
      >
        <span className="flex size-9 shrink-0 items-center justify-center rounded-[10px] bg-success-bg text-success-fg">
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M20 6 9 17l-5-5" />
          </svg>
        </span>
        <span className="flex flex-col gap-0.5">
          <span className="text-sm font-bold">Build #482 succeeded</span>
          <span className="font-mono text-xs text-muted">api-gateway · main · 3m 12s</span>
        </span>
      </div>

      <div className="absolute top-73 right-0 flex w-72.5 flex-col gap-3 rounded-card border border-line-strong bg-card p-4 shadow-float">
        <span className="text-xs font-semibold tracking-[0.06em] text-muted uppercase">
          Pipeline · #483
        </span>
        <div className="flex items-center gap-1.5 text-xs font-semibold">
          <span className="rounded-lg bg-success-bg px-2 py-1.5 text-success-fg">✓ Build</span>
          <span className="h-0.5 flex-1 bg-success-fg" />
          <span className="rounded-lg bg-success-bg px-2 py-1.5 text-success-fg">✓ Test</span>
          <span className="h-0.5 flex-1 bg-running-fg" />
          <span className="rounded-lg bg-running-bg px-2 py-1.5 text-running-fg ring-3 ring-accent/35">
            ● Deploy
          </span>
        </div>
      </div>

      <div className="absolute bottom-0 left-3 flex w-75 flex-col rounded-2xl border border-line bg-sunken px-4 py-3.5 font-mono text-xs leading-[1.7] shadow-float">
        <span className="text-muted">[deploy] pushing image :483</span>
        <span className="text-fg-secondary">[deploy] rolling 3/3 pods</span>
        <span className="text-success-fg">✓ 214 tests passed</span>
        <span className="text-running-fg">● waiting for health check…</span>
      </div>
    </div>
  );
}

/**
 * Home hero (designs 01 / 18; US-WEB-01, 02). Until the app is in the
 * stores the main action is web setup, with a "coming soon" line for the
 * apps; at launch it becomes "Get the app".
 */
export function Hero() {
  const appLive = statusOf("app-stores") === "live";

  return (
    <Section surface="dark" dotGrid className="border-b border-line">
      <Container className="flex flex-wrap items-center gap-12 pt-24 pb-22">
        <div className="flex min-w-0 flex-[1_1_500px] flex-col gap-7">
          <Link
            href={routes.signIn}
            className="flex items-center gap-2.5 self-start rounded-full border border-line bg-card py-1.5 pr-3.5 pl-1.5 text-sm text-fg-secondary no-underline hover:text-fg"
          >
            <span className="rounded-full bg-accent px-2.5 py-0.75 text-xs font-bold text-on-accent">
              New
            </span>
            Set up servers from your laptop →
          </Link>

          <h1 className="text-display">
            Ship builds
            <br />
            from <span className="text-running-fg">anywhere.</span>
          </h1>
          <p className="max-w-135 text-xl leading-relaxed text-fg-secondary">
            JobTrigger puts Jenkins, GitHub Actions and SonarQube in your pocket. Trigger jobs,
            watch logs stream live, and know the moment a build breaks.
          </p>

          <div className="flex flex-wrap gap-3">
            <Link
              href={appLive ? routes.download : routes.signIn}
              className={`${ctaBase} bg-accent px-7 text-on-accent hover:bg-accent-hover hover:text-on-accent`}
            >
              {appLive ? "Get the app — free" : "Set up your servers"} <ArrowIcon />
            </Link>
            <Link
              href={routes.features}
              className={`${ctaBase} border border-line-strong px-6 text-fg hover:bg-raised hover:text-fg`}
            >
              Take the tour
            </Link>
          </div>

          {!appLive && (
            <Link
              href={routes.download}
              className="flex items-center gap-2.5 self-start text-sm text-fg-secondary no-underline hover:text-fg"
            >
              {/* Explicit space: JSX drops the line break, which made the
                  link's name "Coming sooniPhone…". */}
              <StatusBadge feature="app-stores" /> iPhone and Android apps — see what&apos;s
              launching
            </Link>
          )}
        </div>

        <HeroIllustration />
      </Container>
    </Section>
  );
}
