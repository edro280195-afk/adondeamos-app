import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/features/lists/lists_controller.dart';
import 'package:adondeamos/shared/models/list_models.dart';
import 'package:adondeamos/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(listDetailProvider(listId));

    return detail.when(
      data: (list) => _ListDetailBody(list: list),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Lista')),
        body: Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ),
    );
  }
}

class _ListDetailBody extends ConsumerWidget {
  const _ListDetailBody({required this.list});

  final ListDetail list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: list.items.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.playlist_add_rounded,
                title: 'Lista vacía',
                message: 'Agrega lugares desde tus guardados pendientes.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: list.items.length,
              itemBuilder: (_, index) {
                final item = list.items[index];
                final save = item.save;
                final name = save.place.displayName;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < list.items.length - 1 ? 10 : 0,
                  ),
                  child: Dismissible(
                    key: ValueKey(save.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quitar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      HapticFeedback.mediumImpact();
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Quitar lugar'),
                              content: const Text(
                                '¿Quitar este lugar de la lista?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Quitar'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) {
                      ref
                          .read(listDetailProvider(list.id).notifier)
                          .removeItem(save.id);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.violetSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.position}',
                            style: const TextStyle(
                              color: AppTheme.violet,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          save.place.city ?? 'Sin ciudad',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
