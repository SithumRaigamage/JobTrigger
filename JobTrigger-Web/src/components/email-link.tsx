import { detail, siteDetails, type SiteDetail } from "@/content/site-details";

import { cn } from "./cn";

/** A mailto link for a site detail, or its placeholder as plain text while unset. */
export function EmailLink({
  field,
  className,
}: {
  field: Extract<SiteDetail, "securityEmail" | "privacyEmail">;
  className?: string;
}) {
  const address = siteDetails[field];
  if (address === null) {
    return <span className={cn("font-mono", className)}>{detail(field)}</span>;
  }
  return (
    <a href={`mailto:${address}`} className={cn("font-mono", className)}>
      {address}
    </a>
  );
}
