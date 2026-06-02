import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/shared/models/list_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listsProvider = AsyncNotifierProvider<ListsNotifier, List<PlaceList>>(
  ListsNotifier.new,
);

// En Riverpod 3, family recibe el arg en el constructor del Notifier.
final listDetailProvider =
    AsyncNotifierProvider.family<ListDetailNotifier, ListDetail, String>(
      (String id) => ListDetailNotifier(id),
    );

class ListsNotifier extends AsyncNotifier<List<PlaceList>> {
  @override
  Future<List<PlaceList>> build() async {
    final token = _token;
    if (token == null) return [];
    return ref.read(listsApiProvider).getLists(token);
  }

  Future<void> createList({
    required String name,
    String? groupId,
    String visibility = 'private',
  }) async {
    final token = _token;
    if (token == null) return;

    final list = await ref
        .read(listsApiProvider)
        .createList(
          token: token,
          name: name,
          groupId: groupId,
          visibility: groupId != null ? 'group' : visibility,
        );

    state = AsyncData([list, ...?state.asData?.value]);
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;
}

class ListDetailNotifier extends AsyncNotifier<ListDetail> {
  ListDetailNotifier(this._listId);

  final String _listId;

  @override
  Future<ListDetail> build() async {
    final token = ref.read(authControllerProvider).asData?.value.token;
    if (token == null) throw const ApiException('Sin sesión activa.');
    return ref.read(listsApiProvider).getList(token, _listId);
  }

  Future<void> removeItem(String saveId) async {
    final token = ref.read(authControllerProvider).asData?.value.token;
    if (token == null) return;

    await ref
        .read(listsApiProvider)
        .removeItem(token: token, listId: _listId, saveId: saveId);

    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      ListDetail(
        id: current.id,
        name: current.name,
        groupId: current.groupId,
        visibility: current.visibility,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
        items: current.items.where((i) => i.save.id != saveId).toList(),
      ),
    );
  }
}
