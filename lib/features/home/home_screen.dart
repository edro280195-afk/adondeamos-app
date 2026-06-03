import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/decisions/decisions_controller.dart';
import 'package:adondeamos/features/decisions/decisions_screen.dart';
import 'package:adondeamos/features/saves/save_models.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:adondeamos/features/saves/saves_screen.dart';
import 'package:adondeamos/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value.user;
    final firstName = user?.name.split(' ').first ?? '';
    final pendingSaves = ref.watch(pendingSavesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingSavesProvider);
            await ref.read(pendingSavesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              AnimatedListItem(
                index: 0,
                delayMs: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isNotEmpty
                                ? '¡Hola, $firstName! 👋'
                                : '¡Hola! 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '¿A dónde vamos hoy?',
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedListItem(
                index: 1,
                child: pendingSaves.when(
                  data: (saves) => _PendingSummary(count: saves.length),
                  loading: () => const _PendingSummaryLoading(),
                  error: (_, _) => const _ApiOfflineBanner(),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedListItem(
                index: 2,
                child: pendingSaves.when(
                  data: (saves) =>
                      _DecisionHomeCard(pendingCount: saves.length),
                  loading: () => const _DecisionHomeCard(pendingCount: null),
                  error: (_, _) => const _DecisionHomeCard(pendingCount: null),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedListItem(
                index: 3,
                child: const SectionHeader(title: 'Últimos guardados'),
              ),
              pendingSaves.when(
                data: (saves) {
                  if (saves.isEmpty) {
                    return AnimatedListItem(
                      index: 4,
                      child: const _EmptyCallToAction(),
                    );
                  }
                  final recent = saves.take(3).toList();
                  return Column(
                    children: List.generate(recent.length, (i) {
                      final save = recent[i];
                      return AnimatedListItem(
                        index: i + 4,
                        child: _RecentSaveTile(save: save),
                      );
                    }),
                  );
                },
                loading: () => const _RecentSavesLoading(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSummary extends StatelessWidget {
  const _PendingSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.deepBrandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.bookmark_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0
                        ? 'Sin lugares pendientes'
                        : '$count ${count == 1 ? 'lugar pendiente' : 'lugares pendientes'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 0
                        ? 'Guarda el primero desde TikTok, Maps o Instagram.'
                        : 'Lugares que guardaste y aún no has visitado.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSummaryLoading extends StatelessWidget {
  const _PendingSummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(height: 92, borderRadius: 24);
  }
}

class _DecisionHomeCard extends ConsumerStatefulWidget {
  const _DecisionHomeCard({required this.pendingCount});

  final int? pendingCount;

  @override
  ConsumerState<_DecisionHomeCard> createState() => _DecisionHomeCardState();
}

class _DecisionHomeCardState extends ConsumerState<_DecisionHomeCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.pendingCount;
    final subtitle = switch (pendingCount) {
      null => 'Creo una sesión y cargo tus lugares pendientes.',
      0 => 'Guarda lugares pendientes para llenarla automáticamente.',
      1 => 'Uso tu lugar pendiente como opción para votar.',
      _ => 'Uso tus $pendingCount lugares pendientes como opciones.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _loading ? null : _startDecision,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppTheme.deepBrandGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.how_to_vote_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿A dónde vamos?',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.electricSapphire,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startDecision() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      final ops = ref.read(decisionOpsProvider);
      final decision = await ops.createDecision(context: 'Inicio');

      if (widget.pendingCount != 0) {
        try {
          await ops.addFromSaves(decision.id);
        } on ApiException catch (error) {
          if (mounted && (widget.pendingCount ?? 0) > 0) {
            _showMessage(error.message);
          }
        }
      }

      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DecisionsScreen()));
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ApiOfflineBanner extends StatelessWidget {
  const _ApiOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Color(0xFF8A5B00)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No pude conectar con el servidor. Revisa tu conexión.',
                style: TextStyle(
                  color: Color(0xFF8A5B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCallToAction extends StatelessWidget {
  const _EmptyCallToAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.add_location_alt_rounded,
            size: 56,
            color: AppTheme.violetSoft,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aún no tienes lugares guardados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toca el botón central para guardar\ntu primer lugar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _RecentSaveTile extends StatelessWidget {
  const _RecentSaveTile({required this.save});

  final PlaceSave save;

  @override
  Widget build(BuildContext context) {
    final name = save.place.displayName;
    final city = save.place.city ?? '';
    final network = save.sourceNetwork;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaveDetailScreen(save: save),
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: _SaveLeading(save: save),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            subtitle: Text(
              city.isNotEmpty
                  ? '$city · ${_networkLabel(network)}'
                  : _networkLabel(network),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }

  String _networkLabel(String n) => switch (n) {
    'tiktok' => 'TikTok',
    'instagram' => 'Instagram',
    'facebook' => 'Facebook',
    'whatsapp' => 'WhatsApp',
    'googleMaps' => 'Google Maps',
    'youtube' => 'YouTube',
    _ => 'Manual',
  };
}

class _SaveLeading extends StatelessWidget {
  const _SaveLeading({required this.save});

  final PlaceSave save;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = save.thumbnailUrl;
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          thumbUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _networkIcon(save.sourceNetwork),
        ),
      );
    }
    return _networkIcon(save.sourceNetwork);
  }

  Widget _networkIcon(String n) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.violetSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _icon(n),
        color: AppTheme.violet,
        size: 22,
      ),
    );
  }

  IconData _icon(String n) => switch (n) {
    'tiktok' => Icons.music_note_rounded,
    'instagram' => Icons.camera_alt_rounded,
    'whatsapp' => Icons.chat_rounded,
    'googleMaps' => Icons.map_rounded,
    'youtube' => Icons.play_circle_rounded,
    _ => Icons.place_rounded,
  };
}

class _RecentSavesLoading extends StatelessWidget {
  const _RecentSavesLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerCard(height: 64),
        );
      }),
    );
  }
}
