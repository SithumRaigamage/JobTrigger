import { Hero } from "@/features/marketing/home/hero";
import { SetupBand } from "@/features/marketing/home/setup-band";
import { Timeline } from "@/features/marketing/home/timeline";
import { ToolStrip } from "@/features/marketing/home/tool-strip";
import { Trust } from "@/features/marketing/home/trust";

// Home (designs 01 / 18). Sections arrive in P15-06a–d.
export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <Hero />
      <ToolStrip />
      <Timeline />
      <SetupBand />
      <Trust />
    </main>
  );
}
