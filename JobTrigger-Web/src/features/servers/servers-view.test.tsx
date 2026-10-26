import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { Credential } from "@/domain/credentials";

import { ServersView } from "./servers-view";

const jenkins: Credential = {
  tool: "jenkins",
  id: "j1",
  name: "Acme production",
  url: "https://ci.acme.dev",
  username: "sam",
  isDefault: true,
  needsReentry: false,
  secretMask: "••••a91f",
  hasParamToken: false,
};

describe("ServersView", () => {
  it("shows the failure with a way to retry instead of the list", () => {
    render(<ServersView servers={[]} failure={{ kind: "network" }} />);

    expect(screen.getByRole("alert")).toHaveTextContent(
      "Can't reach the server. Check your connection and try again.",
    );
    expect(screen.getByRole("link", { name: "Try again" })).toHaveAttribute("href", "/servers");
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("asks for an unreadable token to be pasted again (AUD-63)", () => {
    render(
      <ServersView
        servers={[{ ...jenkins, needsReentry: true, secretMask: null }]}
        failure={null}
      />,
    );

    expect(screen.getByText("Paste again")).toBeVisible();
  });

  it("links each row to its edit page with an accessible name", () => {
    render(<ServersView servers={[jenkins]} failure={null} />);

    expect(screen.getByRole("link", { name: "Edit Acme production" })).toHaveAttribute(
      "href",
      "/servers/jenkins/j1",
    );
  });
});
