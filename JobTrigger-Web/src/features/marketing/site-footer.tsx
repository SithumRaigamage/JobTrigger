import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";
import { Container } from "@/components/layout";
import { statusOf } from "@/content/feature-status";

import { routes } from "./site-links";

type FooterLink = { href: string; label: string };

function LinkGroup({ title, links }: { title: string; links: FooterLink[] }) {
  return (
    <nav aria-label={title} className="flex flex-[1_1_140px] flex-col gap-3 text-sm">
      <span className="text-xs font-bold tracking-[0.08em] text-muted uppercase">{title}</span>
      {links.map((link) => (
        <Link
          key={link.label}
          href={link.href}
          className="text-fg-secondary no-underline hover:text-fg"
        >
          {link.label}
        </Link>
      ))}
    </nav>
  );
}

/**
 * The marketing footer (designs 16 / 25). The call-to-action card and the
 * Download / Launch updates link follow the `app-stores` status.
 */
export function SiteFooter() {
  const appLive = statusOf("app-stores") === "live";

  const product: FooterLink[] = [
    { href: routes.features, label: "Features" },
    { href: routes.integrations, label: "Integrations" },
    { href: routes.changelog, label: "Changelog" },
    appLive
      ? { href: routes.download, label: "Download" }
      : { href: routes.changelog, label: "Launch updates" },
  ];

  return (
    <footer data-surface="dark" className="border-t border-line bg-sunken">
      <Container className="flex flex-col gap-12 pt-16 pb-8">
        <div className="flex flex-wrap items-center justify-between gap-6 rounded-[20px] border border-line bg-card p-7">
          {appLive ? (
            <p className="text-[1.375rem] font-extrabold tracking-[-0.02em]">
              Your CI, in your pocket.
            </p>
          ) : (
            <p className="flex flex-col gap-1">
              <span className="text-[1.375rem] font-extrabold tracking-[-0.02em]">
                The app is coming soon.
              </span>
              <span className="text-sm text-muted">
                Set up your servers today — they&apos;ll be waiting.
              </span>
            </p>
          )}
          <Link
            href={appLive ? routes.download : routes.signIn}
            className="flex h-12 items-center rounded-full bg-accent px-5 text-[0.9375rem] font-bold text-on-accent no-underline hover:bg-accent-hover hover:text-on-accent"
          >
            {appLive ? "Get the app" : "Set up servers"}
          </Link>
        </div>

        <div className="flex flex-wrap gap-10">
          <div className="flex min-w-0 flex-[2_1_280px] flex-col gap-3.5">
            <BrandMark />
            <p className="max-w-75 text-sm leading-relaxed text-muted">
              Trigger and watch CI builds from your phone.
            </p>
          </div>
          <LinkGroup title="Product" links={product} />
          <LinkGroup
            title="Trust"
            links={[
              { href: routes.security, label: "Security" },
              { href: routes.privacy, label: "Privacy policy" },
              { href: routes.terms, label: "Terms of use" },
            ]}
          />
          <LinkGroup
            title="Help"
            links={[
              { href: routes.support, label: "Support" },
              { href: routes.requestTool, label: "Request a tool" },
              { href: routes.signIn, label: "Set up servers" },
            ]}
          />
        </div>

        <div className="flex flex-wrap justify-between gap-3 border-t border-line pt-5.5 text-[0.8125rem] text-muted">
          <span>© {new Date().getFullYear()} JobTrigger</span>
          <span>Jenkins, GitHub and SonarQube are trademarks of their respective owners.</span>
        </div>
      </Container>
    </footer>
  );
}
