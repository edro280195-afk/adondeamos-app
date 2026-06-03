import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/places/place_models.dart';
import 'package:adondeamos/features/saves/save_models.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:adondeamos/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  // Paleta de color por red social
  static (Color bg, Color fg) _networkPalette(String n) => switch (n) {
    'tiktok'     => (const Color(0xFFF2F2F2), const Color(0xFF141414)),
    'instagram'  => (const Color(0xFFFBE8F2), const Color(0xFFBD2470)),
    'facebook'   => (const Color(0xFFEAF1FD), const Color(0xFF1877F2)),
    'whatsapp'   => (const Color(0xFFE6F7F0), const Color(0xFF128C7E)),
    'youtube'    => (const Color(0xFFFFEAEA), const Color(0xFFCC0000)),
    'googleMaps' => (AppTheme.surfaceBlue, AppTheme.electricSapphire),
    _            => (AppTheme.surfaceBlue, AppTheme.electricSapphire),
  };

  static IconData _networkIcon(String n) => switch (n) {
    'tiktok'     => Icons.music_note_rounded,
    'instagram'  => Icons.camera_alt_rounded,
    'facebook'   => Icons.facebook_rounded,
    'whatsapp'   => Icons.chat_rounded,
    'googleMaps' => Icons.map_rounded,
    'youtube'    => Icons.play_circle_rounded,
    _            => Icons.place_rounded,
  };

  static String _networkLabel(String n) => switch (n) {
    'tiktok'     => 'TikTok',
    'instagram'  => 'Instagram',
    'facebook'   => 'Facebook',
    'whatsapp'   => 'WhatsApp',
    'googleMaps' => 'Google Maps',
    'youtube'    => 'YouTube',
    _            => 'Manual',
  };

  @override
  Widget build(BuildContext context) {
    final placeName = save.place.displayName;
    final city = save.place.city;
    final (bgColor, fgColor) = _networkPalette(save.sourceNetwork);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading: thumbnail o ícono de red con color específico
            _SaveLeadingIcon(
              save: save,
              bgColor: bgColor,
              fgColor: fgColor,
              icon: _networkIcon(save.sourceNetwork),
            ),
            const SizedBox(width: 14),

            // Contenido textual
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: AppTheme.ink,
                    ),
                  ),
                  if (city != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 11, color: AppTheme.muted),
                        const SizedBox(width: 3),
                        Text(
                          city,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      // Chip de red con color específico
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _networkLabel(save.sourceNetwork),
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (save.note != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            save.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Indicador de estado (punto de color)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPending ? AppTheme.warm : AppTheme.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isPending ? Icons.bookmark_rounded : Icons.check_circle_rounded,
                    size: 18,
                    color: isPending
                        ? AppTheme.warm.withValues(alpha: 0.7)
                        : AppTheme.green.withValues(alpha: 0.7),
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

class _SaveLeadingIcon extends StatelessWidget {
  const _SaveLeadingIcon({
    required this.save,
    required this.bgColor,
    required this.fgColor,
    required this.icon,
  });

  final PlaceSave save;
  final Color bgColor;
  final Color fgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final thumb = save.thumbnailUrl;

    if (thumb != null && thumb.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          thumb,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconBox(),
        ),
      );
    }

    return _iconBox();
  }

  Widget _iconBox() => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: fgColor, size: 30),
  );
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.network});
  final String network;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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

class SaveDetailScreen extends ConsumerStatefulWidget {
  const SaveDetailScreen({super.key, required this.save});

  final PlaceSave save;

  @override
  ConsumerState<SaveDetailScreen> createState() => _SaveDetailScreenState();
}

class _SaveDetailScreenState extends ConsumerState<SaveDetailScreen> {
  // URL de portada local: se actualiza al subir/borrar foto sin relanzar la pantalla.
  String? _localThumbnailUrl;
  bool _thumbnailInitialized = false;

  // Foto de Google cargada bajo demanda (solo para origin=google).
  PlaceResolveResult? _googleDetails;
  bool _loadingGoogle = false;

  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _localThumbnailUrl = widget.save.thumbnailUrl;
    _thumbnailInitialized = true;

    if (widget.save.place.isGoogle &&
        widget.save.thumbnailUrl == null &&
        widget.save.place.googlePlaceId != null) {
      _loadGoogleDetails();
    }
  }

  Future<void> _loadGoogleDetails() async {
    if (!mounted) return;
    setState(() => _loadingGoogle = true);
    try {
      final token = ref.read(authControllerProvider).asData?.value.token;
      if (token == null) return;
      final result = await ref.read(placesApiProvider).resolvePlace(
        token: token,
        googlePlaceId: widget.save.place.googlePlaceId!,
      );
      if (mounted) setState(() => _googleDetails = result);
    } catch (_) {
      // No bloquear el detalle si falla la foto.
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  String get _effectiveThumbnailUrl {
    if (_thumbnailInitialized && _localThumbnailUrl != null) {
      return _localThumbnailUrl!;
    }
    return widget.save.thumbnailUrl ?? '';
  }

  bool get _hasPhoto => _effectiveThumbnailUrl.isNotEmpty;

  String? get _googlePhotoUrl =>
      !_hasPhoto ? _googleDetails?.google.photoUrl : null;

  String? get _googlePhotoAttribution =>
      !_hasPhoto ? _googleDetails?.google.photoAttribution : null;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final token = ref.read(authControllerProvider).asData?.value.token;
      if (token == null) throw const ApiException('Sin sesión activa.');

      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      final url = await ref.read(savesApiProvider).uploadPhoto(
        token: token,
        saveId: widget.save.id,
        fileBytes: bytes,
        contentType: mime,
        fileName: picked.name,
      );

      if (mounted) {
        setState(() => _localThumbnailUrl = url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quitar foto'),
            content: const Text('¿Seguro que quieres quitar la foto de portada?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Quitar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final token = ref.read(authControllerProvider).asData?.value.token;
      if (token == null) throw const ApiException('Sin sesión activa.');

      await ref.read(savesApiProvider).deletePhoto(
        token: token,
        saveId: widget.save.id,
      );

      if (mounted) {
        setState(() => _localThumbnailUrl = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto eliminada.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.save;
    final placeName = save.place.displayName;
    final heroUrl = _hasPhoto ? _effectiveThumbnailUrl : _googlePhotoUrl;
    final attribution = _googlePhotoAttribution;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBackground(
                photoUrl: heroUrl,
                isLoading: _loadingGoogle,
                child: attribution != null
                    ? Positioned(
                        bottom: 8,
                        right: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '© $attribution · Google',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            actions: [
              if (_uploadingPhoto)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                PopupMenuButton<_PhotoAction>(
                  icon: const Icon(Icons.photo_camera_rounded),
                  tooltip: 'Foto de portada',
                  onSelected: (action) {
                    if (action == _PhotoAction.upload) _pickAndUpload();
                    if (action == _PhotoAction.delete) _deletePhoto();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _PhotoAction.upload,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.upload_rounded),
                        title: Text('Subir foto'),
                      ),
                    ),
                    if (_hasPhoto)
                      const PopupMenuItem(
                        value: _PhotoAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Quitar foto'),
                        ),
                      ),
                  ],
                ),
            ],
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

enum _PhotoAction { upload, delete }

/// Hero de la pantalla de detalle: foto real, shimmer de carga o gradiente de fallback.
class _HeroBackground extends StatelessWidget {
  const _HeroBackground({
    required this.photoUrl,
    required this.isLoading,
    this.child,
  });

  final String? photoUrl;
  final bool isLoading;
  final Widget? child; // atribución overlay

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerBox(height: 260, borderRadius: 0);
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          ),
          ?child,
        ],
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.deepBrandGradient),
      child: const Center(
        child: Icon(Icons.place_rounded, size: 72, color: Colors.white38),
      ),
    );
  }
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
