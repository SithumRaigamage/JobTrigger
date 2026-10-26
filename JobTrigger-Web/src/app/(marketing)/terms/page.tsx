import type { Metadata } from "next";

import { TermsView } from "@/features/marketing/legal/terms-view";

export const metadata: Metadata = {
  title: "Terms of use",
  description: "The terms for using the JobTrigger app and website.",
};

export default function TermsPage() {
  return <TermsView />;
}
