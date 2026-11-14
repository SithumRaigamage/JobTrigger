/*
 * E3: the offline fallback for the website's server side (the browser uses
 * the SDK's IndexedDB transport). Mirrors
 * JobTrigger-Backend/lib/errorReporting/outbox.js: when the reporting host
 * can't be reached, the already-scrubbed event is appended to
 * `<dir>/YYYY-MM-DD.jsonl` (mode 600, capped at 10 MB and 7 days) and
 * retried at startup and every 5 minutes. The DSN is never written.
 */

import fs from "node:fs";
import path from "node:path";

export type Envelope = [Record<string, unknown>, Array<[{ type?: string }, unknown]>];
export type SendResult = { statusCode?: number } | undefined;
type Send = (envelope: Envelope) => PromiseLike<SendResult> | SendResult;

type Limits = { maxBytes: number; maxAgeDays: number; retryEveryMs: number };
const DEFAULTS: Limits = { maxBytes: 10 * 1024 * 1024, maxAgeDays: 7, retryEveryMs: 5 * 60 * 1000 };
const DAY_FILE = /^(\d{4}-\d{2}-\d{2})\.jsonl$/;

const accepted = (status?: number) => status !== undefined && status >= 200 && status < 300;
const rejectedForGood = (status?: number) =>
  status !== undefined && status >= 400 && status < 500 && status !== 408 && status !== 429;

export function createOutbox(options: {
  dir: string;
  dsn?: string;
  now?: () => Date;
  maxBytes?: number;
  maxAgeDays?: number;
}) {
  const { dir, dsn, now = () => new Date() } = options;
  const maxBytes = options.maxBytes ?? DEFAULTS.maxBytes;
  const maxAgeDays = options.maxAgeDays ?? DEFAULTS.maxAgeDays;

  const files = () => {
    try {
      return fs
        .readdirSync(dir)
        .filter((name) => DAY_FILE.test(name))
        .sort();
    } catch {
      return [];
    }
  };
  const sizeOf = (name: string) => {
    try {
      return fs.statSync(path.join(dir, name)).size;
    } catch {
      return 0;
    }
  };

  function prune() {
    const cutoff = now().getTime() - maxAgeDays * 24 * 60 * 60 * 1000;
    for (const name of files()) {
      const day = Date.parse(`${name.match(DAY_FILE)![1]}T23:59:59Z`);
      if (day < cutoff) fs.rmSync(path.join(dir, name), { force: true });
    }
  }

  /** Keep [envelope] for later. Returns false when it wasn't stored. */
  function add(envelope: Envelope): boolean {
    try {
      if (!Array.isArray(envelope) || !envelope[1]?.some((item) => item[0]?.type === "event")) {
        return false;
      }
      fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
      prune();
      const { dsn: _dsn, ...headers } = envelope[0] ?? {};
      void _dsn;
      const line = `${JSON.stringify([headers, envelope[1]])}\n`;
      const total = files().reduce((sum, name) => sum + sizeOf(name), 0);
      if (total + Buffer.byteLength(line) > maxBytes) return false;
      const file = path.join(dir, `${now().toISOString().slice(0, 10)}.jsonl`);
      fs.appendFileSync(file, line, { mode: 0o600 });
      fs.chmodSync(file, 0o600);
      return true;
    } catch {
      return false;
    }
  }

  /** Send every stored line through [send]; keep the ones that fail. */
  async function drain(send: Send): Promise<void> {
    prune();
    for (const name of files()) {
      const file = path.join(dir, name);
      let lines: string[];
      try {
        lines = fs.readFileSync(file, "utf8").split("\n").filter(Boolean);
      } catch {
        continue;
      }
      const keep: string[] = [];
      for (const line of lines) {
        let envelope: Envelope;
        try {
          envelope = JSON.parse(line) as Envelope;
        } catch {
          continue; // a damaged line can't be sent; drop it
        }
        if (dsn) envelope[0] = { ...envelope[0], dsn };
        let status: number | undefined;
        try {
          status = (await send(envelope))?.statusCode;
        } catch {
          status = undefined;
        }
        if (accepted(status) || rejectedForGood(status)) continue;
        keep.push(line);
      }
      if (keep.length === 0) fs.rmSync(file, { force: true });
      else fs.writeFileSync(file, `${keep.join("\n")}\n`, { mode: 0o600 });
    }
  }

  return { add, drain, dir };
}

type InnerTransport = {
  send: (envelope: Envelope) => PromiseLike<SendResult>;
  flush: (timeout?: number) => PromiseLike<boolean>;
};

/** Wrap a Sentry transport with the outbox. */
export function withOutbox(
  inner: InnerTransport,
  outbox: ReturnType<typeof createOutbox>,
  retryEveryMs: number = DEFAULTS.retryEveryMs,
) {
  let draining = false;
  const drain = async () => {
    if (draining) return;
    draining = true;
    try {
      await outbox.drain((envelope) => inner.send(envelope));
    } finally {
      draining = false;
    }
  };

  const timer = setInterval(drain, retryEveryMs);
  timer.unref?.();
  void drain().catch(() => {});

  return {
    async send(envelope: Envelope) {
      let response: SendResult;
      try {
        response = await inner.send(envelope);
      } catch {
        response = undefined;
      }
      const status = response?.statusCode;
      if (!accepted(status) && !rejectedForGood(status)) outbox.add(envelope);
      return response ?? {};
    },
    flush: (timeout?: number) => inner.flush(timeout),
    drain,
    stop: () => clearInterval(timer),
  };
}
