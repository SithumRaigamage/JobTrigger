import type { Metadata } from "next";

import { SecurityView } from "@/features/marketing/security/security-view";

export const metadata: Metadata = {
  title: "Security",
  description:
    "Where your CI tokens travel in JobTrigger: direct from your phone to your CI, encrypted at rest, and never shown in full on the web.",
};

export default function SecurityPage() {
  return <SecurityView />;
}
