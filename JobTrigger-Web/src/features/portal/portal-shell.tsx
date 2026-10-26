import Link from "next/link";
import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand-mark";
import { statusOf } from "@/content/feature-status";

import { routes } from "../marketing/site-links";

import { signOutAction } from "./actions";
import { PortalNavLink } from "./portal-nav-link";

/** The signed-in layout (design 17 sidebar + content column). */
export function PortalShell({ email, children }: { email: string; children: ReactNode }) {
  const appLive = statusOf("app-stores") === "live";

  return (
    <div className="flex min-h-screen flex-wrap content-start md:content-stretch">
      <aside
        data-surface="dark"
        // Compact on phones: links in a row, account below, the card hidden, so
        // the page content starts on the first screen.
        className="flex max-w-full flex-[1_1_240px] flex-col gap-4 px-4 py-4 md:max-w-70 md:gap-7 md:py-6"
      >
        <Link href={routes.home} className="flex items-center gap-2.5 px-2 no-underline">
          <BrandMark />
          <span className="rounded-md bg-raised px-2 py-0.5 text-[0.6875rem] font-semibold text-muted">
            Setup
          </span>
        </Link>
        <nav
          aria-label="Portal"
          className="flex flex-row flex-wrap gap-1 text-[0.9375rem] font-medium md:flex-col"
        >
          <PortalNavLink href="/servers" glyph="▤" label="My servers" exact />
          <PortalNavLink href="/servers/new" glyph="+" label="Add server" />
          <PortalNavLink href="/account" glyph="◉" label="Account" />
          <PortalNavLink href={routes.support} glyph="?" label="Help" />
        </nav>
        <div className="hidden flex-col gap-2 rounded-2xl border border-line bg-card p-4 md:flex">
          <span className="text-[0.8125rem] font-bold">Open the app</span>
          <span className="text-xs leading-normal text-muted">
            {appLive
              ? "Everything you save here appears in JobTrigger on your phone."
              : "Everything you save here will be waiting in the JobTrigger app."}
          </span>
        </div>
        <div className="flex items-center gap-2.5 border-t border-line px-2 pt-3 md:mt-auto">
          <span
            aria-hidden="true"
            className="flex size-8.5 flex-none items-center justify-center rounded-full bg-running-bg text-sm font-bold text-running-fg"
          >
            {email.charAt(0).toUpperCase()}
          </span>
          <span
            className="min-w-0 flex-1 truncate font-mono text-xs text-fg-secondary"
            title={email}
          >
            {email}
          </span>
          <form action={signOutAction}>
            <button
              type="submit"
              aria-label="Sign out"
              className="flex size-11 flex-none items-center justify-center rounded-control bg-raised text-fg-secondary hover:text-fg"
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                <path d="m16 17 5-5-5-5" />
                <path d="M21 12H9" />
              </svg>
            </button>
          </form>
        </div>
      </aside>
      <main className="flex min-w-0 flex-[999_1_560px] flex-col gap-7 px-5 pt-10 pb-20 md:px-[clamp(20px,4vw,56px)]">
        {children}
      </main>
    </div>
  );
}
