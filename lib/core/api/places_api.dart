import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/places/place_models.dart';

class PlacesApi {
  const PlacesApi(this._client);

  final HttpApiClient _client;

  Future<List<PlacePrediction>> searchPlaces({
    required String token,
    required String query,
  }) async {
    final json = await _client.sendJson(
      'GET',
      '/places/search?q=${Uri.encodeComponent(query)}',
      token: token,
    );
    return (json as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PlacePrediction.fromJson)
        .toList();
  }

  /// Resuelve un lugar de Google a nuestro registro canónico + detalles temporales.
  Future<PlaceResolveResult> resolvePlace({
    required String token,
    required String googlePlaceId,
    String? sessionToken,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/places/resolve',
      token: token,
      body: {'googlePlaceId': googlePlaceId, 'sessionToken': ?sessionToken},
    );
    return PlaceResolveResult.fromJson(json as Map<String, dynamic>);
  }

  Future<Place> createOwnPlace({
    required String token,
    required String name,
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/places',
      token: token,
      body: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'city': ?city,
      },
    );
    return Place.fromJson(json as Map<String, dynamic>);
  }

  /// Intenta resolver un enlace. Si es de Google Maps devuelve el lugar resuelto;
  /// si no, regresa la red detectada y la URL para el flujo manual.
  Future<ResolveLinkResult> resolveLink({
    required String token,
    required String url,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/places/resolve-link',
      token: token,
      body: {'url': url},
    );
    return ResolveLinkResult.fromJson(json as Map<String, dynamic>);
  }
}
