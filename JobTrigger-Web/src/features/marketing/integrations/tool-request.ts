/**
 * The same pre-addressed email the app's "Need another tool? Tell us" link
 * opens (tool_selection_screen.dart `toolRequestUri`), so requests from the
 * app and the site land in one inbox.
 */
export function toolRequestHref(supportEmail: string): string {
  const subject = encodeURIComponent("JobTrigger tool request");
  const body = encodeURIComponent("The CI/CD tool I would like to use: ");
  return `mailto:${supportEmail}?subject=${subject}&body=${body}`;
}
