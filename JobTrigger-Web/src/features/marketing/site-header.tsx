import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";
import { Container } from "@/components/layout";
import { statusOf } from "@/content/feature-status";

import { NavLink } from "./nav-link";
import { mainNav, routes } from "./site-links";

const pill =
  "flex h-11 items-center gap-2 rounded-full bg-fg px-4.5 text-[0.9375rem] font-bold text-page no-underline hover:bg-fg-secondary hover:text-page";

function ArrowIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

/**
 * The marketing header (designs 15 / 24). Until the app is in the stores
 * (`app-stores` not live) it shows the pre-launch actions; flipping that
 * status switches every page to "Sign in" + "Get the app".
 */
export function SiteHeader() {
  const appLive = statusOf("app-stores") === "live";

  return (
    <header
      data-surface="dark"
      // Sticky from md up only: on a phone the wrapped header is ~150 px tall
      // and would cover a fifth of the screen.
      className="top-0 z-40 border-b border-line bg-page/92 backdrop-blur md:sticky"
    >
      <Container className="flex min-h-18 flex-wrap items-center gap-x-4 gap-y-1 py-3 md:gap-x-10">
        <Link href={routes.home} className="no-underline" aria-label="JobTrigger home">
          <BrandMark glow />
        </Link>
        {/* Wraps to its own row on narrow screens (owner decision, P15-05). */}
        <nav
          aria-label="Main"
          className="order-last flex w-full flex-wrap gap-x-7 gap-y-1 text-[0.9375rem] font-medium md:order-none md:w-auto"
        >
          {mainNav.map((item) => (
            <NavLink key={item.href} href={item.href}>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-2">
          {appLive ? (
            <>
              <Link
                href={routes.signIn}
                className="flex h-11 items-center px-3.5 text-[0.9375rem] font-semibold text-fg no-underline hover:text-fg-secondary"
              >
                Sign in
              </Link>
              <Link href={routes.download} className={pill}>
                Get the app <ArrowIcon />
              </Link>
            </>
          ) : (
            <>
              <span className="hidden rounded-full bg-neutral-bg px-2.5 py-1 text-xs font-bold text-neutral-fg sm:inline">
                App coming soon
              </span>
              <Link href={routes.signIn} className={pill}>
                Set up servers <ArrowIcon />
              </Link>
            </>
          )}
        </div>
      </Container>
    </header>
  );
}
