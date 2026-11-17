import type { Metadata } from "next";

import { AuthShell, PortalUnavailable } from "@/features/auth/auth-shell";
import { InvalidResetLink, ResetPasswordForm } from "@/features/auth/password-reset-forms";
import { isPortalConfigured } from "@/server/config";

export const metadata: Metadata = {
  title: "Choose a new password",
  description: "Set a new JobTrigger password from your emailed link.",
  robots: { index: false, follow: false },
  // The URL carries the reset token: never send it on as a Referer.
  referrer: "no-referrer",
};

const pitch = (
  <>
    <h2 className="text-h2 leading-[1.04] tracking-[-0.04em] md:text-5xl">
      New password,
      <br />
      <span className="text-running-fg">same servers.</span>
    </h2>
    <p className="text-[1.0625rem] leading-relaxed text-fg-secondary">
      Every phone and browser signed in to your account is signed out, so only you get back in.
    </p>
  </>
);

const TOKEN = /^[a-f0-9]{64}$/;

/** Opened from the reset email (US-AUTH-08, P20-74). */
export default async function ResetPasswordPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = await searchParams;
  const token = typeof params.token === "string" && TOKEN.test(params.token) ? params.token : null;

  let form;
  if (!isPortalConfigured()) form = <PortalUnavailable title="Choose a new password" />;
  else if (!token) form = <InvalidResetLink />;
  else form = <ResetPasswordForm token={token} />;

  return <AuthShell pitch={pitch} form={form} />;
}
