import type { Metadata } from "next";
import { connection } from "next/server";

import { inter, jetbrainsMono } from "./fonts";
import "./globals.css";

// The shared header and footer arrive in P15-05.
export const metadata: Metadata = {
  title: "JobTrigger",
  description: "Trigger, watch and fix your CI/CD builds from your phone.",
};

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
