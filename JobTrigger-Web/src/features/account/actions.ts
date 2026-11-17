"use server";

import { redirect } from "next/navigation";
import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { MIN_PASSWORD_LENGTH, newPasswordProblem } from "@/domain/auth-validation";
import { changePassword, deleteAccount, logoutAll } from "@/server/auth-api";
import { authed } from "@/server/authed";
import { requireSession } from "@/server/guard";
import { setTokens } from "@/server/session";

/*
 * Account actions (US-WEB-20, US-WEB-21), with the app's rules and copy
 * (auth_notifier.dart, profile_screen.dart, account_dialogs.dart). Both
 * password-protected actions re-check the current password on the backend
 * even with a valid session (AUD-48).
 */

export type AccountState = { error?: string; done?: boolean };

const passwordForm = z.object({ current: z.string(), next: z.string(), confirm: z.string() });

export async function changePasswordAction(
  _previous: AccountState,
  form: FormData,
): Promise<AccountState> {
  const session = await requireSession();
  const parsed = passwordForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: "Enter your current password." };
  const { current, next, confirm } = parsed.data;

  if (!current) return { error: "Enter your current password." };
  if (next.length < MIN_PASSWORD_LENGTH) {
    return { error: `The new password needs at least ${MIN_PASSWORD_LENGTH} characters.` };
  }
  const problem = newPasswordProblem(next);
  if (problem) return { error: problem };
  if (next !== confirm) return { error: "The new passwords don't match." };

  const result = await authed(session, (token) => changePassword(token, current, next));
  if (!result.ok) return { error: failureMessage(result.failure) };

  // The backend revoked every session and returned a fresh pair for this one.
  setTokens(session, result.value);
  await session.save();
  return { done: true };
}

/** Revokes every session on every device, this browser included (US-WEB-20). */
export async function signOutEverywhereAction(_previous: AccountState): Promise<AccountState> {
  const session = await requireSession();
  const result = await authed(session, (token) => logoutAll(token));
  if (!result.ok) return { error: failureMessage(result.failure) };

  session.destroy();
  redirect("/sign-in?notice=signedOutEverywhere");
}

const deleteForm = z.object({ email: z.string(), password: z.string() });

/** Deletes the account and every saved server (US-WEB-21, AUD-48). */
export async function deleteAccountAction(
  _previous: AccountState,
  form: FormData,
): Promise<AccountState> {
  const session = await requireSession();
  const parsed = deleteForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: "Type your email and password to confirm." };
  if (parsed.data.email.trim().toLowerCase() !== session.email.toLowerCase()) {
    return { error: "Type your account's email exactly to confirm." };
  }
  if (!parsed.data.password) return { error: "Enter your password." };

  const result = await authed(session, (token) => deleteAccount(token, parsed.data.password));
  if (!result.ok) return { error: failureMessage(result.failure) };

  session.destroy();
  redirect("/sign-in?notice=accountDeleted");
}
