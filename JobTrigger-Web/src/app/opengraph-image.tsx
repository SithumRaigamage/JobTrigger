import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { ImageResponse } from "next/og";

// The shared link-preview image (US-WEB-07: "a shared default"), 1200×630,
// generated once at build time. ImageResponse renders its own JSX to PNG,
// so these inline styles never reach a page or the CSP. Inter Bold is the
// app's bundled copy (SIL OFL, src/assets/fonts/Inter-OFL.txt): the
// renderer's default font has no bold weight, and a local file keeps the
// build offline.
// Keep `alt` in step with previewImage in features/marketing/page-metadata.ts.
export const alt = "JobTrigger — trigger, watch and fix your CI builds from your phone";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const interBold = await readFile(join(process.cwd(), "src/assets/fonts/Inter-Bold.ttf"));

export default function OpengraphImage() {
  return new ImageResponse(
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
        padding: 80,
        background: "#0B1120",
        color: "#F1F5F9",
        fontFamily: "Inter",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: 20,
            background: "#2563EB",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <svg width="34" height="34" viewBox="0 0 24 24" fill="#FFFFFF">
            <path d="M8 5v14l11-7z" />
          </svg>
        </div>
        <span style={{ fontSize: 40, letterSpacing: -1 }}>JobTrigger</span>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
        <div style={{ display: "flex", flexDirection: "column", fontSize: 100, lineHeight: 1 }}>
          <span style={{ letterSpacing: -4 }}>Ship builds</span>
          <span style={{ letterSpacing: -4 }}>
            from&nbsp;<span style={{ color: "#93C5FD" }}>anywhere.</span>
          </span>
        </div>
        <span style={{ fontSize: 32, color: "#CBD5E1" }}>
          Jenkins, GitHub Actions and SonarQube in your pocket.
        </span>
      </div>
    </div>,
    { ...size, fonts: [{ name: "Inter", data: interBold, style: "normal", weight: 700 }] },
  );
}
