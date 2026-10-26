import type { ComponentProps, ReactNode } from "react";

import { cn } from "./cn";

type Surface = "light" | "dark";

/** The page column: 1240 px max, 20 px side gutter (UI-UX/Web designs). */
export function Container({ className, ...props }: ComponentProps<"div">) {
  return <div className={cn("mx-auto w-full max-w-310 px-5", className)} {...props} />;
}

type SectionProps = ComponentProps<"section"> & {
  /** Swaps every colour token inside it to the dark or light set. */
  surface?: Surface;
  /** The 28 px dot grid used behind dark heroes and bands. */
  dotGrid?: boolean;
};

export function Section({ surface = "light", dotGrid = false, className, ...props }: SectionProps) {
  return (
    <section
      data-surface={surface}
      className={cn(dotGrid && "bg-dot-grid", className)}
      {...props}
    />
  );
}

export function Card({ className, ...props }: ComponentProps<"div">) {
  return (
    <div
      className={cn("rounded-card border border-line bg-card shadow-card", className)}
      {...props}
    />
  );
}

/** The small uppercase label above a section heading. */
export function Kicker({ children, className }: { children: ReactNode; className?: string }) {
  return <p className={cn("text-kicker text-link uppercase", className)}>{children}</p>;
}
