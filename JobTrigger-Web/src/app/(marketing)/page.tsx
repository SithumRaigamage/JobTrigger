import { Hero } from "@/features/marketing/home/hero";
import { Timeline } from "@/features/marketing/home/timeline";
import { ToolStrip } from "@/features/marketing/home/tool-strip";

// Home (designs 01 / 18). Sections arrive in P15-06a–d.
export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <Hero />
      <ToolStrip />
      <Timeline />
    </main>
  );
}
