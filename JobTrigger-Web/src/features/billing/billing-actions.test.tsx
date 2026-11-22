import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Paddle.js isn't loaded in tests. The Script stub calls onReady, which is
// what enables the buttons (and what the real page needs before a checkout).
vi.mock("next/script", async () => {
  const { useEffect } = await import("react");
  const Script = ({ onReady }: { onReady?: () => void }) => {
    useEffect(() => onReady?.(), [onReady]);
    return null;
  };
  return { default: Script };
});

const startCheckoutAction = vi.hoisted(() => vi.fn());
vi.mock("./actions", () => ({ startCheckoutAction, openPortalAction: vi.fn() }));

import { UpgradeButtons } from "./billing-actions";

const open = vi.fn();

beforeEach(() => {
  startCheckoutAction.mockReset();
  open.mockReset();
  Object.defineProperty(window, "Paddle", {
    configurable: true,
    value: {
      Environment: { set: vi.fn() },
      Initialize: vi.fn(),
      Checkout: { open },
    },
  });
});

// US-PROMO-04: a percentage-off code is taken off by Paddle, so the field is
// part of the checkout rather than the "Redeem a code for free Pro time" form.
describe("UpgradeButtons", () => {
  it("names the field for money off, so it is not mistaken for a Pro code", () => {
    render(<UpgradeButtons clientToken="test_0123456789abcdefghij" environment="sandbox" />);

    expect(screen.getByLabelText("Discount code (money off this purchase)")).toBeVisible();
    expect(screen.getByText(/Takes a percentage off this checkout only/)).toBeVisible();
    expect(screen.getByText(/does not add Pro time/)).toBeVisible();
  });

  it("sends the trimmed discount code with the chosen interval, then opens the checkout", async () => {
    startCheckoutAction.mockResolvedValue({ transactionId: "txn_1", environment: "sandbox" });
    render(<UpgradeButtons clientToken="test_0123456789abcdefghij" environment="sandbox" />);

    fireEvent.change(screen.getByLabelText("Discount code (money off this purchase)"), {
      target: { value: "  save20 " },
    });
    const yearly = screen.getByRole("button", { name: "Upgrade, yearly" });
    await waitFor(() => expect(yearly).toBeEnabled());
    fireEvent.click(yearly);

    await waitFor(() => expect(startCheckoutAction).toHaveBeenCalledWith("yearly", "save20"));
    await waitFor(() => expect(open).toHaveBeenCalledWith({ transactionId: "txn_1" }));
  });

  it("shows a refused code's sentence and opens nothing", async () => {
    startCheckoutAction.mockResolvedValue({
      error: "That code isn't valid, or it has expired.",
    });
    render(<UpgradeButtons clientToken="test_0123456789abcdefghij" environment="sandbox" />);

    const monthly = screen.getByRole("button", { name: "Upgrade, monthly" });
    await waitFor(() => expect(monthly).toBeEnabled());
    fireEvent.click(monthly);

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "That code isn't valid, or it has expired.",
    );
    expect(open).not.toHaveBeenCalled();
  });
});
