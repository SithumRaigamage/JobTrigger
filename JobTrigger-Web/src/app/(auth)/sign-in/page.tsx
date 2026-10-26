import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { statusOf } from "@/content/feature-status";
import { AuthShell, PortalUnavailable } from "@/features/auth/auth-shell";
import { safeNext } from "@/features/auth/safe-next";
import { SignInForm } from "@/features/auth/sign-in-form";
import { routes } from "@/features/marketing/site-links";
import { isPortalConfigured } from "@/server/config";
import { getSession, isSignedIn } from "@/server/session";

export const metadata: Metadata = {
  title: "Sign in",
  description: "Sign in to add Jenkins, GitHub and SonarQube servers from your computer.",
  robots: { index: false, follow: false },
};

const notices: Record<string, string> = {
  idle: "You were signed out after 30 minutes without activity.",
  expired: "Your session has ended. Please sign in again.",
  signedOut: "You're signed out.",
  signedOutEverywhere: "You're signed out on every device.",
  accountDeleted: "Your account and every saved server were deleted.",
};

export default async function SignInPage({ searchParams }: PageProps<"/sign-in">) {
  const params = await searchParams;
  const next = typeof params.next === "string" ? params.next : null;
  const pitch = (
    <>
      <h2 className="text-h2 leading-[1.04] tracking-[-0.04em] md:text-5xl">
        Paste it once.
        <br />
        <span className="text-running-fg">Your phone has it.</span>
      </h2>
      <p className="text-[1.0625rem] leading-relaxed text-fg-secondary">
        Sign in with your JobTrigger account to add Jenkins, GitHub and SonarQube servers from this
        computer.
      </p>
    </>
  );
  if (!isPortalConfigured()) {
    return <AuthShell pitch={pitch} form={<PortalUnavailable title="Sign in" />} />;
  }

  const session = await getSession();
  if (isSignedIn(session)) redirect(safeNext(next));

  const notice = typeof params.notice === "string" ? (notices[params.notice] ?? null) : null;
  // No reset flow yet (US-AUTH-08): "Forgot?" leads to the support answer.
  const forgotHref =
    statusOf("password-reset") === "live" ? "/reset-password" : `${routes.support}#faq-account`;

  return (
    <AuthShell
      pitch={pitch}
      form={<SignInForm notice={notice} next={next} forgotHref={forgotHref} />}
      switcher={
        <>
          <span>New to JobTrigger?</span>
          <a href="/sign-up" className="font-bold">
            Create an account →
          </a>
        </>
      }
    />
  );
}
