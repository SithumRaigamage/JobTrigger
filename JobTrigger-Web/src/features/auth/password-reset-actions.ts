"use server";

import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { isValidEmail, newPasswordProblem } from "@/domain/auth-validation";
import { confirmPasswordReset, requestPasswordReset } from "@/server/auth-api";
import { getSession } from "@/server/session";

/*
 * Forgot / reset password on the web (US-AUTH-08, P20-74). Server actions
 * like sign-in: the browser posts, this server calls the backend. The reset
 * token travels browser → this server → backend and is never logged or
 * returned in the form state.
 */

export type ForgotFormState = {
  error?: string;
  fields?: { email?: string };
  email?: string;
  /** True once the backend accepted the request. */
  sent?: boolean;
};

const forgotForm = z.object({ email: z.string().trim() });

export async function forgotPasswordAction(
  _previous: ForgotFormState,
  form: FormData,
): Promise<ForgotFormState> {
  const parsed = forgotForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: "Enter your email." };
  const { email } = parsed.data;
  if (!isValidEmail(email)) return { fields: { email: "Enter a valid email address" }, email };

  const result = await requestPasswordReset(email);
  if (!result.ok) return { error: failureMessage(result.failure), email };
  return { sent: true, email };
}

export type ResetFormState = {
  error?: string;
  fields?: { password?: string; confirm?: string };
  /** True once the password was changed. */
  done?: boolean;
};

const resetForm = z.object({
  token: z.string().regex(/^[a-f0-9]{64}$/),
  password: z.string(),
  confirm: z.string(),
});

export async function resetPasswordAction(
  _previous: ResetFormState,
  form: FormData,
): Promise<ResetFormState> {
  const parsed = resetForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) {
    return { error: "This reset link is invalid or has expired. Ask for a new one." };
  }
  const { token, password, confirm } = parsed.data;

  const fields: ResetFormState["fields"] = {};
  const problem = newPasswordProblem(password);
  if (problem) fields.password = problem;
  if (password !== confirm) fields.confirm = "Passwords don't match.";
  if (Object.keys(fields).length > 0) return { fields };

  const result = await confirmPasswordReset(token, password);
  if (!result.ok) return { error: failureMessage(result.failure) };

  // Every session was signed out by the reset; drop this browser's too.
  const session = await getSession();
  session.destroy();
  return { done: true };
}
