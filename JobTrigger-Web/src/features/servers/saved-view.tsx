import Link from "next/link";

import { StatusBadge } from "@/components/status-badge";
import { statusOf } from "@/content/feature-status";

import { routes } from "../marketing/site-links";

import { addServerHref } from "./server-links";
import { Steps } from "./steps";

/** "Now open the app" after saving (designs 13 / 23; US-WEB-17). */
export function SavedView({ name, others }: { name: string; others: string[] }) {
  const appLive = statusOf("app-stores") === "live";

  return (
    <>
      <Steps current={3} last={appLive ? "Open the app" : "Install the app · soon"} />
      <section
        role="status"
        aria-labelledby="saved-heading"
        data-surface="dark"
        className="relative overflow-hidden rounded-[28px]"
      >
        <div
          aria-hidden="true"
          className="absolute inset-x-[-10%] -bottom-10 h-30 -skew-y-6 bg-accent"
        />
        <div className="relative flex flex-wrap items-end gap-8 px-7 pt-10 md:px-12 md:pt-12">
          <div className="flex min-w-0 flex-[1_1_340px] flex-col gap-5 pb-14">
            <span className="flex items-center gap-2 self-start rounded-full bg-success-bg px-3 py-1.5 text-[0.8125rem] font-bold text-success-fg">
              ✓ Saved · {name}
            </span>
            <h1
              id="saved-heading"
              className="text-h2 leading-[1.04] tracking-[-0.04em] md:text-5xl"
            >
              {appLive ? (
                <>
                  Now pick up
                  <br />
                  your phone.
                </>
              ) : (
                <>
                  Saved. It&apos;ll be
                  <br />
                  waiting for you.
                </>
              )}
            </h1>
            <p className="max-w-110 text-[1.0625rem] leading-relaxed text-fg-secondary">
              {appLive
                ? "Open JobTrigger — the server is already there. If the app is open, just switch back to it."
                : "When the app launches, sign in and this server is already there."}
            </p>
            <div className="flex flex-wrap gap-2.5">
              <Link
                href={addServerHref()}
                className="flex h-13 items-center rounded-[14px] bg-fg px-5.5 font-bold text-page no-underline hover:text-page"
              >
                Add another
              </Link>
              <Link
                href="/servers"
                className="flex h-13 items-center rounded-[14px] bg-raised px-5 font-semibold text-fg no-underline hover:text-fg"
              >
                Back to my servers
              </Link>
            </div>
          </div>
          <div
            role="img"
            aria-label={`The JobTrigger app's server list with ${name} at the top, just added from the web`}
            className="flex flex-[0_1_240px] justify-center"
          >
            <div className="w-57.5 rounded-t-[38px] bg-raised px-2 pt-2 shadow-float">
              <div className="flex h-75 flex-col gap-2.5 rounded-t-[30px] bg-card px-3.5 pt-7">
                <span className="text-xs font-bold tracking-[0.06em] text-muted uppercase">
                  Servers
                </span>
                <span className="flex flex-col gap-1 rounded-2xl bg-running-bg p-3.5 ring-2 ring-accent">
                  <span className="truncate text-sm font-bold">{name}</span>
                  <span className="text-xs text-success-fg">✓ Just added from the web</span>
                </span>
                {others.slice(0, 2).map((other) => (
                  <span
                    key={other}
                    className="truncate rounded-2xl bg-raised p-3.5 text-sm text-fg-secondary"
                  >
                    {other}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>
      {!appLive && (
        <aside className="flex flex-wrap items-center gap-5 rounded-panel border border-line bg-card p-6">
          <span className="flex size-14 flex-none items-center justify-center rounded-2xl bg-raised text-fg-secondary">
            <svg
              width="26"
              height="26"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <rect x="6" y="2" width="12" height="20" rx="3" />
              <path d="M11 18h2" />
            </svg>
          </span>
          <div className="flex min-w-0 flex-[1_1_260px] flex-col gap-1.5">
            <h2 className="flex flex-wrap items-center gap-2.5 text-[1.0625rem] font-bold">
              The JobTrigger app is coming soon <StatusBadge feature="app-stores" />
            </h2>
            <p className="text-sm text-muted">
              Your server is saved and will be waiting when you install it on iPhone or Android.
            </p>
          </div>
          <Link href={routes.changelog} className="text-sm font-bold">
            Follow launch updates →
          </Link>
        </aside>
      )}
    </>
  );
}
