import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/shared/models/invitation_models.dart';

class InvitationsApi {
  const InvitationsApi(this._client);

  final HttpApiClient _client;

  Future<Invitation> invite({
    required String token,
    required String groupId,
    String? email,
    String? userId,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/groups/$groupId/invitations',
      token: token,
      body: {'email': ?email, 'userId': ?userId},
    );
    return Invitation.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Invitation>> getMyInvitations(String token) async {
    final json = await _client.sendJson('GET', '/me/invitations', token: token);
    return (json as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Invitation.fromJson)
        .toList();
  }

  Future<Invitation> acceptInvitation({
    required String token,
    required String invitationId,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/invitations/$invitationId/accept',
      token: token,
    );
    return Invitation.fromJson(json as Map<String, dynamic>);
  }

  Future<Invitation> rejectInvitation({
    required String token,
    required String invitationId,
  }) async {
    final json = await _client.sendJson(
      'POST',
      '/invitations/$invitationId/reject',
      token: token,
    );
    return Invitation.fromJson(json as Map<String, dynamic>);
  }
}
