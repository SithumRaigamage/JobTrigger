import Link from "next/link";

/** The owner console's pages. Reachable only once the backend lets an admin in. */
export function AdminTabs({ current }: { current: "students" | "subscriptions" | "support" }) {
  const tabs = [
    { id: "students", href: "/admin/students", label: "Student applications" },
    { id: "subscriptions", href: "/admin/subscriptions", label: "Subscriptions" },
    { id: "support", href: "/admin/support", label: "Support reports" },
  ] as const;

  return (
    <nav aria-label="Admin" className="flex flex-wrap gap-2 text-sm">
      {tabs.map((tab) => (
        <Link
          key={tab.id}
          href={tab.href}
          aria-current={tab.id === current ? "page" : undefined}
          className={`rounded-full border px-3.5 py-1.5 font-semibold no-underline ${
            tab.id === current ? "border-accent bg-accent text-on-accent" : "border-line-strong"
          }`}
        >
          {tab.label}
        </Link>
      ))}
    </nav>
  );
}
