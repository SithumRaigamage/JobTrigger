import { pageMetadata } from "@/features/marketing/page-metadata";
import { FeaturesView } from "@/features/marketing/features/features-view";

export const metadata = pageMetadata({
  title: "Features",
  description:
    "Trigger Jenkins jobs with any parameter, dispatch GitHub Actions workflows, check SonarQube quality gates, follow live logs, and get notified when they finish.",
  path: "/features",
});

export default function FeaturesPage() {
  return <FeaturesView />;
}
