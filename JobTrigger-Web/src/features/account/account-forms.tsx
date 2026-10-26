"use client";

import { useActionState, useRef, useState } from "react";

import { Field, Notice, PasswordField } from "@/components/form";

import {
  changePasswordAction,
  deleteAccountAction,
  signOutEverywhereAction,
  type AccountState,
} from "./actions";

const card = "flex flex-col gap-4 rounded-panel border bg-card p-6.5";

/** The small tinted icon before a card heading (design 14). */
function HeadingIcon({ tone, path }: { tone: string; path: React.ReactNode }) {
  return (
    <span
      aria-hidden="true"
      className={`flex size-8.5 flex-none items-center justify-center rounded-[10px] ${tone}`}
    >
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        {path}
      </svg>
    </span>
  );
}
const secondaryButton =
  "h-11 self-start rounded-control border border-line-strong bg-card px-4 text-sm font-semibold text-fg hover:bg-raised disabled:opacity-70";

export function ChangePassword() {
  const [state, formAction, pending] = useActionState(changePasswordAction, {} as AccountState);
  const [values, setValues] = useState({ current: "", next: "", confirm: "" });
  const set = (key: keyof typeof values) => (event: React.ChangeEvent<HTMLInputElement>) =>
    setValues((v) => ({ ...v, [key]: event.target.value }));

  return (
    <section
      aria-labelledby="password-heading"
      className={`${card} min-w-0 flex-[1_1_360px] border-line shadow-card`}
    >
      <h2 id="password-heading" className="flex items-center gap-2.5 text-[1.0625rem] font-bold">
        <HeadingIcon
          tone="bg-running-bg text-running-fg"
          path={
            <>
              <rect x="4" y="10" width="16" height="11" rx="2" />
              <path d="M8 10V7a4 4 0 0 1 8 0v3" />
            </>
          }
        />
        Change password
      </h2>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      {state.done && !pending && (
        <p
          role="status"
          className="rounded-control bg-success-bg px-3.5 py-3 text-sm font-semibold text-success-fg"
        >
          Password changed. Other devices were signed out.
        </p>
      )}
      <form action={formAction} noValidate className="flex flex-col gap-4">
        <PasswordField
          id="current"
          name="current"
          label="Current password"
          autoComplete="current-password"
          value={values.current}
          onChange={set("current")}
        />
        <PasswordField
          id="next"
          name="next"
          label="New password"
          autoComplete="new-password"
          value={values.next}
          onChange={set("next")}
          hint={<span className="text-[0.8125rem] text-muted">At least 8 characters.</span>}
        />
        <PasswordField
          id="confirm"
          name="confirm"
          label="Confirm new password"
          autoComplete="new-password"
          value={values.confirm}
          onChange={set("confirm")}
        />
        <button
          type="submit"
          disabled={pending}
          className="h-12 self-start rounded-control bg-accent px-5 text-[0.9375rem] font-bold text-on-accent hover:bg-accent-hover disabled:opacity-70"
        >
          {pending ? "Updating…" : "Update password"}
        </button>
      </form>
    </section>
  );
}

export function SignOutEverywhere() {
  const dialog = useRef<HTMLDialogElement>(null);
  const [state, formAction, pending] = useActionState(signOutEverywhereAction, {} as AccountState);

  return (
    <section aria-labelledby="sessions-heading" className={`${card} gap-3 border-line shadow-card`}>
      <h2 id="sessions-heading" className="flex items-center gap-2.5 text-[1.0625rem] font-bold">
        <HeadingIcon
          tone="bg-unstable-bg text-unstable-fg"
          path={
            <>
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <path d="m16 17 5-5-5-5" />
              <path d="M21 12H9" />
            </>
          }
        />
        Sign out everywhere
      </h2>
      <p className="text-sm leading-[1.55] text-muted">
        Signs out this browser and the app on every phone. Use it if a device is lost.
      </p>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <button type="button" onClick={() => dialog.current?.showModal()} className={secondaryButton}>
        Sign out all devices
      </button>
      <dialog
        ref={dialog}
        aria-labelledby="everywhere-heading"
        aria-describedby="everywhere-description"
        className="m-auto w-[min(440px,calc(100vw-40px))] rounded-panel bg-card p-7 text-fg backdrop:bg-scrim"
      >
        <form action={formAction} className="flex flex-col gap-4">
          <h2 id="everywhere-heading" className="text-xl font-extrabold">
            Sign out of all devices?
          </h2>
          {/* The app's warning (profile_screen.dart), in the site's wording. */}
          <p id="everywhere-description" className="text-sm leading-normal text-muted">
            Every device signed in to this account, including this one, will need to sign in again.
          </p>
          <div className="flex flex-wrap justify-end gap-2.5">
            <button
              type="button"
              autoFocus
              onClick={() => dialog.current?.close()}
              className={secondaryButton}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={pending}
              className="h-11 rounded-control bg-failed-fg px-4 text-sm font-bold text-on-accent disabled:opacity-70"
            >
              {pending ? "Signing out…" : "Sign out everywhere"}
            </button>
          </div>
        </form>
      </dialog>
    </section>
  );
}

export function DeleteAccount({ email }: { email: string }) {
  const [state, formAction, pending] = useActionState(deleteAccountAction, {} as AccountState);
  const [typed, setTyped] = useState("");
  const [password, setPassword] = useState("");
  const confirmed = typed.trim().toLowerCase() === email.toLowerCase() && password.length > 0;

  return (
    <section aria-labelledby="danger-heading" className={`${card} gap-3.5 border-failed-fg/40`}>
      <h2
        id="danger-heading"
        className="flex items-center gap-2.5 text-[1.0625rem] font-bold text-failed-fg"
      >
        <span
          aria-hidden="true"
          className="flex size-8.5 items-center justify-center rounded-[10px] bg-failed-bg font-extrabold"
        >
          !
        </span>
        Delete account
      </h2>
      <p className="text-sm leading-[1.55] text-muted">
        Deletes your account and every saved server. Your CI servers aren&apos;t affected.
      </p>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <form action={formAction} noValidate className="flex flex-col gap-3.5">
        <Field
          id="delete-email"
          name="email"
          type="email"
          label="Type your email to confirm"
          autoComplete="off"
          placeholder={email}
          className="font-mono"
          value={typed}
          onChange={(event) => setTyped(event.target.value)}
        />
        <PasswordField
          id="delete-password"
          name="password"
          label="Password"
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
        <button
          type="submit"
          aria-disabled={!confirmed || undefined}
          disabled={pending}
          onClick={(event) => {
            if (!confirmed) event.preventDefault();
          }}
          className="h-11.5 self-start rounded-control border border-failed-fg bg-card px-4.5 text-sm font-semibold text-failed-fg hover:bg-failed-bg aria-disabled:cursor-not-allowed aria-disabled:opacity-60"
        >
          {pending ? "Deleting…" : "Delete my account"}
        </button>
      </form>
    </section>
  );
}
