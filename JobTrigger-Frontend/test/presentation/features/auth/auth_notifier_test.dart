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
}
