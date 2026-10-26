/**
 * "Skip to content" (WCAG 2.4.1): the first focusable element, hidden until
 * focused, jumping past the repeated header or sidebar to `#content`.
 */
export function SkipLink() {
  return (
    <a
      href="#content"
      className="sr-only rounded-control bg-accent px-4 py-2.5 font-semibold text-on-accent no-underline hover:text-on-accent focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-50"
    >
      Skip to content
    </a>
  );
}
