import type { Metadata } from "next";

import "./globals.css";

// Fonts, tokens and the shared header/footer arrive in P15-02 and P15-05.
export const metadata: Metadata = {
  title: "JobTrigger",
  description: "Trigger, watch and fix your CI/CD builds from your phone.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
