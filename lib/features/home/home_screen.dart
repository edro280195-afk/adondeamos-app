import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:adondeamos/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
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
              const SizedBox(height: 24),
              AnimatedListItem(
                index: 2,
                child: const SectionHeader(title: 'Últimos guardados'),
              ),
              pendingSaves.when(
                data: (saves) {
                  if (saves.isEmpty) {
                    return AnimatedListItem(
                      index: 3,
                      child: const _EmptyCallToAction(),
                    );
                  }
                  final recent = saves.take(3).toList();
                  return Column(
                    children: List.generate(recent.length, (i) {
                      final save = recent[i];
                      final name =
                          save.place.name ??
                          save.place.googlePlaceId?.substring(0, 10) ??
                          'Lugar de Google';
                      final city = save.place.city ?? '';
                      return AnimatedListItem(
                        index: i + 3,
                        child: _RecentSaveTile(
                          name: name,
                          city: city,
                          network: save.sourceNetwork,
                          createdAt: save.createdAt,
                        ),
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
  const _RecentSaveTile({
    required this.name,
    required this.city,
    required this.network,
    required this.createdAt,
  });

  final String name;
  final String city;
  final String network;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.violetSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _networkIcon(network),
              color: AppTheme.violet,
              size: 22,
            ),
          ),
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
    );
  }

  IconData _networkIcon(String n) => switch (n) {
    'tiktok' => Icons.music_note_rounded,
    'instagram' => Icons.camera_alt_rounded,
    'whatsapp' => Icons.chat_rounded,
    'googleMaps' => Icons.map_rounded,
    'youtube' => Icons.play_circle_rounded,
    _ => Icons.place_rounded,
  };

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
