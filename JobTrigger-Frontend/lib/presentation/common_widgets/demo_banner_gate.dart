import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/demo/demo_mode_notifier.dart';
import '../features/auth/auth_notifier.dart';

/// E2 (PE-12): the persistent "Demo" strip above the whole app while demo
/// mode is on, with "Exit demo". The strip's slot is always in the tree
/// (empty when off), so turning demo mode on or off never rebuilds the
/// navigator below it.
class DemoBannerGate extends ConsumerWidget {
  const DemoBannerGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoModeNotifierProvider);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (demo)
          Material(
            key: const Key('demo_banner'),
            color: colors.tertiaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo: sample data, nothing here is real',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('demo_exit_button'),
                      onPressed: () => unawaited(
                        ref.read(authNotifierProvider.notifier).exitDemo(),
                      ),
                      child: const Text('Exit demo'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: demo,
            child: child,
          ),
        ),
      ],
    );
  }
}
