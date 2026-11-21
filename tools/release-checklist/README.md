# Release checklist page (reusable)

A one-page release checklist you can use for any project. Open it, read what
is left, tick tasks as you finish them.

- `release-checklist.html` — the page. **The same file for every project**;
  never edit it per project.
- `checklist-data.js` — the tasks. **The only file that changes** per project
  and release. The copy in this folder is a small example.

No build step and no internet: the page works when you double-click it
(`file://`) and when it is hosted. It loads the data with a plain `<script>`
tag, which is why the data is a `.js` file and not `.json` (browsers block
`fetch` on `file://`).

## Use it in another project

1. Make a folder for the release, e.g. `Releases/v2.3.0/`.
2. Copy `release-checklist.html` into it, unchanged.
3. Write a `checklist-data.js` next to it (start from the example here).
4. Double-click `release-checklist.html`.

To update the page itself, change the master here and copy it again into each
release folder that should get the change.

## What the page does

- Project, version, target date, and progress overall and per section.
- Each task: a plain-English title, numbered steps, who does it, cost, what
  it waits for, and a "must have" or "nice to have" tag.
- Filters: **Only what's left**, **Only my tasks**, **Only must-haves**
  (remembered in the browser).
- A task whose `waitsFor` tasks aren't done shows **Blocked** and
  "Waits for: …". It can still be ticked.
- **Ticks** are saved in this browser only (`localStorage`, one key per
  project + version). If storage is blocked (a private window) the page still
  works and says ticks won't be kept.
- **Export ticks** shows the ticks as JSON with Copy and Download buttons.
  Give that JSON to Claude to record the ticks as `done: true` in the data.
- **Reset ticks** asks on the page before clearing. Tasks marked `done: true`
  in the data stay done.
- Light and dark mode (follows the system), phone-sized screens, and clean
  printing (filters and buttons are hidden; links print their address).
- Task text can't be edited on the page; change `checklist-data.js`.

## Data format

```js
window.CHECKLIST = {
  project: "JobTrigger",          // used in the title and the storage key
  version: "1.0.0",               // used in the title and the storage key
  targetDate: "not set",          // free text, e.g. "2026-12-15"
  updated: "2026-11-22",          // when the data was last changed
  intro: "Optional one-line description.",
  people: { me: "Me", claude: "Claude" },   // optional: labels for `who`
  sections: [
    {
      id: "hosting",              // unique per section
      title: "Hosting and deploy",
      intro: "Optional line under the heading.",
      tasks: [
        {
          id: "render-backend",   // unique across the whole file; never reuse
          title: "Host the backend on Render",
          who: "me",              // "me", "claude" or "both"
          cost: "about $7 a month", // optional
          must: true,             // true = must have before release, false = nice to have
          waitsFor: ["atlas-prod"], // optional: ids of tasks that must be done first
          done: false,            // true = already done (shows ticked and locked)
          steps: [                // 2–6 short steps
            "Open the [Render dashboard](https://dashboard.render.com).",
            "Pick the **Singapore** region."
          ],
          note: "Optional extra line, e.g. where the details are."
        }
      ]
    }
  ]
};
```

Text in `title`, `steps`, `note` and `intro` is plain text with three small
extras: `[label](https://…)` makes a link (http, https or mailto only),
`` `code` `` shows code, and `**words**` shows them in bold. Anything else,
including HTML, is shown as typed.

If the data has a mistake (a missing id, a duplicate id, a `waitsFor` that
points at no task), the page lists it at the top.

## Writing good tasks

- Title: what gets done, in plain words ("Host the backend on Render"), not
  a ticket id.
- Steps: 2–6, each one action, with the real link to the page where it
  happens. Explain any needed term in a few words, e.g. "DNS (the settings
  that point your domain at a server)".
- Only real tasks for this release. Mark finished ones `done: true` rather
  than deleting them, so the count stays honest.
