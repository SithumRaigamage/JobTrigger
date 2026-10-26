import {
  statusLabels,
  statusOf,
  type FeatureId,
  type FeatureStatus,
} from "@/content/feature-status";

import { cn } from "./cn";

type Size = "sm" | "md";

// Token pairs, so a badge adapts to the light or dark section it sits in.
// Status is never colour alone: the label is always the text (US-WEB-22).
const tones: Record<Exclude<FeatureStatus, "live">, string> = {
  beta: "bg-running-bg text-running-fg",
  soon: "bg-neutral-bg text-neutral-fg",
  planned: "border border-dashed border-muted text-neutral-fg",
};

const sizes: Record<Size, string> = {
  sm: "px-2 py-0.5 text-[0.6875rem]",
  md: "px-3 py-1 text-[0.8125rem]",
};

// Inside a control drawn on the page colour (FeatureAction), the slate
// pill would vanish on light; the design uses the hairline colour instead.
const insetTones: typeof tones = { ...tones, soon: "bg-line text-neutral-fg" };

/** The feature's status pill, or nothing when it's `live`. */
export function StatusBadge({
  feature,
  size = "sm",
  inset = false,
  className,
}: {
  feature: FeatureId;
  size?: Size;
  /** Sits inside a page-coloured control rather than on a section. */
  inset?: boolean;
  className?: string;
}) {
  const status = statusOf(feature);
  if (status === "live") return null;

  return (
    <span
      className={cn(
        "inline-flex shrink-0 items-center rounded-full leading-tight font-bold whitespace-nowrap",
        (inset ? insetTones : tones)[status],
        sizes[size],
        className,
      )}
    >
      {statusLabels[status]}
    </span>
  );
}
