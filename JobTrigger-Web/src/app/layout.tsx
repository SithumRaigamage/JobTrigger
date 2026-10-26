import type { Metadata } from "next";

import { inter, jetbrainsMono } from "./fonts";
import "./globals.css";

// The shared header and footer arrive in P15-05.
export const metadata: Metadata = {
  title: "JobTrigger",
  description: "Trigger, watch and fix your CI/CD builds from your phone.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col font-sans">{children}</body>
    </html>
  );
}
