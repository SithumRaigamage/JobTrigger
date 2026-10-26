"use client";

import { useState, type ReactNode } from "react";

import { cn } from "./cn";

const inputBox =
  "h-12.5 rounded-control border bg-card px-3.5 text-base text-fg outline-none focus-visible:outline-2 focus-visible:outline-accent";

/** A labelled text input with an optional hint or error below it. */
export function Field({
  id,
  label,
  error,
  hint,
  notice,
  aside,
  className,
  ...input
}: {
  id: string;
  label: string;
  error?: string;
  hint?: ReactNode;
  /** Always shown, even with an error, e.g. the http:// warning. */
  notice?: ReactNode;
  aside?: ReactNode;
} & React.InputHTMLAttributes<HTMLInputElement>) {
  const describedBy = error ? `${id}-error` : hint ? `${id}-hint` : undefined;
  return (
    <div className="flex flex-col gap-2">
      <div className="flex justify-between gap-3">
        <label htmlFor={id} className="text-[0.8125rem] font-semibold text-fg-secondary">
          {label}
        </label>
        {aside}
      </div>
      <input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={describedBy}
        {...input}
        className={cn(
          inputBox,
          error ? "border-2 border-failed-fg" : "border-line-strong",
          className,
        )}
      />
      {error ? (
        <span id={`${id}-error`} className="text-[0.8125rem] font-semibold text-failed-fg">
          {error}
        </span>
      ) : (
        hint && <span id={`${id}-hint`}>{hint}</span>
      )}
      {notice}
    </div>
  );
}

/** A password or token input with a show/hide toggle (designs 08, 11). */
export function PasswordField({
  id,
  label,
  error,
  aside,
  autoComplete,
  hint,
  secretName = "password",
  ...input
}: {
  id: string;
  label: string;
  error?: string;
  aside?: ReactNode;
  hint?: ReactNode;
  /** "off" for CI tokens (US-WEB-12); browsers may still offer to save. */
  autoComplete: "current-password" | "new-password" | "off";
  /** Name for the show/hide button, e.g. "token". */
  secretName?: string;
} & React.InputHTMLAttributes<HTMLInputElement>) {
  const [visible, setVisible] = useState(false);
  const describedBy = error ? `${id}-error` : hint ? `${id}-hint` : undefined;

  return (
    <div className="flex flex-col gap-2">
      <div className="flex justify-between gap-3">
        <label htmlFor={id} className="text-[0.8125rem] font-semibold text-fg-secondary">
          {label}
        </label>
        {aside}
      </div>
      <div
        className={cn(
          "flex h-12.5 items-center rounded-control border bg-card pr-1 pl-3.5 focus-within:outline-2 focus-within:outline-accent",
          error ? "border-2 border-failed-fg" : "border-line-strong",
        )}
      >
        <input
          id={id}
          type={visible ? "text" : "password"}
          autoComplete={autoComplete}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy}
          className="min-w-0 flex-1 bg-transparent text-base text-fg outline-none"
          {...input}
        />
        <button
          type="button"
          aria-label={`${visible ? "Hide" : "Show"} ${secretName}`}
          aria-pressed={visible}
          onClick={() => setVisible((shown) => !shown)}
          className="flex size-11 items-center justify-center text-muted"
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            aria-hidden="true"
          >
            <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
            <circle cx="12" cy="12" r="3" />
            {visible && <path d="M3 3l18 18" />}
          </svg>
        </button>
      </div>
      {error ? (
        <span id={`${id}-error`} className="text-[0.8125rem] font-semibold text-failed-fg">
          {error}
        </span>
      ) : (
        hint && <span id={`${id}-hint`}>{hint}</span>
      )}
    </div>
  );
}

/** The form's alert or status notice (design 08 Tweaks). */
export function Notice({ tone, children }: { tone: "info" | "error"; children: ReactNode }) {
  return (
    <div
      role={tone === "error" ? "alert" : "status"}
      className={cn(
        "rounded-control px-3.5 py-3 text-sm leading-normal",
        tone === "error"
          ? "bg-failed-bg font-semibold text-failed-fg"
          : "bg-running-bg text-running-fg",
      )}
    >
      {children}
    </div>
  );
}

/** The 52 px primary submit button, disabled while the action runs. */
export function SubmitButton({ pending, children }: { pending: boolean; children: ReactNode }) {
  return (
    <button
      type="submit"
      disabled={pending}
      className="flex h-13 items-center justify-center gap-2 rounded-[14px] bg-accent font-bold text-on-accent hover:bg-accent-hover disabled:cursor-progress disabled:opacity-70"
    >
      {children}
    </button>
  );
}
