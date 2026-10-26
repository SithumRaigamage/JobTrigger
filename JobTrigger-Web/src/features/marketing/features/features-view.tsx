import Link from "next/link";

import buildDetail from "@/assets/screens/14-build-detail.png";
import buildLog from "@/assets/screens/15-build-log.png";
import githubRepos from "@/assets/screens/07-home-github-repos.png";
import globalHistory from "@/assets/screens/08-global-history.png";
import home from "@/assets/screens/app-home-dark.png";
import jobDetail from "@/assets/screens/11-job-detail.png";
import { cn } from "@/components/cn";
import { Card, Container, Kicker, Section } from "@/components/layout";
import { StaticImage } from "@/components/static-image";
import { StatusBadge } from "@/components/status-badge";
import { statusOf } from "@/content/feature-status";

import { routes } from "../site-links";

// Fanned gallery: outer frames drop out on narrow screens (WEB-B4).
const gallery = [
  { image: jobDetail, frame: "h-75 -rotate-6 hidden md:block" },
  { image: buildLog, frame: "h-90 -rotate-3 hidden sm:block" },
  { image: home, frame: "h-105" },
  { image: buildDetail, frame: "h-90 rotate-3 hidden sm:block" },
  { image: globalHistory, frame: "h-75 rotate-6 hidden md:block" },
];

type Tone = "running" | "neutral" | "failed" | "success" | "unstable";

const tones: Record<Tone, string> = {
  running: "bg-running-bg text-running-fg",
  neutral: "bg-neutral-bg text-neutral-fg",
  failed: "bg-failed-bg text-failed-fg",
  success: "bg-success-bg text-success-fg",
  unstable: "bg-unstable-bg text-unstable-fg",
};

// Every card describes something live in the app today (Phases 4, 5, 7, 11).
const cards: { tone: Tone; glyph: string; title: string; body: string; chip: string }[] = [
  {
    tone: "running",
    glyph: "▶",
    title: "Every parameter type",
    body: "Choices, booleans, multi-line text, files and runs — each gets the right input.",
    chip: "release/2.4 · staging",
  },
  {
    tone: "neutral",
    glyph: "••",
    title: "Secrets stay secret",
    body: "Password parameters are masked, never pre-filled and never saved.",
    chip: "DB_PASSWORD ••••••••",
  },
  {
    tone: "running",
    glyph: "≡",
    title: "Live console",
    body: "Streams as it runs, with colours, search and per-stage logs.",
    chip: "● streaming · 1m 48s",
  },
  {
    tone: "failed",
    glyph: "✕",
    title: "Failure at a glance",
    body: "Failing stage, failing tests and the commits that went in.",
    chip: "✕ Test · 1 of 215",
  },
  {
    tone: "success",
    glyph: "✓",
    title: "Build notifications",
    body: "Watch a build and get told when it finishes.",
    chip: "✓ #482 succeeded",
  },
  {
    tone: "unstable",
    glyph: "▦",
    title: "Home-screen widget",
    body: "Pinned jobs and their status without opening the app.",
    chip: "▲ nightly-e2e unstable",
  },
  {
    tone: "neutral",
    glyph: "⇄",
    title: "Many servers",
    body: "Work and personal Jenkins; switch in a tap.",
    chip: "2 servers · 1 active",
  },
  {
    tone: "running",
    glyph: "⌂",
    title: "Queue and nodes",
    body: "What’s waiting, which agents are busy, take one offline.",
    chip: "3 queued · 5/6 busy",
  },
  {
    tone: "success",
    glyph: "◉",
    title: "App lock",
    body: "Face ID or fingerprint, with your passcode as backup.",
    chip: "Face ID on",
  },
];

/** Features page (designs 02 / 19; US-WEB-03). */
export function FeaturesView() {
  const runsLive = statusOf("github-runs") === "live";

  return (
    <main className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid className="overflow-hidden">
        <Container className="flex flex-col items-center gap-5.5 pt-24 text-center">
          <Kicker>Features</Kicker>
          <h1 className="max-w-225 text-h1">
            The whole CI loop. <span className="text-running-fg">On one screen.</span>
          </h1>
          <p className="max-w-155 text-[1.1875rem] leading-relaxed text-fg-secondary">
            {runsLive
              ? "Everything on this page ships in the current app — no roadmap promises."
              : "Everything below is built today. Anything still on the way is marked."}
          </p>
          <div
            role="img"
            aria-label="JobTrigger screens: job detail, build log, home, build detail and history"
            className="mt-10 flex w-full items-end justify-center gap-4"
          >
            {gallery.map((shot, index) => (
              <div
                key={index}
                className={cn(
                  "min-w-0 flex-[0_1_200px] origin-bottom overflow-hidden rounded-t-[33px] bg-raised px-1.75 pt-1.75 shadow-device",
                  shot.frame,
                )}
              >
                <StaticImage
                  image={shot.image}
                  alt=""
                  priority={index === 2}
                  className="block size-full rounded-t-[26px] object-cover object-top"
                />
              </div>
            ))}
          </div>
        </Container>
      </Section>

      <Section aria-labelledby="cards-heading">
        <Container className="flex flex-col gap-10 py-26">
          <h2 id="cards-heading" className="max-w-180 text-h2">
            Built for the moments you&apos;re away from your desk.
          </h2>
          <ul className="grid grid-cols-[repeat(auto-fit,minmax(min(300px,100%),1fr))] gap-5">
            {cards.map((card) => (
              <li key={card.title}>
                <Card className="flex h-full flex-col gap-3.5 rounded-panel p-6.5">
                  <span
                    aria-hidden="true"
                    className={cn(
                      "flex size-11 items-center justify-center rounded-[13px] text-[1.0625rem] font-extrabold",
                      tones[card.tone],
                    )}
                  >
                    {card.glyph}
                  </span>
                  <h3 className="text-[1.1875rem] font-bold">{card.title}</h3>
                  <p className="text-[0.9375rem] leading-relaxed text-muted">{card.body}</p>
                  <span
                    className={cn(
                      "mt-auto self-start rounded-[10px] px-2.5 py-1.5 font-mono text-xs",
                      tones[card.tone],
                    )}
                  >
                    {card.chip}
                  </span>
                </Card>
              </li>
            ))}
          </ul>
        </Container>
      </Section>

      <Section surface="dark" aria-labelledby="github-heading">
        <Container className="flex flex-wrap items-center gap-14 py-26">
          <div className="flex min-w-0 flex-[1_1_440px] flex-col gap-4.5">
            <p className="flex items-center gap-2 self-start">
              <span className="rounded-full bg-fg px-3 py-1.25 text-[0.8125rem] font-bold text-page">
                GitHub Actions
              </span>{" "}
              <StatusBadge feature="github-actions" size="md" />
            </p>
            <h2 id="github-heading" className="text-h2">
              Jenkins and GitHub, side by side.
            </h2>
            <p className="text-[1.0625rem] leading-[1.65] text-fg-secondary">
              Add your GitHub accounts and browse repositories and workflows next to your Jenkins
              servers.{!runsLive && " Runs, logs and history are on the way."}
            </p>
            {!runsLive && (
              <ul className="flex flex-wrap gap-2 text-[0.8125rem] font-semibold">
                <li className="rounded-[10px] bg-success-bg px-3 py-1.5 text-success-fg">
                  ✓ Accounts · repos · workflows
                </li>
                <li className="rounded-[10px] bg-neutral-bg px-3 py-1.5 text-neutral-fg">
                  Coming soon · runs · logs · history
                </li>
              </ul>
            )}
            <Link href={routes.integrations} className="self-start font-semibold">
              See every integration →
            </Link>
          </div>
          <div className="flex min-w-0 flex-[1_1_360px] justify-center">
            <div className="w-65 rounded-[44px] bg-raised p-2.25 shadow-device ring-1 ring-line-strong">
              <StaticImage
                image={githubRepos}
                alt="GitHub repositories in JobTrigger"
                className="block h-auto w-full rounded-[35px]"
              />
            </div>
          </div>
        </Container>
      </Section>
    </main>
  );
}
