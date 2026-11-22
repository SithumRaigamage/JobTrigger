import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const redeemPromoCodeAction = vi.fn();
const refresh = vi.fn();

vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh }) }));
vi.mock("./actions", () => ({
  redeemPromoCodeAction: (...args: unknown[]) => redeemPromoCodeAction(...args),
}));

import { PromoCodeForm } from "./promo-code-form";

beforeEach(() => {
  redeemPromoCodeAction.mockReset();
  refresh.mockReset();
});

function submit(code: string) {
  render(<PromoCodeForm />);
  fireEvent.change(screen.getByLabelText("Code"), { target: { value: code } });
  const form = screen.getByRole("button", { name: "Redeem" }).closest("form");
  fireEvent.submit(form!);
}

describe("PromoCodeForm (US-PROMO-01)", () => {
  it("says it gives Pro days, not money off (US-PROMO-04)", () => {
    render(<PromoCodeForm />);

    expect(screen.getByRole("heading", { name: "Redeem a code for free Pro time" })).toBeVisible();
    expect(
      screen.getByText(/A code that takes money off a purchase is not redeemed here/),
    ).toBeVisible();
  });

  it("sends the code and re-reads the plan when it is accepted", async () => {
    redeemPromoCodeAction.mockResolvedValue({ ok: true });
    submit("LAUNCH30");

    await waitFor(() => expect(redeemPromoCodeAction).toHaveBeenCalled());
    expect(await screen.findByRole("status")).toBeVisible();
    await waitFor(() => expect(refresh).toHaveBeenCalled());
  });

  it("shows the backend's sentence when the code is refused", async () => {
    redeemPromoCodeAction.mockResolvedValue({
      error: "You've already used that code.",
    });
    submit("LAUNCH30");

    expect(await screen.findByRole("alert")).toHaveTextContent("You've already used that code.");
    expect(refresh).not.toHaveBeenCalled();
  });

  it("shows a not-valid sentence and keeps the form usable", async () => {
    redeemPromoCodeAction.mockResolvedValue({
      error: "That code isn't valid, or it has expired.",
    });
    submit("NOPE");

    expect(await screen.findByRole("alert")).toHaveTextContent("isn't valid");
    expect(screen.getByLabelText("Code")).toBeVisible();
    expect(screen.getByRole("button", { name: "Redeem" })).toBeEnabled();
  });
});
