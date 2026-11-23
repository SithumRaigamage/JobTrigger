import { connection } from "next/server";

import { pageMetadata } from "@/features/marketing/page-metadata";
import { SupportView } from "@/features/marketing/support/support-view";
import { getAppInfo } from "@/server/app-info";
import { getSession, isSignedIn } from "@/server/session";

export const metadata = pageMetadata({
  title: "Support",
  description: "Answers to common JobTrigger setup problems, and how to reach support.",
  path: "/support",
});

export default async function SupportPage() {
  // Calls the backend: wait for a request (docs/web-architecture.md §5).
  await connection();
  const [appInfo, session] = await Promise.all([getAppInfo(), getSession()]);
  // US-SUP-05/06: the form is for signed-in users only (P25-05). Signed-out
  // visitors keep the FAQ and email fallback exactly as before.
  const signedIn = isSignedIn(session);
  return (
    <SupportView
      supportEmail={appInfo?.supportEmail ?? null}
      signedIn={signedIn}
      replyEmail={signedIn ? session.email : null}
    />
  );
}
