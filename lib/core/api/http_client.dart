import 'dart:convert';

import 'package:http/http.dart' as http;

/// Excepción centralizada para errores del API.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP base. Maneja headers, serialización y extracción de errores.
/// Los clientes de dominio reciben este objeto por constructor.
class HttpApiClient {
  HttpApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  String get baseUrl => _baseUrl;

  Future<dynamic> sendJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final text = response.body.trim();
    final decoded = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode == 401) {
      throw const ApiException(
        'La sesión expiró. Vuelve a iniciar sesión.',
        statusCode: 401,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractError(decoded) ?? 'No se pudo completar la solicitud.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  static String? _extractError(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final title = decoded['title'];
      if (title is String && title.isNotEmpty) return title;
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
