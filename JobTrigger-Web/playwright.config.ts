import { defineConfig, devices } from "@playwright/test";

const port = 3100;

/** Also used by specs that seal a session cookie (tests/e2e/session.ts). */
export const E2E_SESSION_SECRET = "e2e-session-secret-0123456789abcdef";

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: "list",
  use: {
    baseURL: `http://localhost:${port}`,
    trace: "on-first-retry",
  },
  projects: [
    { name: "desktop", use: { ...devices["Desktop Chrome"] } },
    // WEB-B4: every page works from 360 px wide.
    {
      name: "mobile",
      use: { ...devices["Desktop Chrome"], viewport: { width: 360, height: 780 } },
    },
  ],
  webServer: [
    {
      // The backend stand-in (tests/e2e/fake-backend.mjs) on the port the
      // site's JOBTRIGGER_BACKEND_URL points at.
      command: "node tests/e2e/fake-backend.mjs",
      url: "http://127.0.0.1:5999/healthz",
      reuseExistingServer: false,
    },
    {
      // A production build, not `next dev`: it tests what ships (headers,
      // caching), and Next 16 allows only one `next dev` per project, so a
      // developer's running dev server (3000) would block the tests.
      command: `npm run build && npm run start -- --port ${port}`,
      url: `http://localhost:${port}`,
      reuseExistingServer: false,
      timeout: 180_000,
      // Test-only values, passed here rather than through an env file.
      env: {
        JOBTRIGGER_BACKEND_URL: "http://127.0.0.1:5999",
        SESSION_SECRET: E2E_SESSION_SECRET,
        SITE_URL: `http://localhost:${port}`,
      },
    },
  ],
});
