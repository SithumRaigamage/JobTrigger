import 'package:flutter/material.dart';

/// AUD-63: the backend could not decrypt a credential's secret, so the
/// credential is still listed (one unreadable secret must not fail the
/// whole list) but it can't authenticate until the user types the secret
/// again. It must not silently look like a working credential either.
///
/// [leading] is optional text shown before the notice on the same line —
/// the server URL in a settings tile, for instance. [detail] is an
/// optional second line explaining what to do, used where there's room
/// for it (the edit sheets) and left out where there isn't (the tiles).
class SecretReentryNotice extends StatelessWidget {
  const SecretReentryNotice({super.key, this.leading, this.detail, this.style});

  final String? leading;
  final String? detail;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = style ?? DefaultTextStyle.of(context).style;
    const label = 'Secret needs re-entering';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: leading == null ? '' : '$leading · ',
            style: base,
            children: [
              TextSpan(
                text: label,
                style: base.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
