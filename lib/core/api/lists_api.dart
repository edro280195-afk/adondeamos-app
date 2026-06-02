import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/shared/models/list_models.dart';

class ListsApi {
  const ListsApi(this._client);

  final HttpApiClient _client;

  Future<List<PlaceList>> getLists(String token) async {
    final json = await _client.sendJson('GET', '/lists', token: token);
    return (json as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PlaceList.fromJson)
        .toList();
  }

  Future<ListDetail> getList(String token, String listId) async {
    final json = await _client.sendJson('GET', '/lists/$listId', token: token);
    return ListDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<PlaceList> createList({
    required String token,
    required String name,
    String? groupId,
    String visibility = 'private',
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/lists',
      token: token,
      body: {'name': name, 'groupId': ?groupId, 'visibility': visibility},
    );
    return PlaceList.fromJson(json as Map<String, dynamic>);
  }

  Future<void> addItem({
    required String token,
    required String listId,
    required String saveId,
  }) async {
    await _client.sendJson(
      'POST',
      '/lists/$listId/items',
      token: token,
      body: {'saveId': saveId},
    );
  }

  Future<void> removeItem({
    required String token,
    required String listId,
    required String saveId,
  }) async {
    await _client.sendJson(
      'DELETE',
      '/lists/$listId/items/$saveId',
      token: token,
    );
  }
}
