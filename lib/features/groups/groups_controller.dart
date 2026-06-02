import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/shared/models/group_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupsProvider = AsyncNotifierProvider<GroupsNotifier, List<Group>>(
  GroupsNotifier.new,
);

// En Riverpod 3, family recibe el arg en el constructor del Notifier.
final groupDetailProvider =
    AsyncNotifierProvider.family<GroupDetailNotifier, GroupDetail, String>(
      (String id) => GroupDetailNotifier(id),
    );

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    final token = _token;
    if (token == null) return [];
    return ref.read(groupsApiProvider).getGroups(token);
  }

  Future<void> createGroup(String name) async {
    final token = _token;
    if (token == null) return;

    final detail = await ref
        .read(groupsApiProvider)
        .createGroup(token: token, name: name);

    final group = Group(
      id: detail.id,
      name: detail.name,
      role: 'owner',
      createdAt: detail.createdAt,
    );

    state = AsyncData([group, ...?state.asData?.value]);
  }

  Future<void> inviteMember({
    required String groupId,
    required String email,
  }) async {
    final token = _token;
    if (token == null) return;
    await ref
        .read(invitationsApiProvider)
        .invite(token: token, groupId: groupId, email: email);
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;
}

class GroupDetailNotifier extends AsyncNotifier<GroupDetail> {
  GroupDetailNotifier(this._groupId);

  final String _groupId;

  @override
  Future<GroupDetail> build() async {
    final token = ref.read(authControllerProvider).asData?.value.token;
    if (token == null) throw const ApiException('Sin sesión activa.');
    return ref.read(groupsApiProvider).getGroup(token, _groupId);
  }
}
