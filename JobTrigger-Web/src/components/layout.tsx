import type { ComponentProps, ReactNode } from "react";

import { cn } from "./cn";

type Surface = "light" | "dark";

const containerWidths = {
  /** 1240 px: most pages. */
  page: "max-w-310",
  /** 1040 px: Changelog. */
  medium: "max-w-260",
  /** 960 px: Support. */
  narrow: "max-w-240",
};

/**
 * The page column with a 20 px side gutter (UI-UX/Web designs). Width is a
 * prop, not a className override: `cn` joins classes without resolving
 * conflicts, so two max-w-* classes would race on CSS order.
 */
export function Container({
  width = "page",
  className,
  ...props
}: ComponentProps<"div"> & { width?: keyof typeof containerWidths }) {
  return (
    <div className={cn("mx-auto w-full px-5", containerWidths[width], className)} {...props} />
  );
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

const cardRadii = {
  card: "rounded-card", // 18 px
  lg: "rounded-[20px]",
  panel: "rounded-panel", // 22 px
  xl: "rounded-3xl", // 24 px
};

/** A bordered card. Radius and shadow are props for the same reason as Container's width. */
export function Card({
  radius = "card",
  flat = false,
  className,
  ...props
}: ComponentProps<"div"> & { radius?: keyof typeof cardRadii; flat?: boolean }) {
  return (
    <div
      className={cn(
        "border border-line bg-card",
        cardRadii[radius],
        !flat && "shadow-card",
        className,
      )}
      {...props}
    />
  );
}

/** The small uppercase label above a section heading. */
export function Kicker({ children, className }: { children: ReactNode; className?: string }) {
  return <p className={cn("text-kicker text-link uppercase", className)}>{children}</p>;
}
