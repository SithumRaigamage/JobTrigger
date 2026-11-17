import Link from "next/link";

import { Container, Section } from "@/components/layout";
import { demoServers } from "@/content/demo-servers";
import { ServersView } from "@/features/servers/servers-view";

import { routes } from "../site-links";

/**
 * "See the demo" (E2, PE-16): the real portal's My servers view on sample
 * data. Static: no sign-in, no backend request and no server action, so
 * nothing typed or clicked here is stored or sent anywhere.
 */
export function DemoView() {
  return (
    <main id="content" tabIndex={-1} className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid className="border-b border-line">
        <Container className="flex flex-col gap-3 py-8">
          <p className="text-sm font-semibold text-running-fg">Demo</p>
          <p className="max-w-170 text-[0.9375rem] leading-relaxed text-fg-secondary">
            This is a preview of the setup portal with sample servers. It needs no account, saves
            nothing and contacts no server. The tokens shown are placeholders, masked the way your
            own are.
          </p>
          <div className="flex flex-wrap gap-5 text-[0.9375rem] font-semibold">
            <Link href={routes.signIn}>Set up your own servers →</Link>
            <Link href={routes.features}>Take the tour</Link>
          </div>
        </Container>
      </Section>
      <Container className="flex flex-col gap-7 pt-10 pb-24">
        <ServersView servers={demoServers} failure={null} preview />
      </Container>
    </main>
  );
}
