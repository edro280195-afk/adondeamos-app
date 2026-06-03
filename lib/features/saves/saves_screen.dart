import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/features/saves/save_models.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:adondeamos/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavesScreen extends ConsumerStatefulWidget {
  const SavesScreen({super.key});

  @override
  ConsumerState<SavesScreen> createState() => _SavesScreenState();
}

class _SavesScreenState extends ConsumerState<SavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis lugares'),
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => _onTabChanged(),
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Visitados'),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: TabBarView(
          key: ValueKey(_tabs.index),
          controller: _tabs,
          children: const [
            _SavesTab(status: 'pending'),
            _SavesTab(status: 'visited'),
          ],
        ),
      ),
    );
  }
}

class _SavesTab extends ConsumerWidget {
  const _SavesTab({required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = status == 'pending'
        ? pendingSavesProvider
        : visitedSavesProvider;
    final saves = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: saves.when(
        data: (items) => _SavesList(items: items, status: status),
        loading: () => const _SavesLoading(),
        error: (error, _) => _ErrorState(message: error.toString()),
      ),
    );
  }
}

class _SavesLoading extends StatelessWidget {
  const _SavesLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const ShimmerCard(height: 86),
    );
  }
}

class _SavesList extends ConsumerWidget {
  const _SavesList({required this.items, required this.status});

  final List<PlaceSave> items;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      if (status == 'pending') {
        return const EmptyState(
          icon: Icons.bookmark_add_outlined,
          title: 'Todavía no tienes lugares pendientes',
          message:
              'Usa el botón central para guardar el primer lugar que viste en TikTok, WhatsApp o Google Maps.',
        );
      }
      return const EmptyState(
        icon: Icons.place_outlined,
        title: 'Aún no has visitado ningún lugar',
        message: 'Cuando marques un lugar como visitado aparecerá aquí.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final save = items[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < items.length - 1 ? 10 : 0),
          child: _SwipeableSaveTile(save: save, isPending: status == 'pending'),
        );
      },
    );
  }
}

class _SwipeableSaveTile extends ConsumerWidget {
  const _SwipeableSaveTile({required this.save, required this.isPending});

  final PlaceSave save;
  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
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
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'Eliminar',
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
                title: const Text('Eliminar guardado'),
                content: const Text(
                  '¿Seguro que quieres eliminar este lugar? No se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        final provider = isPending
            ? pendingSavesProvider
            : visitedSavesProvider;
        try {
          await ref.read(provider.notifier).deleteSave(save.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SaveDetailScreen(save: save)),
            );
          },
          child: _SaveTile(save: save, isPending: isPending),
        ),
      ),
    );
  }
}

class _SaveTile extends StatelessWidget {
  const _SaveTile({required this.save, required this.isPending});

  final PlaceSave save;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final placeName = save.place.displayName;
    final city = save.place.city;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _networkIcon(save.sourceNetwork),
                color: AppTheme.violet,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (city != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      city,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _NetworkChip(network: save.sourceNetwork),
                      if (save.note != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            save.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isPending ? Icons.bookmark_rounded : Icons.check_circle_rounded,
              color: isPending ? AppTheme.violet : AppTheme.green,
            ),
          ],
        ),
      ),
    );
  }

  IconData _networkIcon(String network) => switch (network) {
    'tiktok' => Icons.music_note_rounded,
    'instagram' => Icons.camera_alt_rounded,
    'facebook' => Icons.facebook_rounded,
    'whatsapp' => Icons.chat_rounded,
    'googleMaps' => Icons.map_rounded,
    'youtube' => Icons.play_circle_rounded,
    _ => Icons.place_rounded,
  };
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.network});

  final String network;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.violetSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          _label,
          style: const TextStyle(
            color: AppTheme.violet,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String get _label => switch (network) {
    'tiktok' => 'TikTok',
    'instagram' => 'Instagram',
    'facebook' => 'Facebook',
    'whatsapp' => 'WhatsApp',
    'googleMaps' => 'Google Maps',
    'youtube' => 'YouTube',
    _ => 'Manual',
  };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pude cargar tus guardados',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Pantalla de detalle
// ──────────────────────────────────────────────────────────────────────────────

class SaveDetailScreen extends ConsumerWidget {
  const SaveDetailScreen({super.key, required this.save});

  final PlaceSave save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeName = save.place.displayName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.deepBrandGradient),
                child: const Center(
                  child: Icon(
                    Icons.place_rounded,
                    size: 72,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (save.place.city != null)
                    Text(
                      save.place.city!,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  const SizedBox(height: 18),
                  if (save.isPending)
                    FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        try {
                          await ref
                              .read(pendingSavesProvider.notifier)
                              .markVisited(save.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Marcado como visitado!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Marcar como visitado'),
                    )
                  else
                    FilledButton.tonalIcon(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Ya visitado'),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Información',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (save.note != null)
                    Text(save.note!, style: const TextStyle(height: 1.45))
                  else
                    const Text(
                      'Sin nota.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  const SizedBox(height: 16),
                  if (save.sourceUrl != null)
                    _InfoLine(icon: Icons.link_rounded, text: save.sourceUrl!),
                  _InfoLine(
                    icon: Icons.category_rounded,
                    text: _networkLabel(save.sourceNetwork),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _networkLabel(String network) => switch (network) {
    'tiktok' => 'Guardado desde TikTok',
    'instagram' => 'Guardado desde Instagram',
    'facebook' => 'Guardado desde Facebook',
    'whatsapp' => 'Compartido por WhatsApp',
    'googleMaps' => 'Encontrado en Google Maps',
    'youtube' => 'Visto en YouTube',
    _ => 'Guardado manualmente',
  };
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.ink)),
          ),
        ],
      ),
    );
  }
}
