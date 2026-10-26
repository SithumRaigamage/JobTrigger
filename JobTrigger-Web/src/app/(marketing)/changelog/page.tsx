import type { Metadata } from "next";

import { ChangelogView } from "@/features/marketing/changelog/changelog-view";

export const metadata: Metadata = {
  title: "Changelog",
  description: "What's new in JobTrigger, and what the first public release brings.",
};

export default function ChangelogPage() {
  return <ChangelogView />;
}
