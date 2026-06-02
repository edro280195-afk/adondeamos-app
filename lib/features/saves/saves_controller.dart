import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/saves/save_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers por status
final pendingSavesProvider =
    AsyncNotifierProvider<SavesNotifier, List<PlaceSave>>(
      () => SavesNotifier(status: 'pending'),
    );

final visitedSavesProvider =
    AsyncNotifierProvider<SavesNotifier, List<PlaceSave>>(
      () => SavesNotifier(status: 'visited'),
    );

class SavesNotifier extends AsyncNotifier<List<PlaceSave>> {
  SavesNotifier({required this.status});

  final String status;

  @override
  Future<List<PlaceSave>> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    final token = auth.token;
    if (token == null) return [];
    return ref.read(savesApiProvider).getSaves(token: token, status: status);
  }

  Future<void> markVisited(String saveId) async {
    final token = _token;
    if (token == null) return;

    final updated = await ref
        .read(savesApiProvider)
        .updateSave(token: token, saveId: saveId, visited: true);

    state = AsyncData(
      state.asData?.value.map((s) => s.id == saveId ? updated : s).toList() ??
          [],
    );

    ref.invalidate(visitedSavesProvider);
  }

  Future<void> deleteSave(String saveId) async {
    final token = _token;
    if (token == null) return;

    await ref.read(savesApiProvider).deleteSave(token: token, saveId: saveId);

    state = AsyncData(
      state.asData?.value.where((s) => s.id != saveId).toList() ?? [],
    );
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;
}
