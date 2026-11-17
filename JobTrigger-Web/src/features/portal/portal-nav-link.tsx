"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/components/cn";

/** A sidebar link that marks itself current (design 17). */
export function PortalNavLink({
  href,
  glyph,
  label,
  exact = false,
}: {
  href: string;
  glyph: string;
  label: string;
  /** Only the exact path counts (My servers vs its sub-pages). */
  exact?: boolean;
}) {
  const pathname = usePathname();
  const current = exact ? pathname === href : pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      aria-current={current ? "page" : undefined}
      className={cn(
        "flex min-h-11 items-center gap-3 rounded-control px-2.5 no-underline",
        current
          ? "bg-running-bg font-semibold text-fg hover:text-fg"
          : "text-fg-secondary hover:text-fg",
      )}
    >
      <span
        aria-hidden="true"
        className={cn(
          "flex size-7 flex-none items-center justify-center rounded-lg text-sm font-extrabold",
          current ? "bg-accent text-on-accent" : "bg-raised text-fg-secondary",
        )}
      >
        {glyph}
      </span>
      {label}
    </Link>
  );
}
