import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/error_message.dart';
import '../../data/credentials/credentials_notifier.dart';
import 'connection_error_view.dart';
import 'no_active_server_view.dart';

/// What a Jenkins screen shows while there's no active server yet. The
/// active server only exists once the saved-server list has loaded from the
/// backend, so "no server" isn't always the truth: while that load runs it's
/// a spinner, if it fails it's the error with a retry, and only an empty
/// list means [NoActiveServerView].
class ActiveServerGate extends ConsumerWidget {
  const ActiveServerGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(credentialsNotifierProvider)
        .when(
          // A saved server exists but isn't active yet: it's being picked.
          data: (servers) => servers.isEmpty
              ? const NoActiveServerView()
              : const CircularProgressIndicator(),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => ConnectionErrorView(
            message: describeError(error),
            onRetry: () =>
                ref.read(credentialsNotifierProvider.notifier).refresh(),
          ),
        );
  }
}
