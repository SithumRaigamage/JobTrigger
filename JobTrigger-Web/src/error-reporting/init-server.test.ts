// @vitest-environment node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import * as Sentry from "@sentry/nextjs";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { initServerReporting, shutdownServerReporting } from "./init-server";
import { createOutbox, withOutbox, type Envelope } from "./outbox";

const TOKEN = ["a1b2c3d4", "e5f60718", "2a3b4c5d", "6e7f8091"].join("");
const config = {
  dsn: "https://publickey@glitchtip.invalid/1",
  environment: "development",
  release: "0.1.0",
};

describe("server crash reporting", () => {
  let sent: Envelope[];
  let dir: string;

  beforeEach(() => {
    sent = [];
    dir = fs.mkdtempSync(path.join(os.tmpdir(), "crash-outbox-"));
  });
  afterEach(async () => {
    await shutdownServerReporting();
    fs.rmSync(dir, { recursive: true, force: true });
  });

  const transport = (statusCode: number) => () =>
    ({
      send: async (envelope: Envelope) => {
        sent.push(envelope);
        return { statusCode };
      },
      flush: async () => true,
    }) as never;

  // A portal action that fails with a token in its input: the error message,
  // the request headers and the URL all carry it.
  const failAction = () =>
    Sentry.captureRequestError(
      new Error(`add server failed for token ${TOKEN}`),
      {
        path: `/servers/new?token=${TOKEN}`,
        method: "POST",
        headers: { "x-auth-token": TOKEN, authorization: `Bearer ${TOKEN}`, "next-action": "abc" },
      },
      { routerKind: "App Router", routePath: "/servers/new", routeType: "action" },
    );

  it("reports a failing portal action without the token", async () => {
    initServerReporting(config, { transport: transport(200), outboxDir: dir });
    failAction();
    await Sentry.flush(2000);
    const events = sent.flatMap((e) => e[1]).filter((item) => item[0].type === "event");
    expect(events.length).toBeGreaterThan(0);
    expect(JSON.stringify(sent)).not.toContain(TOKEN);
  });

  it("does nothing without a DSN", async () => {
    expect(initServerReporting(null, { transport: transport(200), outboxDir: dir })).toBe(false);
    failAction();
    await Sentry.flush(500);
    expect(sent).toHaveLength(0);
  });

  it("keeps the scrubbed event on disk while the host is unreachable", async () => {
    initServerReporting(config, { transport: transport(503), outboxDir: dir });
    failAction();
    await Sentry.flush(2000);
    const files = fs.readdirSync(dir);
    expect(files).toHaveLength(1);
    const file = path.join(dir, files[0]);
    expect(fs.statSync(file).mode & 0o777).toBe(0o600);
    const text = fs.readFileSync(file, "utf8");
    expect(text).not.toContain(TOKEN);
    expect(text).not.toContain("glitchtip.invalid");
  });
});

describe("outbox", () => {
  let dir: string;
  beforeEach(() => {
    dir = fs.mkdtempSync(path.join(os.tmpdir(), "crash-outbox-"));
  });
  afterEach(() => fs.rmSync(dir, { recursive: true, force: true }));

  const dsn = "https://publickey@glitchtip.invalid/1";
  const envelope = (id: string): Envelope => [{ dsn }, [[{ type: "event" }, { event_id: id }]]];

  it("retries stored events and deletes them once accepted", async () => {
    const outbox = createOutbox({ dir, dsn });
    outbox.add(envelope("a"));
    outbox.add(envelope("b"));
    const received: Envelope[] = [];
    await outbox.drain(async (e) => {
      received.push(e);
      return { statusCode: 200 };
    });
    expect(received).toHaveLength(2);
    expect(received[0][0].dsn).toBe(dsn);
    expect(fs.readdirSync(dir)).toHaveLength(0);
  });

  it("keeps lines that still fail", async () => {
    const outbox = createOutbox({ dir, dsn });
    outbox.add(envelope("a"));
    await outbox.drain(async () => ({ statusCode: 503 }));
    expect(fs.readdirSync(dir)).toHaveLength(1);
  });

  it("drains on startup", async () => {
    createOutbox({ dir, dsn }).add(envelope("old"));
    const received: Envelope[] = [];
    const wrapped = withOutbox(
      {
        send: async (e) => {
          received.push(e);
          return { statusCode: 200 };
        },
        flush: async () => true,
      },
      createOutbox({ dir, dsn }),
      60000,
    );
    await wrapped.drain();
    wrapped.stop();
    expect(received).toHaveLength(1);
  });

  it("stops at the size cap and prunes old files", () => {
    const capped = createOutbox({ dir, dsn, maxBytes: 100 });
    expect(capped.add(envelope("a"))).toBe(true);
    expect(capped.add(envelope("b"))).toBe(true);
    expect(capped.add(envelope("c"))).toBe(false);
    fs.writeFileSync(path.join(dir, "2020-01-01.jsonl"), "{}\n");
    createOutbox({ dir, dsn }).add(envelope("d"));
    expect(fs.readdirSync(dir)).not.toContain("2020-01-01.jsonl");
  });

  it("ignores anything that is not an event", () => {
    expect(createOutbox({ dir }).add([{}, [[{ type: "session" }, {}]]])).toBe(false);
  });
});
