import type { Metadata } from "next";

import { PrivacyView } from "@/features/marketing/legal/privacy-view";

export const metadata: Metadata = {
  title: "Privacy policy",
  description:
    "What JobTrigger stores: your email, a hashed password and encrypted server details. No analytics or tracking.",
};

export default function PrivacyPage() {
  return <PrivacyView />;
}
