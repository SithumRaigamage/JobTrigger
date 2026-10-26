import { Inter, JetBrains_Mono } from "next/font/google";

// Downloaded at build time and served from this site: browsers never
// contact Google, so the CSP stays 'self'-only (WEB-B2). Variable fonts,
// so every weight the designs use (400–800) is available.
export const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-inter",
});

// For anything a CI tool printed or counts: build numbers, URLs, branches.
export const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-jetbrains-mono",
});
