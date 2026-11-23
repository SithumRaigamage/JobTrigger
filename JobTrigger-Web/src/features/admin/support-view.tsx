import Link from "next/link";

import { Card } from "@/components/layout";
import { failureMessage } from "@/domain/app-failure";
import type { AppFailure } from "@/domain/app-failure";
import {
  AREA_LABELS,
  CATEGORY_LABELS,
  IMPACT_LABELS,
  STATUS_LABELS,
  labelFor,
  type AdminSupportTicket,
} from "@/domain/support";
import type { SupportStatusFilter } from "@/server/support-api";

import { SupportStatusForm } from "./support-status-form";

export const STATUS_FILTERS: readonly { id: SupportStatusFilter; label: string }[] = [
  { id: "open", label: "Open" },
  { id: "triaged", label: "Triaged" },
  { id: "closed", label: "Closed" },
  { id: "all", label: "All" },
];

const dateFormat = new Intl.DateTimeFormat("en", { dateStyle: "long", timeZone: "UTC" });

function supportDate(iso: string | null): string | null {
  if (!iso) return null;
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? null : dateFormat.format(date);
}

const areaList = (areas: string[]): string =>
  areas.length ? areas.map((area) => labelFor(AREA_LABELS, area)).join(", ") : "None selected";

/** /admin/support: newest reports first, with the triage signals at a glance. */
export function SupportQueueView({
  items,
  failure,
  status,
}: {
  items: AdminSupportTicket[];
  failure: AppFailure | null;
  status: SupportStatusFilter;
}) {
  return (
    <>
      <header className="flex flex-col gap-2">
        <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Support reports</h1>
        <p className="text-sm text-muted">
          Every report from the app and this site, newest first. Screenshots are shown only here and
          are deleted 30 days after the report; the owner email never carries the images.
        </p>
      </header>
      <nav aria-label="Status" className="flex flex-wrap gap-2">
        {STATUS_FILTERS.map((filter) => (
          <Link
            key={filter.id}
            href={`/admin/support?status=${filter.id}`}
            aria-current={filter.id === status ? "page" : undefined}
            className={`rounded-full border px-3.5 py-1.5 text-sm font-semibold no-underline ${
              filter.id === status ? "border-accent bg-accent text-on-accent" : "border-line-strong"
            }`}
          >
            {filter.label}
          </Link>
        ))}
      </nav>
      {failure ? (
        <p role="alert" className="text-failed-fg">
          {failureMessage(failure)}
        </p>
      ) : items.length === 0 ? (
        <p>No reports here.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {items.map((item) => (
            <li key={item.id}>
              <Card className="flex flex-wrap items-center justify-between gap-3 p-5">
                <div className="flex min-w-0 flex-col gap-1">
                  <span className="truncate font-semibold">{item.subject}</span>
                  <span className="truncate text-sm text-fg-secondary">
                    {item.userEmail ?? "(account deleted)"}
                  </span>
                  <span className="text-sm text-muted">
                    {labelFor(CATEGORY_LABELS, item.category)} · {areaList(item.areas)} ·{" "}
                    {labelFor(IMPACT_LABELS, item.impact)} · {item.screenshotCount} screenshot
                    {item.screenshotCount === 1 ? "" : "s"} · {labelFor(STATUS_LABELS, item.status)}{" "}
                    · {supportDate(item.createdAt) ?? "?"}
                  </span>
                </div>
                <Link href={`/admin/support/${item.id}`}>Open</Link>
              </Card>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

/** /admin/support/:id: the full report, its options, thumbnails and status. */
export function SupportDetailView({ item }: { item: AdminSupportTicket }) {
  const rows: [string, string][] = [
    ["Status", labelFor(STATUS_LABELS, item.status)],
    ["Category", labelFor(CATEGORY_LABELS, item.category)],
    ["Affected areas", areaList(item.areas)],
    ["Impact", labelFor(IMPACT_LABELS, item.impact)],
    ["Reporter", item.userEmail ?? "(account deleted)"],
    ["Reply to", item.replyEmail ?? "(none)"],
    ["Screenshots", String(item.screenshotCount)],
    ["Submitted", supportDate(item.createdAt) ?? "?"],
    ["App version", item.appVersion ?? "?"],
    ["Tool", item.tool ?? "?"],
    ["Platform", item.platform ?? "?"],
    ["Server", item.serverHost ?? "?"],
  ];

  return (
    <>
      <Link href="/admin/support" className="text-sm">
        ← All reports
      </Link>
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">{item.subject}</h1>
      <Card className="p-6">
        <dl className="grid grid-cols-[max-content_1fr] gap-x-6 gap-y-2">
          {rows.map(([label, value]) => (
            <div key={label} className="contents">
              <dt className="text-sm font-semibold text-fg-secondary">{label}</dt>
              <dd className="min-w-0 break-words">{value}</dd>
            </div>
          ))}
        </dl>
      </Card>
      <Card className="flex flex-col gap-3 p-6">
        <h2 className="text-lg font-extrabold">Message</h2>
        <p className="text-[0.9375rem] leading-relaxed break-words whitespace-pre-wrap">
          {item.message}
        </p>
      </Card>
      <Card className="flex flex-col gap-3 p-6">
        <h2 className="text-lg font-extrabold">Screenshots</h2>
        {!item.screenshots?.length ? (
          <p>No screenshots.</p>
        ) : (
          <ul className="flex flex-wrap gap-3">
            {item.screenshots.map((shot) => {
              const href = `/admin/support/${item.id}/screenshots/${shot.index}`;
              return (
                <li key={shot.index}>
                  <a href={href} target="_blank" rel="noopener noreferrer">
                    {/* Served from our own origin with no-store; CSP img-src 'self'. */}
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={href}
                      alt={`Screenshot ${shot.index + 1}`}
                      className="size-28 rounded-control border border-line object-cover"
                    />
                    <span className="sr-only">Open screenshot {shot.index + 1} full size</span>
                  </a>
                </li>
              );
            })}
          </ul>
        )}
      </Card>
      <SupportStatusForm id={item.id} status={item.status} />
    </>
  );
}
