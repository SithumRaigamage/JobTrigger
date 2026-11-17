import { cn } from "./cn";

/**
 * The JobTrigger logo, Concept B (Phase 16): two pipeline stages joined to
 * a green run arrow on a navy tile, from UI-UX/brand/mark.svg, plus the
 * name. On a dark surface the tile gets a hairline (`--logo-outline`).
 */
export function BrandMark({ glow = false, className }: { glow?: boolean; className?: string }) {
  return (
    <span
      className={cn(
        "flex items-center gap-2.5 text-lg font-extrabold tracking-[-0.02em] text-fg",
        className,
      )}
    >
      <span
        className={cn(
          "flex size-8.5 shrink-0 rounded-[22%] outline-1 -outline-offset-1 outline-logo-outline",
          glow && "ring-4 ring-accent/25",
        )}
      >
        <LogoTile />
      </span>
      JobTrigger
    </span>
  );
}

/** The mark itself, on mark.svg's 128-unit grid. */
function LogoTile() {
  return (
    <svg viewBox="0 0 128 128" className="size-full" aria-hidden="true" focusable="false">
      <rect width="128" height="128" rx="28" className="fill-logo-tile" />
      <path
        d="M37 64 H48 M68 64 H78"
        fill="none"
        strokeWidth="6"
        strokeLinecap="round"
        className="stroke-logo-connector"
      />
      <circle cx="28" cy="64" r="9" fill="none" strokeWidth="6" className="stroke-logo-stage" />
      <circle cx="58" cy="64" r="9" fill="none" strokeWidth="6" className="stroke-logo-stage" />
      <path
        d="M84 46 L84 82 L108 64 Z"
        strokeWidth="6"
        strokeLinejoin="round"
        className="fill-logo-run stroke-logo-run"
      />
    </svg>
  );
}
