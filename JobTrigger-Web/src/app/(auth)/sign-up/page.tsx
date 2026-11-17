import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { statusOf } from "@/content/feature-status";
import { AuthShell, PortalUnavailable } from "@/features/auth/auth-shell";
import { SignUpForm } from "@/features/auth/sign-up-form";
import { isPortalConfigured } from "@/server/config";
import { getSession, isSignedIn } from "@/server/session";

export const metadata: Metadata = {
  title: "Create your account",
  description: "One JobTrigger account for the app and the web.",
  robots: { index: false, follow: false },
};

export default async function SignUpPage() {
  const configured = isPortalConfigured();
  if (configured && isSignedIn(await getSession())) redirect("/servers");

  // WEB-B7: the design's "Free on iOS and Android" only once the app is out.
  const points = [
    "Servers follow you to every phone",
    "Tokens encrypted at rest",
    statusOf("app-stores") === "live"
      ? "Free on iOS and Android"
      : "The app is coming soon to iPhone and Android",
  ];

  return (
    <AuthShell
      pitch={
        <>
          <h2 className="text-h2 leading-[1.04] tracking-[-0.04em] md:text-5xl">
            One account.
            <br />
            <span className="text-running-fg">App and web.</span>
          </h2>
          <ul className="flex flex-col gap-3 text-fg-secondary">
            {points.map((point) => (
              <li key={point} className="flex items-center gap-3">
                <span
                  aria-hidden="true"
                  className="flex size-6.5 flex-none items-center justify-center rounded-full bg-success-bg text-[0.8125rem] text-success-fg"
                >
                  ✓
                </span>
                {point}
              </li>
            ))}
          </ul>
        </>
      }
      form={configured ? <SignUpForm /> : <PortalUnavailable title="Create your account" />}
      switcher={
        configured && (
          <>
            <span>Already have an account?</span>
            <a href="/sign-in" className="font-bold">
              Sign in →
            </a>
          </>
        )
      }
    />
  );
}
