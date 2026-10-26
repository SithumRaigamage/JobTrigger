import Link from "next/link";
import type { ReactNode } from "react";

import { cn } from "@/components/cn";
import { Container, Kicker, Section } from "@/components/layout";
import { detail } from "@/content/site-details";

import { routes } from "../site-links";

const legalPages = [
  { href: routes.privacy, label: "Privacy policy" },
  { href: routes.terms, label: "Terms of use" },
  { href: routes.support, label: "Support" },
];

/**
 * Long-form legal layout (design 05): dark title band, a side nav of the
 * legal pages plus this page's sections, and a readable text column.
 */
export function LegalShell({
  title,
  current,
  toc,
  children,
}: {
  title: string;
  current: string;
  toc: { id: string; label: string }[];
  children: ReactNode;
}) {
  return (
    <main className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid>
        <Container className="flex flex-col gap-4 pt-20 pb-18">
          <Kicker>Legal</Kicker>
          <h1 className="text-h1 md:text-6xl">{title}</h1>
          <p className="text-sm text-muted">
            Last updated {detail("legalLastUpdated")} · Draft for legal review
          </p>
        </Container>
      </Section>

      <Container className="flex flex-wrap items-start gap-12 pt-16 pb-26">
        <nav
          aria-label="Legal pages"
          className="flex flex-[1_1_220px] flex-col gap-1 text-[0.9375rem]"
        >
          {legalPages.map((page) => (
            <Link
              key={page.href}
              href={page.href}
              aria-current={page.href === current ? "page" : undefined}
              className={cn(
                "rounded-[10px] px-3.5 py-2.5 no-underline",
                page.href === current
                  ? "bg-running-bg font-bold text-running-fg hover:text-running-fg"
                  : "text-fg-secondary hover:text-fg",
              )}
            >
              {page.label}
            </Link>
          ))}
          <span className="mt-4 px-3.5 py-1 text-xs font-bold tracking-[0.08em] text-muted uppercase">
            On this page
          </span>
          {toc.map((item) => (
            <a
              key={item.id}
              href={`#${item.id}`}
              className="px-3.5 py-1.5 text-sm text-fg-secondary no-underline hover:text-fg"
            >
              {item.label}
            </a>
          ))}
        </nav>
        <article className="flex max-w-190 min-w-0 flex-[999_1_560px] flex-col gap-9">
          {children}
        </article>
      </Container>
    </main>
  );
}

/** One titled section of a legal page. */
export function LegalSection({
  id,
  title,
  children,
}: {
  id: string;
  title: string;
  children: ReactNode;
}) {
  return (
    <section id={id} aria-labelledby={`${id}-heading`} className="flex scroll-mt-24 flex-col gap-3">
      <h2 id={`${id}-heading`} className="text-[1.625rem] font-extrabold tracking-[-0.02em]">
        {title}
      </h2>
      <div className="flex flex-col gap-3 leading-[1.7] text-fg-secondary">{children}</div>
    </section>
  );
}
