import Link from "next/link";
import type { ReactNode } from "react";

import { cn } from "@/components/cn";
import { EmailLink } from "@/components/email-link";
import { Card, Container, Kicker, Section } from "@/components/layout";
import { ToolTile } from "@/components/tool-tile";
import { detail } from "@/content/site-details";

import { routes } from "../site-links";

function Node({ icon, title, note }: { icon: ReactNode; title: string; note?: string }) {
  return (
    <div className="flex min-w-0 flex-[0_1_240px] items-center gap-3 rounded-card border border-line-strong bg-card p-4.5">
      {icon}
      <span className="flex flex-col">
        <span className="font-bold">{title}</span>
        {note && <span className="text-xs text-muted">{note}</span>}
      </span>
    </div>
  );
}

function FlowLine({
  label,
  tone,
  grow,
}: {
  label: string;
  tone: "success" | "running";
  grow: string;
}) {
  return (
    <div
      className={cn(
        "flex min-w-24 flex-col items-center gap-1.5 px-3 text-center text-xs font-semibold",
        grow,
        tone === "success" ? "text-success-fg" : "text-running-fg",
      )}
    >
      <span
        className={cn("h-0.5 w-full", tone === "success" ? "bg-success-fg" : "bg-running-fg")}
      />
      {label}
    </div>
  );
}

const iconBox = "flex size-10 flex-none items-center justify-center rounded-xl";

function TokenFlowDiagram() {
  return (
    <div
      role="img"
      aria-label="Diagram: your phone talks directly to Jenkins, GitHub and SonarQube over HTTPS; your phone and this website both talk to the JobTrigger account service, which stores encrypted tokens; the website shows tokens only masked"
      className="flex flex-col gap-5"
    >
      <div className="flex flex-wrap items-center gap-y-3">
        <Node
          title="Your phone"
          note="Keychain / Keystore"
          icon={
            <span className={cn(iconBox, "bg-running-bg text-running-fg")}>
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              >
                <rect x="6" y="2" width="12" height="20" rx="3" />
                <path d="M11 18h2" />
              </svg>
            </span>
          }
        />
        <FlowLine label="Direct · HTTPS · not through us" tone="success" grow="flex-[1_1_160px]" />
        <div className="flex min-w-0 flex-[0_1_280px] items-center gap-2 rounded-card border border-line-strong bg-card p-4.5">
          <ToolTile tool="jenkins" />
          <ToolTile tool="github" />
          <ToolTile tool="sonarqube" />
          <span className="pl-1 font-bold">Your CI servers</span>
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-y-3">
        <Node
          title="Your laptop"
          note="sees ••••abcd only"
          icon={
            <span className={cn(iconBox, "bg-unstable-bg text-unstable-fg")}>
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              >
                <rect x="3" y="4" width="18" height="12" rx="2" />
                <path d="M2 20h20" />
              </svg>
            </span>
          }
        />
        <FlowLine label="HTTPS" tone="running" grow="flex-[1_1_120px]" />
        <div className="min-w-0 flex-[0_1_200px] rounded-card border border-line-strong bg-card p-4.5 font-bold">
          This website
        </div>
        <FlowLine label="HTTPS" tone="running" grow="flex-[1_1_120px]" />
        <div className="flex min-w-0 flex-[0_1_280px] items-center gap-3 rounded-card bg-accent p-4.5 text-on-accent ring-6 ring-accent/25">
          <span className={cn(iconBox, "bg-on-accent text-accent-hover")}>
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            >
              <rect x="4" y="10" width="16" height="11" rx="2" />
              <path d="M8 10V7a4 4 0 0 1 8 0v3" />
            </svg>
          </span>
          <span className="flex flex-col">
            <span className="font-bold">Account service</span>
            <span className="text-xs">tokens encrypted at rest</span>
          </span>
        </div>
      </div>
    </div>
  );
}

// Each fact is true of the app and backend today, or of this site once the
// portal ships in this phase (30-minute idle sign-out: P15-15).
const facts = [
  {
    title: "Encrypted at rest",
    body: "Saved passwords and tokens are encrypted before storage. Your account password is hashed.",
  },
  {
    title: "Secure storage on the phone",
    body: "Tokens live in the iOS Keychain or Android Keystore — never in plain app settings.",
  },
  {
    title: "Never shown in full on the web",
    body: "Once saved, a token never goes back to your browser. To change it, paste a new one.",
  },
  {
    title: "Short sessions",
    body: "Sign-ins expire quickly and renew quietly. The website signs you out after 30 idle minutes.",
  },
  {
    title: "Your permissions only",
    body: "JobTrigger can do only what your token allows. It never reads Jenkins’ credential store.",
  },
  {
    title: "Optional app lock",
    body: "Face ID or fingerprint, so an unlocked phone still can’t open JobTrigger.",
  },
];

const factTones = [
  "bg-running-bg text-running-fg",
  "bg-success-bg text-success-fg",
  "bg-unstable-bg text-unstable-fg",
  "bg-failed-bg text-failed-fg",
  "bg-running-bg text-running-fg",
  "bg-success-bg text-success-fg",
];

/** Security page (design 04; US-WEB-05). */
export function SecurityView() {
  return (
    <main className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid>
        <Container className="flex flex-col gap-14 py-24">
          <div className="flex max-w-205 flex-col gap-4.5">
            <Kicker>Security</Kicker>
            <h1 className="text-h1">
              Your tokens, <span className="text-running-fg">accounted for.</span>
            </h1>
            <p className="text-[1.1875rem] leading-relaxed text-fg-secondary">
              You&apos;re trusting us with access to your CI. Here is every place that access
              travels.
            </p>
          </div>
          <TokenFlowDiagram />
        </Container>
      </Section>

      <Section aria-label="How tokens are protected">
        <Container className="pt-26 pb-16">
          <ul className="grid grid-cols-[repeat(auto-fit,minmax(min(320px,100%),1fr))] gap-5">
            {facts.map((fact, index) => (
              <li key={fact.title}>
                <Card radius="panel" className="flex h-full flex-col gap-3 p-6.5">
                  <span
                    aria-hidden="true"
                    className={cn(
                      "flex size-11 items-center justify-center rounded-[13px] font-mono text-sm font-bold",
                      factTones[index],
                    )}
                  >
                    {String(index + 1).padStart(2, "0")}
                  </span>
                  <h2 className="text-[1.1875rem] font-bold">{fact.title}</h2>
                  <p className="text-[0.9375rem] leading-relaxed text-muted">{fact.body}</p>
                </Card>
              </li>
            ))}
          </ul>
        </Container>
      </Section>

      <Section aria-label="Advice and reporting">
        <Container className="flex flex-wrap gap-5 pb-28">
          <div
            data-surface="dark"
            className="flex min-w-0 flex-[2_1_480px] flex-col gap-3.5 rounded-3xl p-9"
          >
            <h2 className="text-[1.75rem] font-extrabold tracking-[-0.02em]">
              Give it the smallest token you can.
            </h2>
            <ul className="flex flex-col gap-2.5 leading-[1.55] text-fg-secondary">
              {[
                "A token just for JobTrigger, so you can revoke it alone.",
                "On GitHub, a fine-grained token limited to the repos you need.",
                "An expiry date — then rotate it from the website.",
              ].map((tip) => (
                <li key={tip} className="flex gap-2.5">
                  <span aria-hidden="true" className="text-success-fg">
                    ✓
                  </span>
                  {tip}
                </li>
              ))}
            </ul>
            <Link href={routes.addServer} className="self-start font-semibold">
              Step-by-step token guides →
            </Link>
          </div>
          <Card radius="xl" flat className="flex min-w-0 flex-[1_1_300px] flex-col gap-3 p-9">
            <h2 className="text-xl font-bold">Found a problem?</h2>
            <p className="text-[0.9375rem] leading-relaxed text-muted">
              Report it privately to <EmailLink field="securityEmail" />. We reply within{" "}
              {detail("securityReplyDays")} working days.
            </p>
          </Card>
        </Container>
      </Section>
    </main>
  );
}
