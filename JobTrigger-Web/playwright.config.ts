import { defineConfig, devices } from "@playwright/test";

const port = 3100;

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
  webServer: {
    // A production build, not `next dev`: it tests what ships (headers,
    // caching), and Next 16 allows only one `next dev` per project, so a
    // developer's running dev server (3000) would block the tests.
    command: `npm run build && npm run start -- --port ${port}`,
    url: `http://localhost:${port}`,
    reuseExistingServer: false,
    // Test-only values, passed here rather than through an env file. The
    // backend URL is a port nothing listens on until a spec starts its own
    // fake backend there; the session secret is a fixed test string.
    env: {
      JOBTRIGGER_BACKEND_URL: "http://127.0.0.1:5999",
      SESSION_SECRET: "e2e-session-secret-0123456789abcdef",
      SITE_URL: `http://localhost:${port}`,
    },
    timeout: 180_000,
  },
});
