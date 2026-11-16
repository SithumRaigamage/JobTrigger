import "@testing-library/jest-dom/vitest";

import { cleanup } from "@testing-library/react";
import { afterEach, beforeEach } from "vitest";

import { allToolsManifest, useManifest } from "@/content/release";

// Testing Library only auto-cleans when Vitest globals are on; they're off,
// so unmount after every test or renders leak into the next one.
afterEach(cleanup);

// Every test runs with every tool released (the shipped manifest is release
// 1.0, Jenkins only), so tools a release hides stay tested. A test about the
// release itself calls useManifest(); the next test starts from all tools.
beforeEach(() => useManifest(allToolsManifest()));
