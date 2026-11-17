import { useId, type ReactNode } from "react";

import { isActionable, type FeatureId } from "@/content/feature-status";

import { cn } from "./cn";
import { StatusBadge } from "./status-badge";

type Size = "md" | "lg";

const sizes: Record<Size, string> = {
  md: "min-h-11 px-4 text-sm",
  lg: "h-13 px-5 text-[0.9375rem]",
};

type FeatureActionProps = {
  feature: FeatureId;
  /** The real action, rendered as-is when the feature can be used. */
  children: ReactNode;
  /** What the disabled control says, e.g. "Test connection". */
  label: string;
  /** Why it's off, shown under it and announced with it. */
  reason?: string;
  size?: Size;
  className?: string;
};

/**
 * Renders an action only if its feature is usable (`live` or `beta`).
 * Otherwise a disabled control with the same footprint: dashed, muted,
 * badged and explained (US-WEB-22 "Disabled actions"). It's a
 * non-submitting button, never a link, so there's no dead URL.
 */
export function FeatureAction({
  feature,
  children,
  label,
  reason,
  size = "lg",
  className,
}: FeatureActionProps) {
  const reasonId = useId();
  if (isActionable(feature)) return children;

  return (
    <div className="flex flex-col gap-2">
      <button
        type="button"
        aria-disabled="true"
        aria-describedby={reason ? reasonId : undefined}
        className={cn(
          "inline-flex cursor-not-allowed items-center justify-center gap-2.5 self-start rounded-control border border-dashed border-muted bg-page font-semibold text-muted",
          sizes[size],
          className,
        )}
      >
        {/* The space keeps the accessible name "Test connection Coming soon",
            not "…connectionComing soon"; flex layout ignores it. */}
        {label} <StatusBadge feature={feature} inset />
      </button>
      {reason && (
        <p id={reasonId} className="text-[0.8125rem] text-muted">
          {reason}
        </p>
      )}
    </div>
  );
}
