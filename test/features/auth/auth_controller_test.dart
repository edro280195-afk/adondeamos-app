import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/auth_api.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/auth/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthApi extends Mock implements AuthApi {}

void main() {
  late MockAuthApi mockAuthApi;
  late ProviderContainer container;

  setUp(() {
    mockAuthApi = MockAuthApi();
    FlutterSecureStorage.setMockInitialValues({});

    container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(mockAuthApi)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController', () {
    test('initial state is signedOut when no token exists', () async {
      final state = await container.read(authControllerProvider.future);
      expect(state.isSignedIn, isFalse);
      expect(state.token, isNull);
      expect(state.user, isNull);
    });

    test('login sets token and user on success', () async {
      const tUser = AppUser(
        id: '1',
        name: 'Test',
        username: 'testuser',
        email: 'test@example.com',
      );
      const tResponse = AuthResponse(accessToken: 'token123', user: tUser);

      when(
        () => mockAuthApi.login(username: 'testuser', password: 'password'),
      ).thenAnswer((_) async => tResponse);

      await container
          .read(authControllerProvider.notifier)
          .login(username: 'testuser', password: 'password');

      final state = container.read(authControllerProvider).value;
      expect(state?.isSignedIn, isTrue);
      expect(state?.token, 'token123');
      expect(state?.user?.name, 'Test');

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'adondeamos_access_token'), 'token123');
    });

    test('logout clears token and state', () async {
      FlutterSecureStorage.setMockInitialValues({
        'adondeamos_access_token': 'token123',
      });

      when(() => mockAuthApi.me('token123')).thenAnswer(
        (_) async => const AppUser(
          id: '1',
          name: 'Test',
          username: 'testuser',
          email: 't@t.com',
        ),
      );

      await container.read(authControllerProvider.future); // Initialize

      await container.read(authControllerProvider.notifier).logout();

      final state = container.read(authControllerProvider).value;
      expect(state?.isSignedIn, isFalse);

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'adondeamos_access_token'), isNull);
    });
  });
}
