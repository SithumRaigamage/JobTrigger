// @vitest-environment node
import { describe, expect, it } from "vitest";

import robots from "@/app/robots";
import sitemap from "@/app/sitemap";

import { pageMetadata } from "./page-metadata";
import { publicPaths } from "./public-pages";

describe("pageMetadata", () => {
  it("gives a page its title, description, canonical and preview tags", () => {
    const metadata = pageMetadata({
      title: "Security",
      description: "How tokens travel.",
      path: "/security",
    });

    expect(metadata.title).toBe("Security");
    expect(metadata.alternates?.canonical).toBe("/security");
    expect(metadata.openGraph).toMatchObject({
      url: "/security",
      title: "Security · JobTrigger",
      description: "How tokens travel.",
    });
    expect(metadata.twitter).toMatchObject({ card: "summary_large_image" });
  });

  it("leaves the home title to the root default", () => {
    expect(pageMetadata({ title: null, description: "x", path: "/" }).title).toBeUndefined();
  });
});

describe("robots and sitemap", () => {
  it("keep crawlers out of every portal path", () => {
    const rules = robots().rules as { disallow: string[] };

    expect(rules.disallow).toEqual(["/sign-in", "/sign-up", "/servers", "/account"]);
  });

  it("list every public page and nothing from the portal", () => {
    const urls = sitemap().map((entry) => entry.url);

    expect(urls).toHaveLength(publicPaths.length);
    expect(urls).toContain("http://localhost:3000/security");
    expect(urls.some((url) => /sign-in|servers|account/.test(url))).toBe(false);
  });
});
