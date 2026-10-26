import type { Credential, Tool } from "@/domain/credentials";

export const addServerHref = (tool?: Tool) => (tool ? `/servers/new?tool=${tool}` : "/servers/new");

/** The edit page for one credential (P15-18). */
export const editServerHref = (credential: Pick<Credential, "tool" | "id">) =>
  `/servers/${credential.tool}/${encodeURIComponent(credential.id)}`;
