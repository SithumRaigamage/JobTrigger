"use client";

import Link from "next/link";
import { useActionState, useState } from "react";

import { cn } from "@/components/cn";
import { MIN_PASSWORD_LENGTH } from "@/domain/auth-validation";

import { Field, Notice, PasswordField, SubmitButton } from "@/components/form";

import { routes } from "../marketing/site-links";

import { signUpAction, type AuthFormState } from "./actions";

const initial: AuthFormState = {};

/** Sign-up form (design 09; US-WEB-10). */
export function SignUpForm() {
  const [state, formAction, pending] = useActionState(signUpAction, initial);
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");

  const longEnough = password.length >= MIN_PASSWORD_LENGTH;
  // Live feedback like the app's: only once there's something to compare.
  const mismatch = confirm.length > 0 && confirm !== password;

  return (
    <form
      action={formAction}
      noValidate
      className="flex flex-col gap-4.5 rounded-3xl bg-card p-7 shadow-lift sm:p-9"
    >
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Create your account</h1>
      {state.error && <Notice tone="error">{state.error}</Notice>}
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
      <PasswordField
        id="password"
        name="password"
        label="Password"
        autoComplete="new-password"
        required
        value={password}
        onChange={(event) => setPassword(event.target.value)}
        error={state.fields?.password}
        hint={
          <span
            className={cn(
              "flex items-center gap-2 text-[0.8125rem] font-semibold",
              longEnough ? "text-success-fg" : "text-muted",
            )}
          >
            <span
              aria-hidden="true"
              className={cn("h-1 flex-1 rounded-full", longEnough ? "bg-live-dot" : "bg-line")}
            />
            {longEnough ? "✓ " : ""}At least {MIN_PASSWORD_LENGTH} characters
          </span>
        }
      />
      <PasswordField
        id="confirm"
        name="confirm"
        label="Confirm password"
        autoComplete="new-password"
        required
        value={confirm}
        onChange={(event) => setConfirm(event.target.value)}
        error={mismatch ? "Passwords don't match." : state.fields?.confirm}
      />
      <SubmitButton pending={pending}>
        {pending ? "Creating account…" : "Create account"}
      </SubmitButton>
      <p className="text-[0.8125rem] leading-normal text-muted">
        By creating an account you agree to the <Link href={routes.terms}>terms</Link> and{" "}
        <Link href={routes.privacy}>privacy policy</Link>.
      </p>
    </form>
  );
}
