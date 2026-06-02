import 'dart:async';

import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/places/place_models.dart';
import 'package:adondeamos/features/saves/saves_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardar lugar'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.search_rounded), text: 'Buscar'),
            Tab(icon: Icon(Icons.edit_location_alt_rounded), text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_SearchTab(), _ManualTab()],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB BÚSQUEDA GOOGLE PLACES
// ──────────────────────────────────────────────────────────────────────────────

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _searchController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();

  List<PlacePrediction> _predictions = [];
  PlaceResolveResult? _resolved;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _searchError;
  String _visibility = 'private';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _predictions = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String query) async {
    final token = _token;
    if (token == null) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await ref
          .read(placesApiProvider)
          .searchPlaces(token: token, query: query);
      if (mounted) setState(() => _predictions = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _searchError = e.message);
    } catch (error) {
      if (mounted) setState(() => _searchError = 'Error al buscar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _resolve(PlacePrediction prediction) async {
    final token = _token;
    if (token == null) return;

    setState(() {
      _isSearching = true;
      _predictions = [];
      _searchController.text = prediction.description;
    });
    try {
      final result = await ref
          .read(placesApiProvider)
          .resolvePlace(token: token, googlePlaceId: prediction.placeId);
      setState(() => _resolved = result);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final resolved = _resolved;
    final token = _token;
    if (resolved == null || token == null) return;

    setState(() => _isSaving = true);
    try {
      final sourceNetwork = _detectSourceNetwork(_urlController.text);
      await ref
          .read(savesApiProvider)
          .createSave(
            token: token,
            placeId: resolved.place.id,
            sourceNetwork: sourceNetwork,
            sourceUrl: _emptyToNull(_urlController.text),
            note: _emptyToNull(_noteController.text),
            visibility: _visibility,
          );
      ref.invalidate(pendingSavesProvider);
      _reset();
      _showMessage('¡Lugar guardado!');
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() {
    setState(() {
      _resolved = null;
      _predictions = [];
      _searchError = null;
    });
    _searchController.clear();
    _urlController.clear();
    _noteController.clear();
    _visibility = 'private';
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  static String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static String _detectSourceNetwork(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('tiktok')) return 'tiktok';
    if (lower.contains('instagram')) return 'instagram';
    if (lower.contains('facebook') || lower.contains('fb.watch')) {
      return 'facebook';
    }
    if (lower.contains('whatsapp') || lower.contains('wa.me')) {
      return 'whatsapp';
    }
    if (lower.contains('google') || lower.contains('maps.app.goo.gl')) {
      return 'googleMaps';
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return 'youtube';
    }
    return 'manual';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: [
        // Campo de búsqueda
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Busca un restaurante, cafetería...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _resolved != null
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _reset,
                  )
                : null,
          ),
        ),

        // Error búsqueda
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: TextStyle(color: AppTheme.error, fontSize: 13),
          ),
        ],

        // Lista predicciones
        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(_predictions.length, (i) {
            final p = _predictions[i];
            return AnimatedListItem(
              index: i,
              delayMs: 0,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.violetSoft,
                  child: Icon(Icons.place_rounded, color: AppTheme.violet),
                ),
                title: Text(
                  p.mainText ?? p.description,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: p.secondaryText != null ? Text(p.secondaryText!) : null,
                onTap: () => _resolve(p),
              ),
            );
          }),
        ],

        // Lugar resuelto — tarjeta de confirmación
        if (_resolved != null) ...[
          const SizedBox(height: 16),
          _ResolvedPlaceCard(result: _resolved!),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Enlace donde lo viste (opcional)',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _urlController,
                builder: (_, value, _) {
                  final network = _detectSourceNetwork(value.text);
                  if (network == 'manual') return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      widthFactor: 1,
                      child: _NetworkBadge(network: network),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            selected: {_visibility},
            onSelectionChanged: (v) => setState(() => _visibility = v.single),
            segments: const [
              ButtonSegment(
                value: 'private',
                icon: Icon(Icons.lock_rounded),
                label: Text('Privado'),
              ),
              ButtonSegment(
                value: 'group',
                icon: Icon(Icons.groups_rounded),
                label: Text('Grupo'),
              ),
              ButtonSegment(
                value: 'public',
                icon: Icon(Icons.public_rounded),
                label: Text('Público'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bookmark_add_rounded),
            label: const Text('Guardar lugar'),
          ),
        ],

        // Estado inicial vacío
        if (_predictions.isEmpty && _resolved == null && !_isSearching) ...[
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  size: 64,
                  color: AppTheme.violetSoft,
                ),
                SizedBox(height: 12),
                Text(
                  'Busca cualquier lugar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Restaurantes, cafeterías, bares...\nPowered by Google Places.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ResolvedPlaceCard extends StatelessWidget {
  const _ResolvedPlaceCard({required this.result});

  final PlaceResolveResult result;

  @override
  Widget build(BuildContext context) {
    final google = result.google;
    final hasAddress = google.formattedAddress != null;
    final hasCoords = google.latitude != null && google.longitude != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.deepBrandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lugar encontrado',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              google.displayName ?? 'Lugar de Google',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (hasAddress) ...[
              const SizedBox(height: 4),
              Text(
                google.formattedAddress!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            if (hasCoords) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _Tag(label: '${google.latitude!.toStringAsFixed(4)}°N', color: Colors.white24),
                  const SizedBox(width: 8),
                  _Tag(label: '${google.longitude!.toStringAsFixed(4)}°W', color: Colors.white24),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB MANUAL
// ──────────────────────────────────────────────────────────────────────────────

class _ManualTab extends ConsumerStatefulWidget {
  const _ManualTab();

  @override
  ConsumerState<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends ConsumerState<_ManualTab> {
  static const _defaultLatitude = 27.4779;
  static const _defaultLongitude = -99.5496;

  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Nuevo Laredo');
  final _latitudeController = TextEditingController(
    text: _defaultLatitude.toString(),
  );
  final _longitudeController = TextEditingController(
    text: _defaultLongitude.toString(),
  );
  final _noteController = TextEditingController();
  String _visibility = 'private';
  bool _isSaving = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;

  @override
  Widget build(BuildContext context) {
    final sourceNetwork = _detectSourceNetwork(_urlController.text);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          TextFormField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Enlace donde lo viste',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: sourceNetwork != 'manual'
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: _NetworkBadge(network: sourceNetwork),
                      ),
                    )
                  : null,
            ),
            validator: _validateUrl,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre del lugar',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Escribe el nombre del lugar.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cityController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              prefixIcon: Icon(Icons.location_city_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  validator: _validateCoordinate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  validator: _validateCoordinate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Nota',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            selected: {_visibility},
            onSelectionChanged: (v) => setState(() => _visibility = v.single),
            segments: const [
              ButtonSegment(
                value: 'private',
                icon: Icon(Icons.lock_rounded),
                label: Text('Privado'),
              ),
              ButtonSegment(
                value: 'group',
                icon: Icon(Icons.groups_rounded),
                label: Text('Grupo'),
              ),
              ButtonSegment(
                value: 'public',
                icon: Icon(Icons.public_rounded),
                label: Text('Público'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bookmark_add_rounded),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final token = _token;
    if (token == null) {
      _showMessage('Tu sesión ya no está activa.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final place = await ref
          .read(placesApiProvider)
          .createOwnPlace(
            token: token,
            name: _nameController.text.trim(),
            latitude: double.parse(_latitudeController.text.trim()),
            longitude: double.parse(_longitudeController.text.trim()),
            city: _emptyToNull(_cityController.text),
          );

      await ref
          .read(savesApiProvider)
          .createSave(
            token: token,
            placeId: place.id,
            sourceNetwork: _detectSourceNetwork(_urlController.text),
            sourceUrl: _emptyToNull(_urlController.text),
            note: _emptyToNull(_noteController.text),
            visibility: _visibility,
          );

      ref.invalidate(pendingSavesProvider);
      _clearForm();
      _showMessage('Lugar guardado.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Error inesperado: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Pega un enlace válido.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'El enlace debe iniciar con http o https.';
    }
    return null;
  }

  String? _validateCoordinate(String? value) {
    final coordinate = double.tryParse(value?.trim() ?? '');
    if (coordinate == null) return 'Dato inválido.';
    return null;
  }

  void _clearForm() {
    _urlController.clear();
    _nameController.clear();
    _cityController.text = 'Nuevo Laredo';
    _latitudeController.text = _defaultLatitude.toString();
    _longitudeController.text = _defaultLongitude.toString();
    _noteController.clear();
    setState(() => _visibility = 'private');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _detectSourceNetwork(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('tiktok')) return 'tiktok';
    if (lower.contains('instagram')) return 'instagram';
    if (lower.contains('facebook') || lower.contains('fb.watch')) {
      return 'facebook';
    }
    if (lower.contains('whatsapp') || lower.contains('wa.me')) {
      return 'whatsapp';
    }
    if (lower.contains('google') || lower.contains('maps.app.goo.gl')) {
      return 'googleMaps';
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return 'youtube';
    }
    return 'manual';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ──────────────────────────────────────────────────────────────────────────────

class _NetworkBadge extends StatelessWidget {
  const _NetworkBadge({required this.network});

  final String network;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.violetSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _label,
          style: const TextStyle(
            color: AppTheme.violet,
            fontSize: 12,
            fontWeight: FontWeight.w900,
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
    'googleMaps' => 'Maps',
    'youtube' => 'YouTube',
    _ => 'Manual',
  };
}
