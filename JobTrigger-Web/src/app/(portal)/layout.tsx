import type { Metadata } from "next";

import { AuthShell, PortalUnavailable } from "@/features/auth/auth-shell";
import { PortalShell } from "@/features/portal/portal-shell";
import { isPortalConfigured } from "@/server/config";
import { requireSession } from "@/server/guard";

// US-WEB-07: never indexed (the proxy also sends X-Robots-Tag: noindex).
export const metadata: Metadata = { robots: { index: false, follow: false } };

/** Every signed-in page. The session check here is the access control. */
export default async function PortalLayout({ children }: LayoutProps<"/">) {
  if (!isPortalConfigured()) {
    return <AuthShell pitch={null} form={<PortalUnavailable title="Your servers" />} />;
  }
  const session = await requireSession();
  return <PortalShell email={session.email}>{children}</PortalShell>;
}
