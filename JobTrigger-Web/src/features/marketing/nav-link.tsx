"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/components/cn";

/** A main-nav link that marks itself as the current page. */
export function NavLink({ href, children }: { href: string; children: string }) {
  const pathname = usePathname();
  const current = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      aria-current={current ? "page" : undefined}
      className={cn(
        "py-2.5 no-underline",
        current
          ? "text-fg shadow-[inset_0_-2px_0_var(--color-accent)] hover:text-fg"
          : "text-fg-secondary hover:text-fg",
      )}
    >
      {children}
    </Link>
  );
}
