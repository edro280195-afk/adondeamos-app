import 'dart:typed_data';

import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/saves/save_models.dart';

class SavesApi {
  const SavesApi(this._client);

  final HttpApiClient _client;

  Future<List<PlaceSave>> getSaves({
    required String token,
    String? status,
  }) async {
    final query = status == null ? '' : '?status=$status';
    final json = await _client.sendJson('GET', '/saves$query', token: token);
    return (json as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PlaceSave.fromJson)
        .toList();
  }

  Future<PlaceSave> createSave({
    required String token,
    required String placeId,
    String sourceNetwork = 'manual',
    String? sourceUrl,
    String? thumbnailUrl,
    String? note,
    String visibility = 'private',
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/saves',
      token: token,
      body: {
        'placeId': placeId,
        'sourceNetwork': sourceNetwork,
        'sourceUrl': ?sourceUrl,
        'thumbnailUrl': ?thumbnailUrl,
        'note': ?note,
        'visibility': visibility,
      },
    );
    return PlaceSave.fromJson(json as Map<String, dynamic>);
  }

  Future<PlaceSave> updateSave({
    required String token,
    required String saveId,
    String? note,
    String? visibility,
    bool? visited,
  }) async {
    final json = await _client.sendJson(
      'PATCH',
      '/saves/$saveId',
      token: token,
      body: {'note': ?note, 'visibility': ?visibility, 'visited': ?visited},
    );
    return PlaceSave.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteSave({
    required String token,
    required String saveId,
  }) async {
    await _client.sendJson('DELETE', '/saves/$saveId', token: token);
  }

  /// Sube o reemplaza la foto de portada. Devuelve la nueva URL.
  Future<String> uploadPhoto({
    required String token,
    required String saveId,
    required Uint8List fileBytes,
    required String contentType,
    required String fileName,
  }) async {
    final json = await _client.sendMultipart(
      'POST',
      '/saves/$saveId/photo',
      fileBytes: fileBytes,
      contentType: contentType,
      fileName: fileName,
      token: token,
    );
    final map = json as Map<String, dynamic>;
    return map['thumbnailUrl'] as String;
  }

  /// Elimina la foto de portada del guardado.
  Future<void> deletePhoto({
    required String token,
    required String saveId,
  }) async {
    await _client.sendJson('DELETE', '/saves/$saveId/photo', token: token);
  }
}
