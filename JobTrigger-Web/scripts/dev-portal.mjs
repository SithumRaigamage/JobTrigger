// `npm run dev:portal`: `next dev` with the setup portal switched on, against
// the backend running on this machine (`./setup-dev.sh`, which uses MongoDB
// Atlas). See docs/dev-setup.md, "Use the portal locally".
//
// Fills the two portal settings unless they're already set in the shell:
//   JOBTRIGGER_BACKEND_URL  http://127.0.0.1:5001 (the local backend)
//   SESSION_SECRET          a fresh random secret for this run only. It is
//                           never printed or written anywhere; a new one on
//                           each start just means signing in again.
// Arguments pass through to `next dev`, e.g. `npm run dev:portal -- -p 3001`.
import { randomBytes } from "node:crypto";
import { spawn } from "node:child_process";

const env = { ...process.env };
env.JOBTRIGGER_BACKEND_URL ||= "http://127.0.0.1:5001";
const secretFromShell = Boolean(env.SESSION_SECRET);
env.SESSION_SECRET ||= randomBytes(32).toString("base64");

console.log(`Portal backend: ${env.JOBTRIGGER_BACKEND_URL}`);
console.log(
  secretFromShell
    ? "Session secret: from your shell"
    : "Session secret: generated for this run (sign in again after a restart)",
);

// npm puts node_modules/.bin on PATH, so `next` is this project's own copy.
const child = spawn("next", ["dev", ...process.argv.slice(2)], { env, stdio: "inherit" });

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => child.kill(signal));
}
child.on("exit", (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  else process.exit(code ?? 1);
});
