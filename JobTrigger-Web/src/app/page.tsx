import { Button } from "@/components/button";
import { Card, Container, Kicker, Section } from "@/components/layout";

// Token sample page (P15-02): every primitive on both surfaces, for
// checking against UI-UX/Web. Replaced by the home page in P15-06.

const statuses = [
  { label: "Success", bg: "bg-success-bg", fg: "text-success-fg" },
  { label: "Failed", bg: "bg-failed-bg", fg: "text-failed-fg" },
  { label: "Unstable", bg: "bg-unstable-bg", fg: "text-unstable-fg" },
  { label: "Running", bg: "bg-running-bg", fg: "text-running-fg" },
  { label: "Aborted", bg: "bg-neutral-bg", fg: "text-neutral-fg" },
] as const;

function Sample({ heading }: { heading: string }) {
  return (
    <Container className="flex flex-col gap-8 py-20">
      <div className="flex flex-col gap-4">
        <Kicker>Design tokens</Kicker>
        <h2 className="text-h2">{heading}</h2>
        <p className="max-w-155 text-lg text-muted">
          Inter for interface text; <span className="font-mono text-fg">JetBrains Mono #1428</span>{" "}
          for what a CI tool printed. <a href="#top">A link</a>.
        </p>
      </div>
      <div className="flex flex-wrap gap-3">
        <Button size="lg">Primary</Button>
        <Button size="lg" variant="secondary">
          Secondary
        </Button>
        <Button size="lg" variant="ghost">
          Ghost
        </Button>
        <Button size="lg" disabled>
          Disabled
        </Button>
      </div>
      <Card className="flex flex-col gap-4 p-6">
        <p className="font-semibold">Card</p>
        <ul className="flex flex-wrap gap-2">
          {statuses.map((status) => (
            <li
              key={status.label}
              className={`rounded-full px-3 py-1 text-sm font-semibold ${status.bg} ${status.fg}`}
            >
              {status.label}
            </li>
          ))}
        </ul>
      </Card>
    </Container>
  );
}

export default function HomePage() {
  return (
    <main id="top" className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid className="border-b border-line">
        <Container className="pt-24">
          <h1 className="text-display">Trigger. Watch. Fix.</h1>
        </Container>
        <Sample heading="Dark surface" />
      </Section>
      <Section surface="light">
        <Sample heading="Light surface" />
      </Section>
    </main>
  );
}
