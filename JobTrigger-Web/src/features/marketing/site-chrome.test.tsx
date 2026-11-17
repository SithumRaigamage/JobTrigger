import { render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { FeatureId, FeatureStatus } from "@/content/feature-status";

import { SiteFooter } from "./site-footer";
import { SiteHeader } from "./site-header";

let appStores: FeatureStatus = "soon";

vi.mock("next/navigation", () => ({ usePathname: () => "/features" }));

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  return {
    ...actual,
    statusOf: (id: FeatureId) => (id === "app-stores" ? appStores : actual.statusOf(id)),
  };
});

afterEach(() => {
  appStores = "soon";
});

describe("SiteHeader", () => {
  it("marks the current page in the main nav", () => {
    render(<SiteHeader />);
    const nav = screen.getByRole("navigation", { name: "Main" });

    expect(within(nav).getByRole("link", { name: "Features" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(within(nav).getByRole("link", { name: "Security" })).not.toHaveAttribute("aria-current");
  });

  it("shows the pre-launch actions while the app isn't in the stores", () => {
    render(<SiteHeader />);

    expect(screen.getByText("App coming soon")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Set up servers" })).toHaveAttribute(
      "href",
      "/sign-in",
    );
    expect(screen.queryByRole("link", { name: /Get the app/ })).not.toBeInTheDocument();
  });

  it("switches to Sign in + Get the app when the app is live", () => {
    appStores = "live";
    render(<SiteHeader />);

    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute("href", "/sign-in");
    expect(screen.getByRole("link", { name: "Get the app" })).toHaveAttribute("href", "/#download");
    expect(screen.queryByText("App coming soon")).not.toBeInTheDocument();
  });
});

describe("SiteFooter", () => {
  it("invites setup and points to launch updates before launch", () => {
    render(<SiteFooter />);

    expect(screen.getByText("The app is coming soon.")).toBeInTheDocument();
    const product = screen.getByRole("navigation", { name: "Product" });
    expect(within(product).getByRole("link", { name: "Launch updates" })).toHaveAttribute(
      "href",
      "/changelog",
    );
    expect(within(product).queryByRole("link", { name: "Download" })).not.toBeInTheDocument();
  });

  it("offers the app once it's live", () => {
    appStores = "live";
    render(<SiteFooter />);

    expect(screen.getByText("Your CI, in your pocket.")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Get the app" })).toHaveAttribute("href", "/#download");
    const product = screen.getByRole("navigation", { name: "Product" });
    expect(within(product).getByRole("link", { name: "Download" })).toBeInTheDocument();
  });

  it("labels every link group", () => {
    render(<SiteFooter />);

    for (const name of ["Product", "Trust", "Help"]) {
      expect(screen.getByRole("navigation", { name })).toBeInTheDocument();
    }
  });
});
