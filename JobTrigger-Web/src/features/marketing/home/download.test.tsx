import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { FeatureStatus } from "@/content/feature-status";

import { Download } from "./download";

let appStores: FeatureStatus = "soon";
const links = vi.hoisted(() => ({
  appStore: null as string | null,
  googlePlay: null as string | null,
}));

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  return {
    ...actual,
    statusOf: (id: Parameters<typeof actual.statusOf>[0]) =>
      id === "app-stores" ? appStores : actual.statusOf(id),
  };
});

vi.mock("../site-links", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../site-links")>();
  return { ...actual, storeLinks: links };
});

afterEach(() => {
  appStores = "soon";
  links.appStore = null;
  links.googlePlay = null;
});

describe("Download", () => {
  it("before launch: coming soon, inert store buttons, web setup and launch updates", () => {
    render(<Download />);

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      /Coming soon to\s*iPhone and Android\./,
    );
    for (const name of ["Coming soon to the App Store", "Coming soon to Google Play"]) {
      const button = screen.getByRole("button", { name });
      expect(button).toHaveAttribute("aria-disabled", "true");
      expect(button).toHaveAttribute("type", "button");
    }
    expect(screen.queryByRole("link", { name: /App Store|Google Play/ })).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Set up your servers now" })).toHaveAttribute(
      "href",
      "/sign-in",
    );
    expect(screen.getByRole("link", { name: "Follow launch updates →" })).toHaveAttribute(
      "href",
      "/changelog",
    );
  });

  it("at launch: real store links", () => {
    appStores = "live";
    links.appStore = "https://apps.apple.com/app/jobtrigger/id1";
    links.googlePlay = "https://play.google.com/store/apps/details?id=jobtrigger";
    render(<Download />);

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      /Your next build\s*is one tap away\./,
    );
    expect(screen.getByRole("link", { name: "Download on the App Store" })).toHaveAttribute(
      "href",
      links.appStore,
    );
    expect(screen.getByRole("link", { name: "Get it on Google Play" })).toHaveAttribute(
      "href",
      links.googlePlay,
    );
    expect(screen.queryByText("Follow launch updates →")).not.toBeInTheDocument();
  });

  it("never links a store button that has no URL, even when live", () => {
    appStores = "live";
    render(<Download />);

    expect(screen.queryByRole("link", { name: /App Store|Google Play/ })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: /App Store/ })).toHaveAttribute(
      "aria-disabled",
      "true",
    );
  });
});
