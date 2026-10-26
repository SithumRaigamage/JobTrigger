import Link from "next/link";
import type { ComponentProps, ReactNode } from "react";

import { cn } from "./cn";

type Variant = "primary" | "secondary" | "ghost";
type Size = "md" | "lg";

const base =
  "inline-flex min-h-11 items-center justify-center gap-2 rounded-control font-semibold no-underline transition-colors";

const variants: Record<Variant, string> = {
  primary: "bg-accent text-on-accent hover:bg-accent-hover hover:text-on-accent",
  secondary: "border border-line bg-card text-fg hover:bg-raised hover:text-fg",
  ghost: "text-fg hover:bg-raised hover:text-fg",
};

const sizes: Record<Size, string> = {
  md: "px-4 text-sm",
  // 52 px, the app's primary button height.
  lg: "h-13 px-6 text-base",
};

type CommonProps = {
  variant?: Variant;
  size?: Size;
  className?: string;
  children: ReactNode;
};

type ButtonProps = CommonProps & {
  href?: undefined;
  /**
   * Renders `aria-disabled` rather than the `disabled` attribute, so the
   * button stays focusable and screen readers can announce why it's off
   * (US-WEB-22). A disabled button is always `type="button"` with no
   * click handler, so it never submits or acts.
   */
  disabled?: boolean;
} & Omit<ComponentProps<"button">, "disabled" | "className" | "children">;

/** A link styled as a button. Links can't be disabled: render a button. */
type LinkProps = CommonProps & {
  href: string;
  disabled?: never;
} & Omit<ComponentProps<typeof Link>, "href" | "className" | "children">;

export function Button({
  variant = "primary",
  size = "md",
  className,
  children,
  ...rest
}: ButtonProps | LinkProps) {
  const classes = cn(base, variants[variant], sizes[size], className);

  if (rest.href !== undefined) {
    return (
      <Link className={classes} {...rest}>
        {children}
      </Link>
    );
  }

  const { disabled, onClick, type = "button", ...buttonProps } = rest;
  return (
    <button
      {...buttonProps}
      type={disabled ? "button" : type}
      onClick={disabled ? undefined : onClick}
      aria-disabled={disabled || undefined}
      className={cn(classes, disabled && "cursor-not-allowed opacity-55")}
    >
      {children}
    </button>
  );
}
