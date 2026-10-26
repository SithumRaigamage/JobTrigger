import { pageMetadata } from "@/features/marketing/page-metadata";
import { PrivacyView } from "@/features/marketing/legal/privacy-view";

export const metadata = pageMetadata({
  title: "Privacy policy",
  description:
    "What JobTrigger stores: your email, a hashed password and encrypted server details. No analytics or tracking.",
  path: "/privacy",
});

export default function PrivacyPage() {
  return <PrivacyView />;
}
