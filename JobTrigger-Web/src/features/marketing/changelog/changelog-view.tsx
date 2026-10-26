import { cn } from "@/components/cn";
import { Container, Kicker } from "@/components/layout";
import {
  afterLaunch,
  firstReleaseVersion,
  releases,
  upcomingRelease,
  type ChangeTag,
  type UpcomingTag,
} from "@/content/changelog";

const tagTones: Record<ChangeTag | UpcomingTag, string> = {
  Ships: "bg-success-bg text-success-fg",
  New: "bg-success-bg text-success-fg",
  Beta: "bg-running-bg text-running-fg",
  Improved: "bg-running-bg text-running-fg",
  Next: "bg-neutral-bg text-neutral-fg",
  Fixed: "bg-neutral-bg text-neutral-fg",
};

type Entry = {
  key: string;
  version: string;
  date: string;
  title: string;
  upcoming: boolean;
  items: { tag: ChangeTag | UpcomingTag; text: string }[];
};

function entries(): Entry[] {
  const next = afterLaunch();
  const after: Entry[] =
    next.length > 0
      ? [
          {
            key: "next",
            version: "Next",
            date: "No dates yet",
            title: releases.length > 0 ? "Coming next" : "After launch",
            upcoming: false,
            items: next,
          },
        ]
      : [];

  // Before the first release (US-WEB-08 "the state at launch"): one entry
  // for v1.0 built from the feature statuses, then what follows it.
  if (releases.length === 0) {
    return [
      {
        key: "first",
        version: firstReleaseVersion,
        date: "Coming soon",
        title: "First public release",
        upcoming: true,
        items: upcomingRelease(),
      },
      ...after,
    ];
  }
  return [
    ...after,
    ...releases.map((release) => ({
      key: release.version,
      version: release.version,
      date: new Date(release.date).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "long",
        year: "numeric",
        timeZone: "UTC",
      }),
      title: release.title,
      upcoming: false,
      items: release.items,
    })),
  ];
}

/** Changelog (designs 07 / 21; US-WEB-08). */
export function ChangelogView() {
  const list = entries();

  return (
    <main data-surface="dark" className="flex-1 bg-dot-grid">
      <Container width="medium" className="flex flex-col gap-14 pt-22 pb-28">
        <div className="flex flex-col gap-3.5">
          <Kicker>Changelog</Kicker>
          <h1 className="text-h1 md:text-6xl">What&apos;s new in JobTrigger</h1>
          <p className="max-w-155 text-lg leading-relaxed text-fg-secondary">
            {releases.length === 0
              ? "JobTrigger hasn't launched yet. Here's what the first release brings, and what follows it."
              : "Every release, newest first."}
          </p>
        </div>

        <ol className="flex flex-col">
          {list.map((entry, index) => (
            <li key={entry.key} className="flex gap-4 md:gap-7">
              <div className="flex w-10 flex-none flex-col items-center">
                <span
                  aria-hidden="true"
                  className={cn(
                    "mt-1.5 size-4 flex-none rounded-full",
                    index === 0 ? "bg-accent ring-6 ring-accent/30" : "bg-line-strong",
                  )}
                />
                <span
                  className={cn(
                    "mt-2.5 w-0.5 flex-1",
                    index < list.length - 1 ? "bg-line" : "bg-transparent",
                  )}
                />
              </div>
              <div className="flex min-w-0 flex-auto flex-wrap gap-x-8 gap-y-4 pb-12">
                <div className="flex flex-[0_0_150px] flex-col gap-1.5 pt-0.5">
                  <span className="font-mono font-medium">{entry.version}</span>
                  <span className="text-[0.8125rem] text-muted">{entry.date}</span>
                </div>
                <article className="flex min-w-0 flex-[1_1_400px] flex-col gap-3.5 rounded-panel border border-line bg-card p-6.5">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <h2 className="text-[1.375rem] font-extrabold">{entry.title}</h2>
                    {entry.upcoming && (
                      <span className="rounded-full bg-accent px-2.5 py-0.75 text-xs font-bold text-on-accent">
                        Upcoming
                      </span>
                    )}
                  </div>
                  <ul className="flex flex-col gap-2.5">
                    {entry.items.map((item) => (
                      <li
                        key={item.text}
                        className="flex items-baseline gap-2.5 text-[0.9375rem] leading-[1.55] text-fg-secondary"
                      >
                        <span
                          className={cn(
                            "flex-none rounded-md px-2 py-0.5 text-[0.6875rem] font-bold tracking-[0.04em] uppercase",
                            tagTones[item.tag],
                          )}
                        >
                          {item.tag}
                        </span>{" "}
                        {item.text}
                      </li>
                    ))}
                  </ul>
                </article>
              </div>
            </li>
          ))}
        </ol>
      </Container>
    </main>
  );
}
