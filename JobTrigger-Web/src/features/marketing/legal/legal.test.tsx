import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SupportView } from "../support/support-view";

import { PrivacyView } from "./privacy-view";
import { TermsView } from "./terms-view";

describe("PrivacyView", () => {
  it("states what is stored and that nothing is tracked", () => {
    render(<PrivacyView />);

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Privacy policy");
    expect(screen.getByText(/hashed password and your encrypted server details/)).toBeVisible();
    expect(screen.getByText("No analytics, crash reports or ad identifiers today.")).toBeVisible();
  });

  it("marks itself as the current legal page and keeps placeholders as text", () => {
    render(<PrivacyView />);

    const nav = screen.getByRole("navigation", { name: "Legal pages" });
    expect(within(nav).getByRole("link", { name: "Privacy policy" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(screen.getByText(/Last updated \[DATE\]/)).toBeVisible();
    expect(screen.queryByRole("link", { name: /PRIVACY EMAIL/ })).not.toBeInTheDocument();
  });
});

describe("TermsView", () => {
  it("is its own page in the legal nav", () => {
    render(<TermsView />);

    const nav = screen.getByRole("navigation", { name: "Legal pages" });
    expect(within(nav).getByRole("link", { name: "Terms of use" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(within(nav).getByRole("link", { name: "Terms of use" })).toHaveAttribute(
      "href",
      "/terms",
    );
  });
});

describe("SupportView", () => {
  it("lists four topics that jump to their answer, the first open", () => {
    const { container } = render(<SupportView supportEmail="help@jobtrigger.app" />);

    expect(screen.getByRole("link", { name: /Jenkins tokens/ })).toHaveAttribute(
      "href",
      "#faq-jenkins-tokens",
    );
    const details = container.querySelectorAll("details");
    expect(details).toHaveLength(4);
    expect(details[0]).toHaveAttribute("open");
    expect(details[1]).not.toHaveAttribute("open");
  });

  it("emails the backend's support address, as the app does", () => {
    render(<SupportView supportEmail="help@jobtrigger.app" />);

    expect(screen.getByRole("link", { name: "Email support" })).toHaveAttribute(
      "href",
      "mailto:help@jobtrigger.app",
    );
  });

  it("says when the support address can't be loaded instead of linking nowhere", () => {
    render(<SupportView supportEmail={null} />);

    expect(screen.queryByRole("link", { name: "Email support" })).not.toBeInTheDocument();
    expect(screen.getByText(/Support email is unavailable right now/)).toBeVisible();
  });

  it("answers the password question from the password-reset status", () => {
    render(<SupportView supportEmail={null} />);

    expect(screen.getByText(/Password reset isn’t available yet/)).toBeInTheDocument();
  });
});
