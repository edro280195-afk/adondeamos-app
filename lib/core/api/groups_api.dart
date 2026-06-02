import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/shared/models/group_models.dart';

class GroupsApi {
  const GroupsApi(this._client);

  final HttpApiClient _client;

  Future<List<Group>> getGroups(String token) async {
    final json = await _client.sendJson('GET', '/groups', token: token);
    return (json as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Group.fromJson)
        .toList();
  }

  Future<GroupDetail> getGroup(String token, String groupId) async {
    final json = await _client.sendJson(
      'GET',
      '/groups/$groupId',
      token: token,
    );
    return GroupDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<GroupDetail> createGroup({
    required String token,
    required String name,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/groups',
      token: token,
      body: {'name': name},
    );
    return GroupDetail.fromJson(json as Map<String, dynamic>);
  }
}
