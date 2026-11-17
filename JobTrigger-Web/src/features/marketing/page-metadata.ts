import type { Metadata } from "next";

/**
 * The shared app/opengraph-image.tsx, referenced explicitly: a page's own
 * `openGraph` object replaces the inherited one, so the file-based image
 * would otherwise be dropped (found in P15-12).
 */
const previewImage = {
  url: "/opengraph-image",
  width: 1200,
  height: 630,
  alt: "JobTrigger — trigger, watch and fix your CI builds from your phone",
};

/**
 * Metadata for one public page (US-WEB-07): a unique title and
 * description, its canonical URL, and matching Open Graph / Twitter tags.
 * URLs are relative; the root layout's metadataBase makes them absolute.
 */
export function pageMetadata({
  title,
  description,
  path,
}: {
  /** Short title; the root template adds " · JobTrigger". Null for home. */
  title: string | null;
  description: string;
  path: string;
}): Metadata {
  const fullTitle = title ? `${title} · JobTrigger` : "JobTrigger";
  return {
    ...(title ? { title } : {}),
    description,
    alternates: { canonical: path },
    openGraph: {
      type: "website",
      siteName: "JobTrigger",
      locale: "en_GB",
      url: path,
      title: fullTitle,
      description,
      images: [previewImage],
    },
    twitter: { card: "summary_large_image", title: fullTitle, description, images: [previewImage] },
  };
}
