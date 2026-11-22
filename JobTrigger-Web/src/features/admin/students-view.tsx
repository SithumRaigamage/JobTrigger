import Link from "next/link";

import { Card } from "@/components/layout";
import type { AppFailure } from "@/domain/app-failure";
import { failureMessage } from "@/domain/app-failure";
import type { AdminStudent } from "@/domain/student";
import type { AdminStatusFilter } from "@/server/admin-students-api";
import { studentDate } from "@/features/student/student-text";

import { ReviewForms } from "./review-forms";

export const STATUS_FILTERS: readonly { id: AdminStatusFilter; label: string }[] = [
  { id: "pending", label: "Pending" },
  { id: "approved", label: "Approved" },
  { id: "rejected", label: "Rejected" },
  { id: "expired", label: "Ended" },
  { id: "all", label: "All" },
];

const statusText: Record<AdminStudent["status"], string> = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
  expired: "Ended",
};

const methodText: Record<AdminStudent["method"], string> = {
  email: "University email",
  document: "Student ID / letter",
};

/** "decided <date> by <reviewer>", or null while undecided (US-STU-03). */
export function decisionText(item: AdminStudent): string | null {
  if (!item.reviewedAt) return null;
  const by = item.reviewedByEmail ?? "(account deleted)";
  return `decided ${studentDate(item.reviewedAt) ?? "?"} by ${by}`;
}

const NOTICES: Record<string, string> = {
  approved: "Approved. The student has Pro for 365 days.",
  rejected: "Rejected. The student can see the reason and apply again.",
};

/** /admin/students: the review queue and history, both methods, newest first (SP-51, US-STU-03). */
export function StudentsView({
  items,
  failure,
  status,
  q,
  notice,
}: {
  items: AdminStudent[];
  failure: AppFailure | null;
  status: AdminStatusFilter;
  q: string;
  notice?: string;
}) {
  return (
    <>
      <header className="flex flex-col gap-2">
        <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Student applications</h1>
        <p className="text-sm text-muted">
          Every application, by university email or document, needs your approval. Documents are
          shown only here, never in an email. Each is deleted 30 days after the decision.
        </p>
      </header>
      {notice && NOTICES[notice] && (
        <p
          role="status"
          className="rounded-control bg-success-bg px-3.5 py-3 text-sm font-semibold text-success-fg"
        >
          {NOTICES[notice]}
        </p>
      )}
      <nav aria-label="Status" className="flex flex-wrap gap-2">
        {STATUS_FILTERS.map((filter) => (
          <Link
            key={filter.id}
            href={`/admin/students?status=${filter.id}${q ? `&q=${encodeURIComponent(q)}` : ""}`}
            aria-current={filter.id === status ? "page" : undefined}
            className={`rounded-full border px-3.5 py-1.5 text-sm font-semibold no-underline ${
              filter.id === status ? "border-accent bg-accent text-on-accent" : "border-line-strong"
            }`}
          >
            {filter.label}
          </Link>
        ))}
      </nav>
      <form action="/admin/students" method="get" role="search" className="flex flex-wrap gap-2">
        <input type="hidden" name="status" value={status} />
        <label htmlFor="student-search" className="sr-only">
          Search by exact account email
        </label>
        <input
          id="student-search"
          type="search"
          name="q"
          defaultValue={q}
          placeholder="Exact account email"
          className="h-11 min-w-0 flex-[1_1_260px] rounded-control border border-line-strong bg-card px-3.5"
        />
        <button
          type="submit"
          className="h-11 rounded-control border border-line-strong bg-card px-4 text-sm font-semibold"
        >
          Search
        </button>
      </form>
      {failure ? (
        <p role="alert" className="text-failed-fg">
          {failureMessage(failure)}
        </p>
      ) : items.length === 0 ? (
        <p>No applications here.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {items.map((item) => {
            const decided = decisionText(item);
            return (
              <li key={item.id}>
                <Card className="flex flex-wrap items-center justify-between gap-3 p-5">
                  <div className="flex min-w-0 flex-col gap-1">
                    <span className="truncate font-semibold">
                      {item.method === "email"
                        ? (item.universityEmail ?? "(email deleted)")
                        : (item.fullName ?? "(name deleted)")}
                    </span>
                    <span className="truncate font-mono text-sm text-fg-secondary">
                      {item.accountEmail ?? "(account deleted)"}
                    </span>
                    <span className="text-sm text-muted">
                      {methodText[item.method]} · {statusText[item.status]} · submitted{" "}
                      {studentDate(item.submittedAt) ?? "?"}
                      {decided ? ` · ${decided}` : ""}
                    </span>
                  </div>
                  <Link href={`/admin/students/${item.id}`}>
                    {item.status === "pending" ? "Review" : "Open"}
                  </Link>
                </Card>
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}

/** One application: its details, the document and the decision (SP-51). */
export function StudentDetailView({ item }: { item: AdminStudent }) {
  const byEmail = item.method === "email";
  const rows: [string, string][] = [
    ["Status", statusText[item.status]],
    ["Method", methodText[item.method]],
    ...(byEmail ? [] : ([["Full name on ID", item.fullName ?? "(deleted)"]] as [string, string][])),
    ["Account email", item.accountEmail ?? "(account deleted)"],
    ...(item.universityEmail
      ? ([["University email", item.universityEmail]] as [string, string][])
      : []),
    ["Submitted", studentDate(item.submittedAt) ?? "?"],
    ...(item.emailVerifiedAt
      ? ([["Email verified", studentDate(item.emailVerifiedAt) ?? "?"]] as [string, string][])
      : []),
    ...(item.reviewedAt
      ? ([
          ["Decided", studentDate(item.reviewedAt) ?? "?"],
          ["Decided by", item.reviewedByEmail ?? "(account deleted)"],
        ] as [string, string][])
      : []),
    ...(item.expiresAt
      ? ([["Pro until", studentDate(item.expiresAt) ?? "?"]] as [string, string][])
      : []),
    ...(item.rejectionReason
      ? ([["Rejection reason", item.rejectionReason]] as [string, string][])
      : []),
    ...(item.documentDeleteAt && item.hasDocument
      ? ([["Document deleted on", studentDate(item.documentDeleteAt) ?? "?"]] as [string, string][])
      : []),
  ];
  const isImage = item.documentMime === "image/jpeg" || item.documentMime === "image/png";
  const documentHref = `/admin/students/${item.id}/document`;

  return (
    <>
      <Link href="/admin/students" className="text-sm">
        ← All applications
      </Link>
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Student application</h1>
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
      {!byEmail && (
        <Card className="flex flex-col gap-3 p-6">
          <h2 className="text-lg font-extrabold">Document</h2>
          {item.documentDeleted ? (
            <p>Deleted 30 days after the decision. Only a fingerprint is kept.</p>
          ) : !item.hasDocument ? (
            <p>No document.</p>
          ) : isImage ? (
            // The route sends no-store and nosniff; the image is only ever
            // loaded from our own origin (CSP img-src 'self').
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={documentHref}
              alt="The student's uploaded document"
              className="max-h-[70vh] max-w-full self-start rounded-control border border-line object-contain"
            />
          ) : (
            <p>
              <a href={documentHref} download>
                Download the PDF
              </a>{" "}
              to read it. It is not kept in your browser&apos;s cache.
            </p>
          )}
        </Card>
      )}
      {item.status === "pending" && <ReviewForms id={item.id} />}
    </>
  );
}
