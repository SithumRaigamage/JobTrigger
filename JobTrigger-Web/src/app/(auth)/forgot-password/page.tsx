import type { Metadata } from "next";

import { AuthShell, PortalUnavailable } from "@/features/auth/auth-shell";
import { ForgotPasswordForm } from "@/features/auth/password-reset-forms";
import { isPortalConfigured } from "@/server/config";

export const metadata: Metadata = {
  title: "Reset your password",
  description: "Get a link to choose a new JobTrigger password.",
  robots: { index: false, follow: false },
};

const pitch = (
  <>
    <h2 className="text-h2 leading-[1.04] tracking-[-0.04em] md:text-5xl">
      Locked out?
      <br />
      <span className="text-running-fg">We&apos;ll email you a link.</span>
    </h2>
    <p className="text-[1.0625rem] leading-relaxed text-fg-secondary">
      Your saved servers stay exactly as they are. Only the password changes.
    </p>
  </>
);

/** US-AUTH-08 on the web (P20-74). Works signed in or out. */
export default function ForgotPasswordPage() {
  return (
    <AuthShell
      pitch={pitch}
      form={
        isPortalConfigured() ? (
          <ForgotPasswordForm />
        ) : (
          <PortalUnavailable title="Reset your password" />
        )
      }
      switcher={
        <>
          <span>Remembered it?</span>
          <a href="/sign-in" className="font-bold">
            Sign in →
          </a>
        </>
      }
    />
  );
}
