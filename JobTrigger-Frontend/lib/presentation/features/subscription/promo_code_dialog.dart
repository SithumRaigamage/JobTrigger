import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlements_notifier.dart';
import 'promo_redeem_notifier.dart';

/// US-PROMO-01: asks for a promo or voucher code and redeems it.
///
/// Resolves `true` only on a successful redemption (the dialog then closes and
/// the screen shows the toast); a refusal stays in the dialog with the
/// backend's sentence, so the code can be corrected without starting again.
class PromoCodeDialog extends ConsumerStatefulWidget {
  const PromoCodeDialog({super.key});

  @override
  ConsumerState<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends ConsumerState<PromoCodeDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _problem;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    final outcome = await ref
        .read(promoRedeemProvider.notifier)
        .redeem(_controller.text);
    if (!mounted) return;
    switch (outcome) {
      case PromoRedeemed(:final snapshot):
        // The plan the code granted, straight away: the screen behind shows
        // Pro and its end date without a second request.
        ref.read(entitlementsNotifierProvider.notifier).apply(snapshot);
        Navigator.of(context).pop(true);
      case PromoRedeemRefused(:final message):
        setState(() {
          _busy = false;
          _problem = message;
        });
      case PromoRedeemFailed(:final failure):
        setState(() {
          _busy = false;
          _problem = failure.message;
        });
      case PromoRedeemBusy():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Redeem a code'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the promo or voucher code you were given. It adds '
                'JobTrigger Pro from the moment you redeem it.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('promo_code_field'),
                controller: _controller,
                autofocus: true,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'LAUNCH30',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              if (_problem case final problem?)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    problem,
                    key: const Key('promo_code_problem'),
                    style: textTheme.bodyMedium?.copyWith(color: colors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const Key('promo_redeem_submit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: _canSubmit ? _submit : null,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Redeem'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
