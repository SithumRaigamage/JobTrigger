"use client";

import { useActionState, type ReactNode } from "react";

import { Notice } from "@/components/form";

import type { TeamActionState } from "./actions";

/*
 * US-SUB-11 (AC12, AC14): one small form per team action. The server action
 * does the work; this shows its error or confirmation next to the button.
 */

export type TeamAction = (state: TeamActionState, form: FormData) => Promise<TeamActionState>;

const primary =
  "h-11 rounded-full bg-accent px-5 text-[0.9375rem] font-bold text-on-accent hover:bg-accent-hover disabled:opacity-70";
const quiet =
  "h-10 rounded-full border border-line-strong bg-card px-4 text-sm font-semibold text-fg hover:bg-raised disabled:opacity-70";

export function TeamForm({
  action,
  label,
  pendingLabel,
  hidden = {},
  children,
  tone = "primary",
  confirm,
}: {
  action: TeamAction;
  label: string;
  pendingLabel?: string;
  /** Values the form sends without showing them (ids). */
  hidden?: Record<string, string>;
  children?: ReactNode;
  tone?: "primary" | "quiet";
  /** Asked before a destructive action. */
  confirm?: string;
}) {
  const [state, formAction, pending] = useActionState(action, {});
  return (
    <form
      action={formAction}
      onSubmit={(event) => {
        if (confirm && !window.confirm(confirm)) event.preventDefault();
      }}
      className="flex flex-col gap-3"
    >
      {Object.entries(hidden).map(([name, value]) => (
        <input key={name} type="hidden" name={name} value={value} />
      ))}
      {children}
      {state.error && <Notice tone="error">{state.error}</Notice>}
      {state.done && <Notice tone="info">{state.done}</Notice>}
      <button
        type="submit"
        disabled={pending}
        className={`${tone === "primary" ? primary : quiet} self-start`}
      >
        {pending ? (pendingLabel ?? label) : label}
      </button>
    </form>
  );
}
