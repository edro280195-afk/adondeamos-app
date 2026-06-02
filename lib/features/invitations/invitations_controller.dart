import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/shared/models/invitation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invitationsProvider =
    AsyncNotifierProvider<InvitationsNotifier, List<Invitation>>(
      InvitationsNotifier.new,
    );

class InvitationsNotifier extends AsyncNotifier<List<Invitation>> {
  @override
  Future<List<Invitation>> build() async {
    final token = _token;
    if (token == null) return [];
    return ref.read(invitationsApiProvider).getMyInvitations(token);
  }

  Future<void> accept(String invitationId) async {
    final token = _token;
    if (token == null) return;

    final updated = await ref
        .read(invitationsApiProvider)
        .acceptInvitation(token: token, invitationId: invitationId);

    _replace(updated);
  }

  Future<void> reject(String invitationId) async {
    final token = _token;
    if (token == null) return;

    final updated = await ref
        .read(invitationsApiProvider)
        .rejectInvitation(token: token, invitationId: invitationId);

    _replace(updated);
  }

  void _replace(Invitation updated) {
    state = AsyncData(
      state.asData?.value
              .map((i) => i.id == updated.id ? updated : i)
              .toList() ??
          [],
    );
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;
}
