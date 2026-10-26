import { Download } from "@/features/marketing/home/download";
import { Hero } from "@/features/marketing/home/hero";
import { SetupBand } from "@/features/marketing/home/setup-band";
import { Timeline } from "@/features/marketing/home/timeline";
import { ToolStrip } from "@/features/marketing/home/tool-strip";
import { Trust } from "@/features/marketing/home/trust";

// Home (designs 01 / 18; US-WEB-01, 02). Each section follows the feature
// statuses, so the same page is the pre-launch and the launch version.
export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <Hero />
      <ToolStrip />
      <Timeline />
      <SetupBand />
      <Trust />
      <Download />
    </main>
  );
}
