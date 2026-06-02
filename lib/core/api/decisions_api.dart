import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/shared/models/decision_models.dart';

class DecisionsApi {
  const DecisionsApi(this._client);

  final HttpApiClient _client;

  Future<Decision> createDecision({
    required String token,
    String? groupId,
    String? context,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/decisions',
      token: token,
      body: {'groupId': ?groupId, 'context': ?context},
    );
    return Decision.fromJson(json as Map<String, dynamic>);
  }

  Future<Decision> addOptions({
    required String token,
    required String decisionId,
    List<String>? placeIds,
    bool autoFillFromSaves = false,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/decisions/$decisionId/options',
      token: token,
      body: {'placeIds': ?placeIds, 'autoFillFromSaves': autoFillFromSaves},
    );
    return Decision.fromJson(json as Map<String, dynamic>);
  }

  Future<Decision> castVote({
    required String token,
    required String decisionId,
    required String optionId,
    required bool isYes,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/decisions/$decisionId/options/$optionId/votes',
      token: token,
      body: {'isYes': isYes},
    );
    return Decision.fromJson(json as Map<String, dynamic>);
  }

  Future<Decision> getDecision({
    required String token,
    required String decisionId,
  }) async {
    final json = await _client.sendJson(
      'GET',
      '/decisions/$decisionId',
      token: token,
    );
    return Decision.fromJson(json as Map<String, dynamic>);
  }
}
