import { pageMetadata } from "@/features/marketing/page-metadata";
import { TermsView } from "@/features/marketing/legal/terms-view";

export const metadata = pageMetadata({
  title: "Terms of use",
  description: "The terms for using the JobTrigger app and website.",
  path: "/terms",
});

export default function TermsPage() {
  return <TermsView />;
}
