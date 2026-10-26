import { cn } from "@/components/cn";
import { Card, Container, Kicker, Section } from "@/components/layout";
import { statusOf } from "@/content/feature-status";

const topics = [
  {
    glyph: "⇄",
    title: "Web setup",
    note: "Servers not showing up",
    faq: "faq-web-setup",
    tone: "bg-running-bg text-running-fg",
  },
  {
    glyph: "J",
    title: "Jenkins tokens",
    note: "Credentials rejected",
    faq: "faq-jenkins-tokens",
    tone: "bg-failed-bg text-failed-fg",
  },
  {
    glyph: "◎",
    title: "Connections",
    note: "VPN and private servers",
    faq: "faq-connections",
    tone: "bg-unstable-bg text-unstable-fg",
  },
  {
    glyph: "◉",
    title: "Your account",
    note: "Passwords and sign-in",
    faq: "faq-account",
    tone: "bg-success-bg text-success-fg",
  },
];

function faqs() {
  return [
    {
      id: "faq-web-setup",
      question: "I added a server on the website but the app doesn’t show it",
      answer:
        "Make sure the app is signed in to the same JobTrigger account. Switch away from the app and back, or pull to refresh on the home screen.",
    },
    {
      id: "faq-jenkins-tokens",
      question: "Jenkins says my credentials are wrong",
      answer:
        "JobTrigger needs a Jenkins API token, not your Jenkins password if your server uses single sign-on. Create one under your name → Security → API Token.",
    },
    {
      id: "faq-connections",
      question: "The app can’t reach my Jenkins server",
      answer:
        "If Jenkins is only on your office network or VPN, connect your phone to that network first. The website can save it either way.",
    },
    {
      id: "faq-account",
      question: "I forgot my JobTrigger password",
      // US-AUTH-08 is deferred; the answer follows its status.
      answer:
        statusOf("password-reset") === "live"
          ? "Choose “Forgot password?” on the sign-in screen and follow the email we send you."
          : "Password reset isn’t available yet. Email support from the address on your account and we will help you.",
    },
  ];
}

/** Support page (design 06; US-WEB-06). The FAQ is native <details>: no JS. */
export function SupportView({ supportEmail }: { supportEmail: string | null }) {
  return (
    <main className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid>
        <Container
          width="narrow"
          className="flex flex-col items-center gap-4.5 pt-22 pb-30 text-center"
        >
          <Kicker>Support</Kicker>
          <h1 className="text-h1 md:text-6xl">How can we help?</h1>
          <p className="text-lg text-fg-secondary">
            Most setup problems are one of the four below.
          </p>
        </Container>
      </Section>

      <Container width="narrow" className="-mt-18 flex flex-col gap-8 pb-26">
        <ul className="grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-3.5">
          {topics.map((topic) => (
            <li key={topic.title}>
              <a
                href={`#${topic.faq}`}
                className="flex h-full flex-col gap-2.5 rounded-[20px] border border-line bg-card p-5.5 text-fg no-underline shadow-lift hover:text-fg"
              >
                <span
                  aria-hidden="true"
                  className={cn(
                    "flex size-10 items-center justify-center rounded-xl font-extrabold",
                    topic.tone,
                  )}
                >
                  {topic.glyph}
                </span>
                <span className="font-bold">{topic.title}</span>{" "}
                <span className="text-[0.8125rem] text-muted">{topic.note}</span>
              </a>
            </li>
          ))}
        </ul>

        <Card radius="panel" id="faq" className="overflow-hidden">
          <h2 className="sr-only">Common questions</h2>
          {faqs().map((faq, index) => (
            <details
              key={faq.id}
              id={faq.id}
              open={index === 0}
              className="group scroll-mt-24 border-b border-line last:border-b-0"
            >
              <summary className="flex min-h-16 cursor-pointer list-none items-center justify-between gap-4 px-6 py-5 font-semibold [&::-webkit-details-marker]:hidden">
                {faq.question}
                <span
                  aria-hidden="true"
                  className="flex size-8 flex-none items-center justify-center rounded-full bg-raised text-lg text-fg-secondary group-open:bg-accent group-open:text-on-accent"
                >
                  <span className="group-open:hidden">+</span>
                  <span className="hidden group-open:inline">−</span>
                </span>
              </summary>
              <p className="px-6 pb-5.5 text-[0.9375rem] leading-[1.65] text-muted">{faq.answer}</p>
            </details>
          ))}
        </Card>

        <section
          aria-labelledby="stuck-heading"
          className="relative overflow-hidden rounded-3xl bg-accent text-on-accent"
        >
          <div
            aria-hidden="true"
            className="absolute -right-15 -bottom-20 size-65 rounded-full border-36 border-on-accent/12"
          />
          <div className="relative flex flex-wrap items-center justify-between gap-5 p-9">
            <div className="flex min-w-0 flex-[1_1_360px] flex-col gap-2">
              <h2 id="stuck-heading" className="text-[1.625rem] font-extrabold">
                Still stuck?
              </h2>
              <p className="text-[0.9375rem] leading-relaxed">
                Tell us your app version and what you tried. Never send us a token — we will never
                ask for one.
              </p>
            </div>
            {supportEmail ? (
              <a
                href={`mailto:${supportEmail}`}
                className="flex h-13 items-center rounded-full bg-on-accent px-6 font-bold text-accent-hover no-underline hover:text-accent-hover"
              >
                Email support
              </a>
            ) : (
              // The address comes from the backend (shared with the app); if
              // it can't be loaded, say so rather than link nowhere.
              <p className="text-[0.9375rem] font-semibold">
                Support email is unavailable right now. Please try again shortly.
              </p>
            )}
          </div>
        </section>
      </Container>
    </main>
  );
}
