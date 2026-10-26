import Link from "next/link";
import type { ReactNode } from "react";

import widgetShot from "@/assets/screens/widget-notification.png";
import { cn } from "@/components/cn";
import { Container, Section } from "@/components/layout";
import { StaticImage } from "@/components/static-image";
import { StatusBadge } from "@/components/status-badge";
import { statusOf } from "@/content/feature-status";

import { routes, storeLinks } from "../site-links";

const phoneIcon = (
  <svg
    width="22"
    height="22"
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
);

const playIcon = (
  <svg
    width="22"
    height="22"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.8"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    <path d="M5 3l14 9-14 9z" />
  </svg>
);

/**
 * A store button. Links only with a URL; otherwise the dashed disabled
 * control (US-WEB-22): an aria-disabled button, never a dead link.
 */
function StoreButton({
  href,
  icon,
  caption,
  store,
}: {
  href: string | null;
  icon: ReactNode;
  caption: string;
  store: string;
}) {
  const body = (
    <>
      {icon}
      <span className="flex flex-col text-left leading-[1.15]">
        {/* The space keeps the accessible name "Coming soon to the App Store"
            rather than "…theApp Store"; the flex column ignores it. */}
        <span className="text-[0.6875rem]">{caption}</span>{" "}
        <span className="text-lg font-bold">{store}</span>
      </span>
    </>
  );
  const shape = "flex h-14 items-center gap-3 rounded-control px-5";

  if (href) {
    return (
      <a href={href} className={cn(shape, "bg-on-accent text-page no-underline hover:text-page")}>
        {body}
      </a>
    );
  }
  return (
    <button
      type="button"
      aria-disabled="true"
      className={cn(shape, "cursor-not-allowed border border-dashed border-line-strong text-muted")}
    >
      {body}
    </button>
  );
}

/**
 * Download (designs 01 / 18; US-WEB-02). Before launch: "coming soon",
 * disabled store buttons, and web setup as the action. At launch: the
 * store buttons. The QR code follows once real store URLs exist (P15-24).
 */
export function Download() {
  const appLive = statusOf("app-stores") === "live";
  const appStore = appLive ? storeLinks.appStore : null;
  const googlePlay = appLive ? storeLinks.googlePlay : null;

  return (
    <Section id="download" surface="dark" dotGrid aria-labelledby="download-heading">
      <Container className="flex flex-wrap items-center justify-between gap-12 py-28">
        <div className="flex min-w-0 flex-[1_1_480px] flex-col gap-5.5">
          {!appLive && <StatusBadge feature="app-stores" size="md" className="self-start" />}
          <h2
            id="download-heading"
            className="text-h2 leading-none tracking-[-0.045em] md:text-[4rem]"
          >
            {appLive ? (
              <>
                Your next build
                <br />
                is <span className="text-running-fg">one tap away.</span>
              </>
            ) : (
              <>
                Coming soon to
                <br />
                <span className="text-running-fg">iPhone and Android.</span>
              </>
            )}
          </h2>
          <p className="max-w-130 text-lg leading-relaxed text-fg-secondary">
            {appLive
              ? "Free on iPhone and Android."
              : "The app is in its final stretch. Set up your servers on the web today — they'll be waiting the moment you install it."}
          </p>

          <div className="flex flex-wrap gap-3">
            <StoreButton
              href={appStore}
              icon={phoneIcon}
              caption={appStore ? "Download on the" : "Coming soon to the"}
              store="App Store"
            />
            <StoreButton
              href={googlePlay}
              icon={playIcon}
              caption={googlePlay ? "Get it on" : "Coming soon to"}
              store="Google Play"
            />
          </div>

          {!appLive && (
            <div className="flex flex-wrap items-center gap-5">
              <Link
                href={routes.signIn}
                className="flex h-13 items-center rounded-[14px] bg-accent px-5.5 font-bold text-on-accent no-underline hover:bg-accent-hover hover:text-on-accent"
              >
                Set up your servers now
              </Link>
              <Link href={routes.changelog} className="text-[0.9375rem] font-semibold">
                Follow launch updates →
              </Link>
            </div>
          )}
        </div>

        <div className="mx-auto w-50 flex-none rounded-[36px] bg-raised p-2 shadow-device md:mx-0">
          <StaticImage
            image={widgetShot}
            alt="JobTrigger home-screen widget"
            className="block h-auto w-full rounded-[28px]"
          />
        </div>
      </Container>
    </Section>
  );
}
