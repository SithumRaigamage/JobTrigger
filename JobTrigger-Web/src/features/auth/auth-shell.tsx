import Link from "next/link";
import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand-mark";
import { Container } from "@/components/layout";

import { routes } from "../marketing/site-links";

/**
 * Sign-in / sign-up shell (designs 08, 09): a slanted dark band with an
 * accent stripe behind a pitch and a floating form, and a small legal nav.
 */
export function AuthShell({
  pitch,
  form,
  switcher,
}: {
  pitch: ReactNode;
  form: ReactNode;
  /** The "New to JobTrigger? / Already have an account?" card. */
  switcher?: ReactNode;
}) {
  return (
    <div className="relative flex min-h-screen flex-col overflow-hidden">
      <div
        aria-hidden="true"
        data-surface="dark"
        className="absolute inset-x-[-10%] -top-60 h-160 -skew-y-8"
      />
      <div aria-hidden="true" className="absolute inset-x-[-10%] top-90 h-6 -skew-y-8 bg-accent" />
      <Container className="relative flex flex-1 flex-col gap-14 pt-8 pb-16">
        <Link
          href={routes.home}
          data-surface="dark"
          className="self-start bg-transparent no-underline"
        >
          <BrandMark />
        </Link>
        <div className="flex flex-wrap items-start justify-center gap-12">
          <div
            data-surface="dark"
            className="flex max-w-120 min-w-0 flex-[1_1_380px] flex-col gap-4.5 bg-transparent pt-6"
          >
            {pitch}
          </div>
          <div className="flex max-w-115 min-w-0 flex-[1_1_400px] flex-col gap-4">
            {form}
            {switcher && (
              <div className="flex flex-wrap justify-between gap-3 rounded-card border border-line bg-card px-5.5 py-4.5 text-sm text-muted">
                {switcher}
              </div>
            )}
          </div>
        </div>
        <nav
          aria-label="Legal"
          className="mt-auto flex flex-wrap justify-center gap-5 text-[0.8125rem]"
        >
          <Link href={routes.privacy} className="text-muted">
            Privacy
          </Link>
          <Link href={routes.terms} className="text-muted">
            Terms
          </Link>
          <Link href={routes.support} className="text-muted">
            Support
          </Link>
          <span className="text-muted">© {new Date().getFullYear()} JobTrigger</span>
        </nav>
      </Container>
    </div>
  );
}

/** Shown instead of a form when the portal isn't configured on this deploy. */
export function PortalUnavailable({ title }: { title: string }) {
  return (
    <div className="flex flex-col gap-3 rounded-3xl bg-card p-7 shadow-lift sm:p-9">
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">{title}</h1>
      <p
        role="status"
        className="rounded-control bg-neutral-bg px-3.5 py-3 text-sm text-neutral-fg"
      >
        Server setup on the web isn&apos;t available right now. Please try again later.
      </p>
      <Link href={routes.support} className="self-start text-sm font-semibold">
        Get help →
      </Link>
    </div>
  );
}
