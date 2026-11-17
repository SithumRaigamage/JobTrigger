import { pageMetadata } from "@/features/marketing/page-metadata";
import { SecurityView } from "@/features/marketing/security/security-view";

export const metadata = pageMetadata({
  title: "Security",
  description:
    "Where your CI tokens travel in JobTrigger: direct from your phone to your CI, encrypted at rest, and never shown in full on the web.",
  path: "/security",
});

export default function SecurityPage() {
  return <SecurityView />;
}
