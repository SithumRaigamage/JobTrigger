import type { Metadata } from "next";
import { connection } from "next/server";

import { getSiteUrl } from "@/server/config";

import { inter, jetbrainsMono } from "./fonts";
import "./globals.css";

export function generateMetadata(): Metadata {
  return {
    // Absolute URLs for canonical links, Open Graph and the preview image,
    // from SITE_URL at request time (docs/web-architecture.md §8).
    metadataBase: new URL(getSiteUrl()),
    // Pages set a short title; the template adds the product name.
    title: { default: "JobTrigger", template: "%s · JobTrigger" },
    description: "Trigger, watch and fix your CI/CD builds from your phone.",
  };
}

export default async function RootLayout({ children }: LayoutProps<"/">) {
  // Render every page per request so it carries this request's CSP nonce
  // (src/proxy.ts). A prerendered page would ship scripts without one.
  await connection();

  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col font-sans">{children}</body>
    </html>
  );
}
