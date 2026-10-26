import { SkipLink } from "@/components/skip-link";
import { SiteFooter } from "@/features/marketing/site-footer";
import { SiteHeader } from "@/features/marketing/site-header";

export default function MarketingLayout({ children }: LayoutProps<"/">) {
  return (
    <>
      <SkipLink />
      <SiteHeader />
      {children}
      <SiteFooter />
    </>
  );
}
