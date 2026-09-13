import 'package:flutter/material.dart';

/// Deliberately thin: the SwiftUI app used system Dynamic Type text styles
/// (`.headline`, `.caption`, etc.) almost everywhere, which Material 3's
/// default `TextTheme` already covers — screens should reach for
/// `Theme.of(context).textTheme.*` directly rather than a parallel typography
/// system. The one style worth naming here is the build console log, which
/// the old app explicitly set to monospaced
/// (`BuildLogView.swift`: `.font(.system(.caption, design: .monospaced))`)
/// for column-aligned log output.
class AppTypography {
  const AppTypography._();

  static const buildLog = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.4,
  );
}
