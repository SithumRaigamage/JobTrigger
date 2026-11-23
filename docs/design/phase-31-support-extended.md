# Design — richer support reports and screenshots (Phase 31)

Sources: `docs/user-stories/shared/11-support.md` (US-SUP-05…07),
`tasks/phase-31-support-extended.md`. Target: **1.1**, not 1.0.0.

## Shape of the change

```
Flutter form / website form
  → POST /api/support/tickets  (x-auth-token)
      text + options + up to 3 base64 screenshots
  → SupportTicket (encrypted fields, encrypted image bytes)
  → owner email (count + admin link, no images)
  → /admin/support (super admin) → screenshot route (binary, no-store)
```

Three layers, following `CLAUDE.md` §4:

- **Domain (app, plain Dart)**: `SupportCategory` gains three values but keeps
  the four existing `wire` strings. New `SupportArea` and `SupportImpact`
  enums; `SupportTicket` gains `areas`, `impact` and `screenshotCount`.
  `SupportScreenshot` holds a picked file (name, bytes, mime) in memory only.
- **Data (app)**: `SupportRepositoryImpl.submit` posts the same JSON the
  website does, base64-encoding images like the student document flow. The
  user-facing `GET` never parses or stores returned image bytes.
- **Presentation (app)**: the existing `SupportScreen` keeps its single-scroll
  layout; chips become a wrap for category, a wrap for areas, and a dropdown
  for impact. A screenshot row shows thumbnails from `Uint8List` with remove
  buttons. No notifier holds bytes longer than one submission.
- **Backend**: `SupportTicket` schema adds `areas` (array of strings),
  `impact` (enum) and `screenshots` (array of `{ data, mime, size, hash,
  deleteAt }`, encrypted with `security/secretCipher.js`). The controller
  reuses the magic-byte checks from `lib/studentDocument.js` for JPG/PNG, and
  the existing scrubber for text. New super-admin detail + screenshot routes
  sit beside the existing list/status routes.
- **Website**: a signed-in form on `/support` (not anonymous — P25-05 still
  holds) posts to the same endpoint through a Server Action. Admin pages
  mirror `app/(portal)/admin/students/`: `/admin/support` queue,
  `/admin/support/[id]` detail, and a route handler for each image.
  Read `node_modules/next/dist/docs/` (per `JobTrigger-Web/AGENTS.md`) before
  writing any Next.js code.

## Decisions (owner-approved 2026-11-23)

| Decision | Choice | Reason |
|---|---|---|
| Release | 1.1 | Keeps the 1.0.0 freeze clean |
| Categories | 7, old wire values unchanged | Backward compatibility with filed tickets |
| Areas | multi-select, optional | One primary category keeps counts honest |
| Impact | single select, required | Cheap triage signal |
| Picking | `file_picker` only | Existing approved dependency; no camera package |
| Limits | 3 files, 5 MB each, JPG/PNG | Matches the student-document precedent |
| Storage | encrypted at rest, 30-day deletion | NFR-SEC-08; screenshots can contain personal data |
| Owner email | count + admin link, no attachments | Deliverability and privacy |
| Admin view | website only | Owner already triages students/subscriptions there |

## Security and failure rules

- Screenshots are **not** scrubbed by the text scrubber: the user is warned to
  blur secrets before sending. The backend never logs bytes, names or MIME
  types, only a ticket id and a count.
- Image bytes are encrypted with the same key scheme as student documents,
  `select: false` in Mongoose, and only decrypted by the admin screenshot
  route; that route sets `Cache-Control: no-store` and checks super-admin on
  every request.
- Text validation failures leave the form filled in; a rejected image names
  the file and the reason without clearing the other fields.
- Demo mode never posts a support ticket (existing `DemoSupportRepository`
  behaviour stays).
- No new state-management, HTTP or routing library; no new Flutter package.
