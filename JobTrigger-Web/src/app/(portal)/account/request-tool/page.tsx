import type { Metadata } from "next";

import { RequestToolForm } from "@/features/support/request-tool-form";

export const metadata: Metadata = { title: "Request a tool" };

/** US-WEB-04: signed in only (the portal layout checks the session). */
export default function RequestToolPage() {
  return <RequestToolForm />;
}
