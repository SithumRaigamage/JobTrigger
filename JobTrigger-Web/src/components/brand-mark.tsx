import { cn } from "./cn";

/** The JobTrigger logo: a play glyph on an accent tile, plus the name. */
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
          "flex size-8.5 items-center justify-center rounded-[10px] bg-accent text-on-accent",
          glow && "ring-4 ring-accent/25",
        )}
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
          <path d="M8 5v14l11-7z" />
        </svg>
      </span>
      JobTrigger
    </span>
  );
}
