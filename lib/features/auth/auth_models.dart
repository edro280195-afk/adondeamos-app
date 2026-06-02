import 'package:adondeamos/core/api/json_helpers.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: safeStr(json['id']),
      name: safeStr(json['name']),
      username: safeStr(json['username']),
      email: safeStr(json['email']),
      avatarUrl: safeStrOrNull(json['avatarUrl']),
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: safeStr(json['accessToken']),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
