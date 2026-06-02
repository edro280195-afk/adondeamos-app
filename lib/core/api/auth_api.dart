import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_models.dart';

class AuthApi {
  const AuthApi(this._client);

  final HttpApiClient _client;

  Future<AuthResponse> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/auth/login',
      body: {'username': username, 'password': password},
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AppUser> me(String token) async {
    final json = await _client.sendJson('GET', '/me', token: token);
    return AppUser.fromJson(json as Map<String, dynamic>);
  }
}
