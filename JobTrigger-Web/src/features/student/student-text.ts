const dateFormat = new Intl.DateTimeFormat("en", { dateStyle: "long", timeZone: "UTC" });

/** "November 16, 2027", or null when there is no usable date. */
export function studentDate(iso: string | null): string | null {
  if (!iso) return null;
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? null : dateFormat.format(date);
}
