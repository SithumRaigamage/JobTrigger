"use server";

import { redirect } from "next/navigation";
import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { isValidEmail, newPasswordProblem } from "@/domain/auth-validation";
import { login, signup } from "@/server/auth-api";
import { getSession, setTokens } from "@/server/session";

import { safeNext } from "./safe-next";

/*
 * Sign in and sign up (US-WEB-10). Server actions: the browser posts the
 * form, the server calls the backend and sets the session cookie. Tokens
 * never reach browser JavaScript. Next checks the action's Origin against
 * the host, and the cookie is SameSite=Lax (docs/web-architecture.md §5).
 */

export type AuthFormState = {
  /** Shown in the form's alert: AppFailure or validation copy. */
  error?: string;
  /** Per-field problems from server-side validation. */
  fields?: { email?: string; password?: string; confirm?: string };
  /** What the user typed, so a failed attempt keeps it. Never the password. */
  email?: string;
};

const signInForm = z.object({
  email: z.string().trim().min(1),
  password: z.string().min(1),
  next: z.string().optional(),
});

export async function signInAction(
  _previous: AuthFormState,
  form: FormData,
): Promise<AuthFormState> {
  const parsed = signInForm.safeParse(Object.fromEntries(form));
  if (!parsed.success)
    return { error: "Enter your email and password.", email: String(form.get("email") ?? "") };
  const { email, password, next } = parsed.data;

  const result = await login(email, password);
  if (!result.ok) return { error: failureMessage(result.failure), email };

  const session = await getSession();
  setTokens(session, result.value);
  await session.save();
  redirect(safeNext(next));
}

const signUpForm = z.object({
  email: z.string().trim(),
  password: z.string(),
  confirm: z.string(),
});

export async function signUpAction(
  _previous: AuthFormState,
  form: FormData,
): Promise<AuthFormState> {
  const parsed = signUpForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: "Fill in every field." };
  const { email, password, confirm } = parsed.data;

  const fields: AuthFormState["fields"] = {};
  if (!isValidEmail(email)) fields.email = "Enter a valid email address";
  const passwordProblem = newPasswordProblem(password);
  if (passwordProblem) fields.password = passwordProblem;
  if (password !== confirm) fields.confirm = "Passwords don't match.";
  if (Object.keys(fields).length > 0) return { fields, email };

  const result = await signup(email, password);
  if (!result.ok) return { error: failureMessage(result.failure), email };

  const session = await getSession();
  setTokens(session, result.value);
  await session.save();
  redirect("/servers/new");
}
