// @vitest-environment node
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

/*
 * WCAG 2.1 AA check of the colour tokens in globals.css, for both surfaces
 * (WEB-B5) — the web counterpart of the app's app_colors_test.dart. It
 * reads the real stylesheet, so changing a token re-runs the check.
 */

const css = readFileSync(fileURLToPath(new URL("./globals.css", import.meta.url)), "utf8");

function block(selector: string): Record<string, string> {
  const start = css.indexOf(`${selector} {`);
  if (start === -1) throw new Error(`No ${selector} block in globals.css`);
  const body = css.slice(start, css.indexOf("}", start));
  return Object.fromEntries(
    [...body.matchAll(/--([\w-]+):\s*(#[0-9a-f]{6})\s*;/gi)].map(([, name, hex]) => [name, hex]),
  );
}

function luminance(hex: string): number {
  const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const [r, g, b] = channels.map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

const surfaces = {
  light: block('[data-surface="light"]'),
  dark: block('[data-surface="dark"]'),
};

const textPairs: Array<[fg: string, bg: string]> = [
  ["fg", "page"],
  ["fg", "card"],
  ["fg-secondary", "card"],
  ["muted", "page"],
  ["muted", "card"],
  ["link", "page"],
  ["link", "card"],
  ["link-hover", "card"],
  ["success-fg", "success-bg"],
  ["failed-fg", "failed-bg"],
  ["unstable-fg", "unstable-bg"],
  ["running-fg", "running-bg"],
  ["neutral-fg", "neutral-bg"],
  // StatusBadge `inset` (a "Coming soon" pill inside a disabled control).
  ["neutral-fg", "line"],
];

describe.each(Object.entries(surfaces))("%s surface", (_name, tokens) => {
  it.each(textPairs)("%s on %s is at least 4.5:1", (fg, bg) => {
    expect(tokens[fg], `--${fg}`).toBeDefined();
    expect(tokens[bg], `--${bg}`).toBeDefined();
    expect(contrast(tokens[fg], tokens[bg])).toBeGreaterThanOrEqual(4.5);
  });
});

it("white on the accent is at least 4.5:1", () => {
  expect(contrast("#ffffff", "#2563eb")).toBeGreaterThanOrEqual(4.5);
  expect(contrast("#ffffff", "#1d4ed8")).toBeGreaterThanOrEqual(4.5);
});

it("on-accent-muted on the accent is at least 4.5:1", () => {
  expect(contrast("#eff6ff", "#2563eb")).toBeGreaterThanOrEqual(4.5);
});
