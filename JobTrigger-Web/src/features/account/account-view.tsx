import { ChangePassword, DeleteAccount, SignOutEverywhere } from "./account-forms";

/** Account (design 14; US-WEB-20, 21). */
export function AccountView({ email }: { email: string }) {
  return (
    <>
      <section
        data-surface="dark"
        className="relative flex flex-wrap items-center gap-4.5 overflow-hidden rounded-3xl p-7"
      >
        <div
          aria-hidden="true"
          className="absolute -top-15 -right-10 size-55 rounded-full border-32 border-accent/35"
        />
        <span
          aria-hidden="true"
          className="relative flex size-16 items-center justify-center rounded-full bg-accent text-[1.625rem] font-extrabold text-on-accent"
        >
          {email.charAt(0).toUpperCase()}
        </span>
        <div className="relative flex min-w-0 flex-col gap-1">
          <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Account</h1>
          <span className="truncate font-mono text-sm text-fg-secondary">{email}</span>
        </div>
      </section>
      <div className="flex flex-wrap items-start gap-5">
        <ChangePassword />
        <div className="flex min-w-0 flex-[1_1_320px] flex-col gap-5">
          <SignOutEverywhere />
          <DeleteAccount email={email} />
        </div>
      </div>
    </>
  );
}
