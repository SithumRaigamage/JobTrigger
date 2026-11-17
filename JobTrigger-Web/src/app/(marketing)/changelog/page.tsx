import { pageMetadata } from "@/features/marketing/page-metadata";
import { ChangelogView } from "@/features/marketing/changelog/changelog-view";

export const metadata = pageMetadata({
  title: "Changelog",
  description: "What's new in JobTrigger, and what the first public release brings.",
  path: "/changelog",
});

export default function ChangelogPage() {
  return <ChangelogView />;
}
