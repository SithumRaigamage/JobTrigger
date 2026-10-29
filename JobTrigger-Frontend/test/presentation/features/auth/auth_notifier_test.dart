import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('build returns Unauthenticated when no session is stored', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(authNotifierProvider.future);

    expect(state, isA<Unauthenticated>());
  });

  test(
    'setSession persists the token, caches the user, and flips to Authenticated',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt-abc');

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.email, 'a@b.com');

      final storage = SecureStorageService(const FlutterSecureStorage());
      expect(await storage.readToken(), 'jwt-abc');
    },
  );

  test(
    'logout clears the stored session and flips to Unauthenticated',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt-abc');

      await container.read(authNotifierProvider.notifier).logout();

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<Unauthenticated>());
      final storage = SecureStorageService(const FlutterSecureStorage());
      expect(await storage.readToken(), isNull);
    },
  );

  test(
    'a fresh container rehydrates Authenticated state from a prior session',
    () async {
      final firstContainer = ProviderContainer();
      await firstContainer.read(authNotifierProvider.future);
      await firstContainer
          .read(authNotifierProvider.notifier)
          .setSession(
            const User(id: 'u2', email: 'existing@b.com'),
            'jwt-existing',
          );
      firstContainer.dispose();

      final secondContainer = ProviderContainer();
      addTearDown(secondContainer.dispose);

      final state = await secondContainer.read(authNotifierProvider.future);

      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.email, 'existing@b.com');
    },
  );

  // P19-01: "Remember me" decides whether the session outlives a restart.
  group('keepSignedIn across a restart', () {
    Future<AuthState?> restartAfterSession({bool? keepSignedIn}) async {
      final first = ProviderContainer();
      await first.read(authNotifierProvider.future);
      await first
          .read(authNotifierProvider.notifier)
          .setSession(
            const User(id: 'u3', email: 'c@b.com'),
            'jwt-3',
            refreshToken: 'refresh-3',
            keepSignedIn: keepSignedIn,
          );
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      return second.read(authNotifierProvider.future);
    }

    test('true keeps the session', () async {
      expect(
        await restartAfterSession(keepSignedIn: true),
        isA<Authenticated>(),
      );
    });

    test('false discards the session and its tokens', () async {
      expect(
        await restartAfterSession(keepSignedIn: false),
        isA<Unauthenticated>(),
      );
      final storage = SecureStorageService(const FlutterSecureStorage());
      expect(await storage.readToken(), isNull);
    });

    test('unset keeps the session (sessions from before the flag)', () async {
      expect(await restartAfterSession(), isA<Authenticated>());
    });

    test('a later setSession without a choice leaves it alone', () async {
      final first = ProviderContainer();
      await first.read(authNotifierProvider.future);
      final notifier = first.read(authNotifierProvider.notifier);
      const user = User(id: 'u4', email: 'd@b.com');
      await notifier.setSession(user, 'jwt-a', keepSignedIn: false);
      // What changePassword does: a fresh token, no stated choice.
      await notifier.setSession(user, 'jwt-b');
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(
        await second.read(authNotifierProvider.future),
        isA<Unauthenticated>(),
      );
    });

    test('logout forgets the choice', () async {
      final first = ProviderContainer();
      await first.read(authNotifierProvider.future);
      final notifier = first.read(authNotifierProvider.notifier);
      const user = User(id: 'u5', email: 'e@b.com');
      await notifier.setSession(user, 'jwt-a', keepSignedIn: false);
      await notifier.logout();
      await notifier.setSession(user, 'jwt-b');
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(
        await second.read(authNotifierProvider.future),
        isA<Authenticated>(),
      );
    });
  });
}
