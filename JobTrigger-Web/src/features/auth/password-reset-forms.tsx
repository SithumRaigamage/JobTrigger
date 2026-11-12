"use client";

import Link from "next/link";
import { useActionState } from "react";

import { Field, Notice, PasswordField, SubmitButton } from "@/components/form";

import {
  forgotPasswordAction,
  resetPasswordAction,
  type ForgotFormState,
  type ResetFormState,
} from "./password-reset-actions";

const cardClass = "flex flex-col gap-4.5 rounded-3xl bg-card p-7 shadow-lift sm:p-9";
const titleClass = "text-[1.625rem] font-extrabold tracking-[-0.02em]";

/** "Forgot password?" — asks for the email (US-AUTH-08). */
export function ForgotPasswordForm() {
  const [state, formAction, pending] = useActionState(forgotPasswordAction, {} as ForgotFormState);

  if (state.sent) {
    return (
      <div className={cardClass}>
        <h1 className={titleClass}>Check your inbox</h1>
        {/* Worded so it never confirms whether the email has an account. */}
        <Notice tone="info">
          If an account exists for {state.email}, we&apos;ve sent it a link to reset the password.
          The link works once and expires in 15 minutes.
        </Notice>
        <Link href="/sign-in" className="self-start text-sm font-semibold">
          Back to sign in →
        </Link>
      </div>
    );
  }

  return (
    <form action={formAction} noValidate className={cardClass}>
      <h1 className={titleClass}>Reset your password</h1>
      {state.error ? (
        <Notice tone="error">{state.error}</Notice>
      ) : (
        <p className="text-sm text-muted">
          Enter the email you sign in with. We&apos;ll send you a link to choose a new password.
        </p>
      )}
      <Field
        id="email"
        name="email"
        label="Email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state.email}
        error={state.fields?.email}
      />
      <SubmitButton pending={pending}>{pending ? "Sending…" : "Send reset link"}</SubmitButton>
    </form>
  );
}

/** The emailed link's page: choose a new password (US-AUTH-08). */
export function ResetPasswordForm({ token }: { token: string }) {
  const [state, formAction, pending] = useActionState(resetPasswordAction, {} as ResetFormState);

  if (state.done) {
    return (
      <div className={cardClass}>
        <h1 className={titleClass}>Password reset</h1>
        <Notice tone="info">
          You&apos;ve been signed out on every device. Sign in with your new password.
        </Notice>
        <Link href="/sign-in" className="self-start text-sm font-semibold">
          Sign in →
        </Link>
      </div>
    );
  }

  return (
    <form action={formAction} noValidate className={cardClass}>
      <h1 className={titleClass}>Choose a new password</h1>
      {state.error ? (
        <Notice tone="error">{state.error}</Notice>
      ) : (
        <p className="text-sm text-muted">
          At least 8 characters. Resetting signs you out on every device.
        </p>
      )}
      <input type="hidden" name="token" value={token} />
      <PasswordField
        id="password"
        name="password"
        label="New password"
        autoComplete="new-password"
        required
        error={state.fields?.password}
      />
      <PasswordField
        id="confirm"
        name="confirm"
        label="Confirm new password"
        autoComplete="new-password"
        required
        error={state.fields?.confirm}
      />
      <SubmitButton pending={pending}>{pending ? "Saving…" : "Reset password"}</SubmitButton>
    </form>
  );
}

/** A link that can't be a reset link: no form, just a way forward. */
export function InvalidResetLink() {
  return (
    <div className={cardClass}>
      <h1 className={titleClass}>This link doesn&apos;t work</h1>
      <Notice tone="error">
        It may be incomplete, used already, or expired. Ask for a new one.
      </Notice>
      <Link href="/forgot-password" className="self-start text-sm font-semibold">
        Ask for a new link →
      </Link>
    </div>
  );
}
