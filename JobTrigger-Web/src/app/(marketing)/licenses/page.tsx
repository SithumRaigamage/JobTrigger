import { pageMetadata } from "@/features/marketing/page-metadata";
import { LicensesView } from "@/features/marketing/legal/licenses-view";

export const metadata = pageMetadata({
  title: "Open-source licenses",
  description: "The open-source packages the JobTrigger app, website and backend are built with.",
  path: "/licenses",
});

export default function LicensesPage() {
  return <LicensesView />;
}
