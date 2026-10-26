import type { StaticImageData } from "next/image";

/**
 * An image from a static import, as a plain `<img>`.
 *
 * Not `next/image`: it always adds `style="color:transparent"`, an inline
 * style attribute the strict CSP blocks (style-src has no
 * 'unsafe-inline'; docs/web-architecture.md "Security headers"). The
 * static import still gives the intrinsic size, so layout doesn't shift.
 */
export function StaticImage({
  image,
  alt,
  priority = false,
  className,
}: {
  image: StaticImageData;
  alt: string;
  /** Above the fold: load eagerly and early. */
  priority?: boolean;
  className?: string;
}) {
  return (
    // eslint-disable-next-line @next/next/no-img-element -- see the comment above
    <img
      src={image.src}
      width={image.width}
      height={image.height}
      alt={alt}
      decoding="async"
      loading={priority ? "eager" : "lazy"}
      fetchPriority={priority ? "high" : undefined}
      className={className}
    />
  );
}
