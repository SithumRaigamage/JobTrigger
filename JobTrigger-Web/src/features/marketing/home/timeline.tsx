import type { ReactNode } from "react";

import { cn } from "@/components/cn";
import { Container, Section } from "@/components/layout";

/* Illustrations: each is one role="img" with a description, so assistive
   tech hears what it shows rather than the mock UI text inside it. */

function TriggerCard() {
  return (
    <div
      role="img"
      aria-label="A Build with parameters form for deploy-api: branch release/2.4, environment staging, a masked DB_PASSWORD, and a Build button"
      data-surface="light"
      className="flex flex-col gap-4 rounded-panel bg-card p-6 shadow-device"
    >
      <div className="flex items-center justify-between gap-3">
        <span className="font-bold">deploy-api</span>
        <span className="font-mono text-xs text-muted">Build with parameters</span>
      </div>
      <div className="flex flex-col gap-1.5">
        <span className="font-mono text-xs text-fg-secondary">BRANCH</span>
        <span className="flex h-11 items-center justify-between rounded-control border border-line-strong px-3.5 font-mono text-sm">
          release/2.4 <span>▾</span>
        </span>
      </div>
      <div className="flex flex-col gap-1.5">
        <span className="font-mono text-xs text-fg-secondary">ENVIRONMENT</span>
        <span className="flex gap-1 rounded-control bg-raised p-1 text-sm font-semibold">
          <span className="flex-1 rounded-[9px] p-2 text-center text-fg-secondary">dev</span>
          <span className="flex-1 rounded-[9px] bg-card p-2 text-center shadow-card">staging</span>
          <span className="flex-1 rounded-[9px] p-2 text-center text-fg-secondary">prod</span>
        </span>
      </div>
      <div className="flex items-center justify-between gap-3">
        <span className="font-mono text-xs text-fg-secondary">DB_PASSWORD</span>
        <span className="font-mono text-sm text-muted">•••••••• (masked)</span>
      </div>
      <span className="flex h-12 items-center justify-center rounded-control bg-accent font-semibold text-on-accent">
        ▶ Build
      </span>
    </div>
  );
}

function WatchCard() {
  return (
    <div
      role="img"
      aria-label="A live console log, running for 1 minute 48 seconds, with a search button: the build succeeds and two flaky tests are retried"
      className="overflow-hidden rounded-panel border border-line bg-sunken shadow-device"
    >
      <div className="flex flex-wrap items-center gap-2 border-b border-line bg-band px-4 py-3">
        <span className="rounded-full bg-running-bg px-2.5 py-1 text-xs font-semibold text-running-fg">
          ● Running · 1m 48s
        </span>
        <span className="ml-auto flex h-8 items-center rounded-lg bg-raised px-3 text-xs text-fg-secondary">
          ⌕ Search log
        </span>
      </div>
      <div className="flex flex-col p-4.5 font-mono text-[0.8125rem] leading-[1.8]">
        <span className="text-muted">12:04:01 Started by user sam</span>
        <span className="text-fg-secondary">12:04:03 [Pipeline] stage (Build)</span>
        <span className="text-fg-secondary">12:04:41 &gt; gradle assemble</span>
        <span className="text-success-fg">12:05:12 BUILD SUCCESSFUL in 31s</span>
        <span className="text-fg-secondary">12:05:13 [Pipeline] stage (Test)</span>
        <span className="text-unstable-fg">12:05:40 WARN 2 flaky tests retried</span>
        <span className="text-running-fg">12:05:49 ▍</span>
      </div>
    </div>
  );
}

function Stage({ tone, children }: { tone: "success" | "failed" | "idle"; children: string }) {
  return (
    <span
      className={cn(
        "rounded-[9px] px-2.5 py-1.75 text-xs font-semibold",
        tone === "success" && "bg-success-bg text-success-fg",
        tone === "failed" && "bg-failed-bg text-failed-fg ring-3 ring-failed-fg/25",
        tone === "idle" && "bg-raised text-muted",
      )}
    >
      {children}
    </span>
  );
}

function FixCard() {
  return (
    <div
      role="img"
      aria-label="Build #481 failed at the Test stage: AuthTokenTest.expiresAfterRefresh expected 401 but was 200, after commit a1f9c2e “refresh: extend token TTL”"
      className="flex flex-col gap-4.5 rounded-panel border border-line-strong bg-card p-5.5 shadow-device"
    >
      <div className="flex flex-wrap items-center justify-between gap-3">
        <span className="font-bold">Build #481</span>
        <span className="rounded-full bg-failed-bg px-2.5 py-1 text-xs font-semibold text-failed-fg">
          ✕ Failed
        </span>
      </div>
      <div className="flex flex-wrap items-center gap-1.5">
        <Stage tone="success">✓ Checkout</Stage>
        <span className="hidden h-0.5 w-4.5 bg-success-fg sm:block" />
        <Stage tone="success">✓ Build</Stage>
        <span className="hidden h-0.5 w-4.5 bg-failed-fg sm:block" />
        <Stage tone="failed">✕ Test</Stage>
        <span className="hidden h-0.5 w-4.5 bg-line-strong sm:block" />
        <Stage tone="idle">○ Deploy</Stage>
      </div>
      <div className="flex flex-col gap-2 rounded-[14px] bg-page p-3.5">
        <span className="text-xs font-semibold tracking-[0.06em] text-muted uppercase">
          Failed tests · 1 of 215
        </span>
        <span className="font-mono text-[0.8125rem] break-all text-failed-fg">
          AuthTokenTest.expiresAfterRefresh
        </span>
        <span className="font-mono text-xs text-muted">expected 401 but was 200</span>
      </div>
      <div className="flex items-center gap-2.5 text-[0.8125rem] text-fg-secondary">
        <span className="flex size-6.5 items-center justify-center rounded-full bg-running-bg text-[0.6875rem] font-bold text-running-fg">
          PK
        </span>
        <span>
          <span className="font-mono text-running-fg">a1f9c2e</span> refresh: extend token TTL
        </span>
      </div>
    </div>
  );
}

const jobTiles = [
  { name: "web-app", label: "✓ Success", tone: "bg-success-bg text-success-fg" },
  { name: "api-gateway", label: "✕ Failed", tone: "bg-failed-bg text-failed-fg" },
  { name: "deploy-api", label: "● Running", tone: "bg-running-bg text-running-fg" },
  { name: "nightly-e2e", label: "▲ Unstable", tone: "bg-unstable-bg text-unstable-fg" },
];

function RelaxCard() {
  return (
    <div
      role="img"
      aria-label="Two notifications, web-app #219 succeeded and api-gateway #481 failed, above a home-screen widget showing four pinned jobs and their status"
      // Stacked on phones; the overlapping layout from md up, where it fits.
      className="flex flex-col gap-3 md:relative md:block md:h-82.5"
    >
      <div className="md:absolute md:inset-x-0 md:top-0 md:pl-9">
        <div
          data-surface="light"
          className="flex origin-top scale-[0.94] gap-3 rounded-card bg-card px-4 py-3.5 opacity-55"
        >
          <span className="flex size-8.5 shrink-0 items-center justify-center rounded-[10px] bg-success-bg font-extrabold text-success-fg">
            ✓
          </span>
          <span className="flex flex-col">
            <span className="text-sm font-bold">web-app #219 succeeded</span>
            <span className="text-xs text-muted">2 min ago</span>
          </span>
        </div>
      </div>
      <div
        data-surface="light"
        className="flex gap-3 rounded-card bg-card px-4 py-3.5 shadow-float md:absolute md:inset-x-4.5 md:top-11"
      >
        <span className="flex size-8.5 shrink-0 items-center justify-center rounded-[10px] bg-failed-bg font-extrabold text-failed-fg">
          ✕
        </span>
        <span className="flex flex-col">
          <span className="text-sm font-bold">api-gateway #481 failed</span>
          <span className="text-xs text-muted">Test stage · tap to see why</span>
        </span>
      </div>
      <div className="grid grid-cols-2 gap-2.5 rounded-panel border border-line-strong bg-card p-4 md:absolute md:right-15 md:bottom-0 md:left-0">
        {jobTiles.map((tile) => (
          <span
            key={tile.name}
            className={cn(
              "flex min-w-0 flex-col gap-1 rounded-[14px] p-3 text-[0.8125rem] font-semibold break-words",
              tile.tone,
            )}
          >
            {tile.name}
            <span className="text-xs font-medium">{tile.label}</span>
          </span>
        ))}
      </div>
    </div>
  );
}

type Step = {
  kicker: string;
  title: string;
  body: string;
  /** Node and kicker colours: one status pair per step. */
  tone: { node: string; kicker: string };
  illustration: ReactNode;
};

const steps: Step[] = [
  {
    kicker: "Trigger",
    title: "Start any job, with the right inputs.",
    body: "Browse folders and multibranch pipelines. Every parameter gets a proper input — branches, choices, files — and secrets stay masked and are never saved.",
    tone: { node: "bg-running-bg text-running-fg ring-accent/45", kicker: "text-running-fg" },
    illustration: <TriggerCard />,
  },
  {
    kicker: "Watch",
    title: "Logs that stream as fast as the build.",
    body: "Follow the console live, search it, jump to a stage, and share the full log with your team in two taps.",
    tone: { node: "bg-success-bg text-success-fg ring-live-dot/35", kicker: "text-success-fg" },
    illustration: <WatchCard />,
  },
  {
    kicker: "Fix",
    title: "See why it went red in seconds.",
    body: "The failing stage, the failing test and the commit that went in — on one screen, before you reach a laptop.",
    tone: { node: "bg-failed-bg text-failed-fg ring-failed-fg/35", kicker: "text-failed-fg" },
    illustration: <FixCard />,
  },
  {
    kicker: "Relax",
    title: "Stop refreshing. We’ll tell you.",
    body: "Watch a build and get a notification when it finishes. Pin your jobs to a home-screen widget.",
    tone: {
      node: "bg-unstable-bg text-unstable-fg ring-unstable-fg/35",
      kicker: "text-unstable-fg",
    },
    illustration: <RelaxCard />,
  },
];

/** "Everything you open Jenkins for" — Trigger, Watch, Fix, Relax (US-WEB-01). */
export function Timeline() {
  return (
    <Section surface="dark" aria-labelledby="timeline-heading">
      <Container className="flex flex-col pt-26 pb-10">
        <h2
          id="timeline-heading"
          className="max-w-190 pb-16 text-h2 leading-[1.05] md:text-[3.25rem]"
        >
          Everything you open Jenkins for. <span className="text-muted">Minus the laptop.</span>
        </h2>

        <ol>
          {steps.map((step, index) => (
            <li key={step.kicker} className="flex gap-4 md:gap-7">
              <div className="flex w-12 flex-none flex-col items-center">
                <span
                  aria-hidden="true"
                  className={cn(
                    "flex size-12 flex-none items-center justify-center rounded-full text-[1.0625rem] font-extrabold ring-6",
                    step.tone.node,
                  )}
                >
                  {index + 1}
                </span>
                <span
                  className={cn(
                    "mt-3 w-0.5 flex-1",
                    index < steps.length - 1 ? "bg-line" : "bg-transparent",
                  )}
                />
              </div>
              <div className="flex min-w-0 flex-auto flex-wrap items-start gap-10 pb-24">
                <div className="flex min-w-0 flex-[1_1_360px] flex-col gap-3.5 pt-1.5">
                  <span className={cn("text-kicker uppercase", step.tone.kicker)}>
                    {step.kicker}
                  </span>
                  <h3 className="text-[1.75rem] leading-[1.1] font-extrabold tracking-[-0.03em] md:text-[2.25rem]">
                    {step.title}
                  </h3>
                  <p className="text-[1.0625rem] leading-[1.65] text-fg-secondary">{step.body}</p>
                </div>
                <div className="min-w-0 flex-[1_1_440px]">{step.illustration}</div>
              </div>
            </li>
          ))}
        </ol>
      </Container>
    </Section>
  );
}
