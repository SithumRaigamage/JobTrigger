import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/reduce_transparency_notifier.dart';

/// Shared frosted-glass surface (`docs/user-stories/00-design-system-
/// glassmorphism.md`, US-DESIGN-01) — replaces the `Material(color:
/// surfaceContainerHigh) + InkWell` idiom that was repeated ad hoc across
/// `_ToolCard`, `_JobTile`, `_LastBuildCard`, and `ToastView`.
///
/// Two flavors instead of one uniform blur, per US-DESIGN-04's performance
/// guardrail — blurring only does real visual work where something is
/// actually scrolling/moving behind the surface:
///
///  * [GlassSurface.chrome] — app bars, the bottom nav, bottom sheets,
///    dialogs: fixed overlays above scrolling content, where a
///    `BackdropFilter` blur is cheap (one instance on screen at a time) and
///    visually meaningful.
///  * [GlassSurface.card] — list rows, tool cards, tiles, toasts:
///    translucent fill + hairline border + soft shadow, no `BackdropFilter`
///    — cheap enough to repeat dozens of times in a scrolling list.
///
/// Respects the reduce-transparency accessibility fallback (US-DESIGN-03):
/// when [ReduceTransparencyNotifier] is on, blur is skipped entirely and an
/// opaque fill is used instead, regardless of [blurred].
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blurred = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.margin,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.brightness,
  });

  const GlassSurface.chrome({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.padding,
    this.margin,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.brightness,
  }) : blurred = true;

  const GlassSurface.card({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.margin,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.brightness,
  }) : blurred = false;

  final Widget child;
  final bool blurred;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Overrides the light/dark glass token choice instead of deriving it
  /// from `Theme.of(context).brightness` — for a surface whose *background*
  /// is a fixed color independent of the app theme (the build-log console's
  /// `Scaffold(backgroundColor: Colors.black)`, regardless of light/dark
  /// mode). Without this, the chrome would use light-theme glass tokens
  /// over a black backdrop: pale fill, harsh contrast against the console.
  final Brightness? brightness;

  /// Forwarded to the internal `InkWell` — matches the press-tracking
  /// idiom `_ToolCard` used (`onTapDown`/`onTapUp`/`onTapCancel` driving an
  /// `AnimatedScale`) before this widget replaced its ad hoc `Material` +
  /// `InkWell`. Only meaningful when [onTap] is also set.
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;

  static const _blurSigma = 12.0;
  static const _shadowBlurRadius = 20.0;
  static const _shadowOffset = Offset(0, 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark =
        (brightness ?? Theme.of(context).brightness) == Brightness.dark;
    final reduceTransparency = ref.watch(reduceTransparencyNotifierProvider);
    final applyBlur = blurred && !reduceTransparency;

    final fill = reduceTransparency
        ? (isDark
              ? AppColors.glassFallbackFillDark
              : AppColors.glassFallbackFillLight)
        : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight);
    final border = isDark
        ? AppColors.glassBorderDark
        : AppColors.glassBorderLight;
    final shadow = isDark
        ? AppColors.glassShadowDark
        : AppColors.glassShadowLight;

    Widget body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (onTap != null) {
      body = InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        child: body,
      );
    }

    // Always a local Material ancestor here, inside the DecoratedBox below
    // -- not just when this GlassSurface owns [onTap]. A `ListTile` (or any
    // other Material-ink descendant) always looks for the *nearest*
    // Material to paint on; without one in between, it finds one further
    // up the tree, and this surface's DecoratedBox fill would then paint
    // over/hide those splashes (Flutter's own "ListTile background color
    // or ink splashes may be invisible" warning). Covers both a
    // GlassSurface.card with its own onTap (the InkWell above) and one
    // that just groups several independently-tappable children (e.g.
    // multiple ListTiles in one card).
    body = Material(color: Colors.transparent, child: body);

    // BackdropFilter blur must sit *inside* the ClipRRect (so it only
    // samples/paints within the rounded bounds), but a BoxShadow must sit
    // *outside* it (ClipRRect would otherwise clip the shadow itself) —
    // hence the two nested containers below rather than one BoxDecoration.
    final glass = ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          if (applyBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: border, width: 1),
            ),
            child: body,
          ),
        ],
      ),
    );

    final withShadow = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: _shadowBlurRadius,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: glass,
    );

    return margin == null
        ? withShadow
        : Padding(padding: margin!, child: withShadow);
  }
}

/// Drop-in glass replacement for a plain `AppBar(...)` call site — same
/// commonly-used params, transparent background, wrapped in
/// [GlassSurface.chrome]. Pair with `Scaffold(extendBodyBehindAppBar:
/// true)` and top padding on the scrollable body; otherwise there's
/// nothing behind the bar to blur and it reads as a flat translucent color
/// instead of genuine glass.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.brightness,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  /// See [GlassSurface.brightness] — set this on a screen whose background
  /// is a fixed color independent of the app theme (e.g. the build-log
  /// console), so the bar's fill *and* its title/icon colors stay legible
  /// against it regardless of light/dark mode.
  final Brightness? brightness;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final foregroundColor = switch (brightness) {
      Brightness.dark => Colors.white,
      Brightness.light => Colors.black,
      null => null,
    };
    return GlassSurface.chrome(
      brightness: brightness,
      child: AppBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
