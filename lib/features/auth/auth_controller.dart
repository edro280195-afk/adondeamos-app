import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({required this.token, required this.user});

  const AuthState.signedOut() : this(token: null, user: null);

  final String? token;
  final AppUser? user;

  bool get isSignedIn => token != null && user != null;
}

class AuthController extends AsyncNotifier<AuthState> {
  static const _tokenKey = 'adondeamos_access_token';
  static const _usernameKey = 'adondeamos_username';
  static const _passwordKey = 'adondeamos_password';

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  @override
  Future<AuthState> build() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return const AuthState.signedOut();
    }

    try {
      final user = await ref.read(authApiProvider).me(token);
      return AuthState(token: token, user: user);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _secureStorage.delete(key: _tokenKey);
      }
      return const AuthState.signedOut();
    }
  }

  Future<bool> checkBiometricsAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  Future<bool> hasSavedCredentials() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return username != null && password != null;
  }

  Future<bool> loginWithBiometrics() async {
    final canAuth = await checkBiometricsAvailable();
    if (!canAuth) return false;

    final hasCreds = await hasSavedCredentials();
    if (!hasCreds) return false;

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión en Adondeamos',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        final username = await _secureStorage.read(key: _usernameKey);
        final password = await _secureStorage.read(key: _passwordKey);
        if (username != null && password != null) {
          await login(username: username, password: password);
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref
          .read(authApiProvider)
          .login(username: username, password: password);
      await _saveCredentials(response.accessToken, username, password);
      return AuthState(token: response.accessToken, user: response.user);
    });
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref
          .read(authApiProvider)
          .register(
            name: name,
            username: username,
            email: email,
            password: password,
          );
      await _saveCredentials(response.accessToken, username, password);
      return AuthState(token: response.accessToken, user: response.user);
    });
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    state = const AsyncData(AuthState.signedOut());
  }

  Future<void> _saveCredentials(
    String token,
    String username,
    String password,
  ) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
  }
}
