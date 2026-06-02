import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/saves_api.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/auth/auth_models.dart';
import 'package:adondeamos/features/places/place_models.dart';
import 'package:adondeamos/features/saves/save_models.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSavesApi extends Mock implements SavesApi {}

void main() {
  late MockSavesApi mockSavesApi;
  late ProviderContainer container;

  final tPlace = Place(id: 'p1', origin: 'google', name: 'Test Place');

  final tSave = PlaceSave(
    id: '1',
    place: tPlace,
    sourceNetwork: 'manual',
    visibility: 'private',
    status: 'pending',
    createdAt: '2023-10-10',
    updatedAt: '2023-10-10',
  );

  setUp(() {
    mockSavesApi = MockSavesApi();
    FlutterSecureStorage.setMockInitialValues({
      'adondeamos_access_token': 'token123',
    });

    container = ProviderContainer(
      overrides: [
        savesApiProvider.overrideWithValue(mockSavesApi),
        // Mock AuthState para el token
        authControllerProvider.overrideWith(() => _MockAuthController()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SavesNotifier', () {
    test('fetches pending saves successfully', () async {
      when(
        () => mockSavesApi.getSaves(token: 'token123', status: 'pending'),
      ).thenAnswer((_) async => [tSave]);

      final saves = await container.read(pendingSavesProvider.future);
      expect(saves, isNotEmpty);
      expect(saves.first.id, '1');
    });

    test('deleteSave removes item from state', () async {
      when(
        () => mockSavesApi.getSaves(token: 'token123', status: 'pending'),
      ).thenAnswer((_) async => [tSave]);
      when(
        () => mockSavesApi.deleteSave(token: 'token123', saveId: '1'),
      ).thenAnswer((_) async => {});

      await container.read(pendingSavesProvider.future); // load initial

      await container.read(pendingSavesProvider.notifier).deleteSave('1');

      final saves = container.read(pendingSavesProvider).value;
      expect(saves, isEmpty);
      verify(
        () => mockSavesApi.deleteSave(token: 'token123', saveId: '1'),
      ).called(1);
    });
  });
}

class _MockAuthController extends AuthController {
  @override
  Future<AuthState> build() async {
    return const AuthState(
      token: 'token123',
      user: AppUser(
        id: '1',
        name: 'Test',
        username: 'testuser',
        email: 't@t.com',
      ),
    );
  }
}
