import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/features/lists/list_detail_screen.dart';
import 'package:adondeamos/features/lists/lists_controller.dart';
import 'package:adondeamos/shared/models/list_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(listsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis listas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateSheet(context, ref),
            tooltip: 'Nueva lista',
          ),
        ],
      ),
      body: lists.when(
        data: (items) => items.isEmpty
            ? _EmptyLists(onCreate: () => _showCreateSheet(context, ref))
            : _ListsGrid(lists: items),
        loading: () => const _ListsLoading(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.muted),
              const SizedBox(height: 12),
              Text(error.toString(), style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(listsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva lista'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    bool isGroup = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva lista',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la lista',
                    hintText: 'Ej. Sábado en la noche',
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '¿Lista grupal?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Visible para todos los miembros del grupo.'),
                  value: isGroup,
                  onChanged: (v) => setSheetState(() => isGroup = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      try {
                        await ref.read(listsProvider.notifier).createList(
                              name: name,
                              visibility: isGroup ? 'group' : 'private',
                            );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Crear lista'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListsLoading extends StatelessWidget {
  const _ListsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ShimmerCard(height: 72),
    );
  }
}

class _ListsGrid extends StatelessWidget {
  const _ListsGrid({required this.lists});

  final List<PlaceList> lists;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: lists.length,
      itemBuilder: (_, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < lists.length - 1 ? 10 : 0),
          child: _ListTile(list: lists[index]),
        );
      },
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.list});

  final PlaceList list;

  @override
  Widget build(BuildContext context) {
    final isGroup = list.groupId != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ListDetailScreen(listId: list.id),
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: isGroup ? const Color(0xFFEDF7F2) : AppTheme.violetSoft,
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.list_alt_rounded,
                color: isGroup ? AppTheme.green : AppTheme.violet,
              ),
            ),
            title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              isGroup ? 'Lista grupal' : 'Lista personal',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ),
        ),
      ),
    );
  }
}

class _EmptyLists extends StatelessWidget {
  const _EmptyLists({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt_rounded, size: 72, color: AppTheme.violetSoft),
            const SizedBox(height: 16),
            const Text(
              'Todavía no tienes listas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea listas para organizar tus lugares pendientes y compartirlos con tu grupo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear lista'),
            ),
          ],
        ),
      ),
    );
  }
}
