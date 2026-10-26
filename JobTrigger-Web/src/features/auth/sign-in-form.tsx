"use client";

import Link from "next/link";
import { useActionState } from "react";

import { Field, Notice, PasswordField, SubmitButton } from "@/components/form";

import { signInAction, type AuthFormState } from "./actions";

const initial: AuthFormState = {};

/** Sign-in form (design 08; US-WEB-10). */
export function SignInForm({
  notice,
  next,
  forgotHref,
}: {
  /** Why the user landed here, e.g. after the idle timeout (US-WEB-20). */
  notice: string | null;
  next: string | null;
  forgotHref: string;
}) {
  const [state, formAction, pending] = useActionState(signInAction, initial);

  return (
    <form
      action={formAction}
      noValidate
      className="flex flex-col gap-4.5 rounded-3xl bg-card p-7 shadow-lift sm:p-9"
    >
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Sign in</h1>
      {state.error ? (
        <Notice tone="error">{state.error}</Notice>
      ) : (
        notice && <Notice tone="info">{notice}</Notice>
      )}
      <Field
        id="email"
        name="email"
        label="Email"
        type="email"
        autoComplete="email"
        required
        defaultValue={state.email}
      />
      <PasswordField
        id="password"
        name="password"
        label="Password"
        autoComplete="current-password"
        required
        aside={
          <Link href={forgotHref} className="text-[0.8125rem] font-semibold">
            Forgot?
          </Link>
        }
      />
      {next && <input type="hidden" name="next" value={next} />}
      <SubmitButton pending={pending}>
        {pending ? "Signing in…" : "Sign in"}
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.4"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <path d="M5 12h14M13 6l6 6-6 6" />
        </svg>
      </SubmitButton>
    </form>
  );
}
