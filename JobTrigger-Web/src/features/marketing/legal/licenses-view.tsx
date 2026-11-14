import { openSourceGroups } from "@/content/open-source";

import { routes } from "../site-links";

import { LegalSection, LegalShell } from "./legal-shell";

const toc = [
  ...openSourceGroups.map((group) => ({ id: group.id, label: group.title })),
  { id: "about", label: "About this list" },
];

/**
 * Open-source licenses (PE-03): the app's About JobTrigger screen links here
 * (`openSourceLicensesUrl`). Lists each project's direct runtime
 * dependencies with the licence they declare and a link to the full text.
 */
export function LicensesView() {
  return (
    <LegalShell title="Open-source licenses" current={routes.licenses} toc={toc}>
      <p className="text-lg leading-[1.7] text-fg-secondary">
        JobTrigger is built with open-source software. Thank you to everyone who maintains these
        packages.
      </p>

      {openSourceGroups.map((group) => (
        <LegalSection key={group.id} id={group.id} title={group.title}>
          <ul className="flex flex-col divide-y divide-line">
            {group.packages.map((pkg) => (
              <li key={pkg.name} className="flex flex-wrap items-baseline gap-x-3 gap-y-1 py-2.5">
                <a href={pkg.url} rel="noopener noreferrer" className="font-bold">
                  {pkg.name}
                </a>
                {pkg.version && <span className="text-sm text-muted">{pkg.version}</span>}
                <span className="ml-auto text-sm">{pkg.license ?? "See licence on registry"}</span>
              </li>
            ))}
          </ul>
        </LegalSection>
      ))}

      <LegalSection id="about" title="About this list">
        <p>
          These are the packages each part of JobTrigger depends on directly. Each name links to
          the package&apos;s page, where its full licence text and its own dependencies are listed.
        </p>
      </LegalSection>
    </LegalShell>
  );
}
