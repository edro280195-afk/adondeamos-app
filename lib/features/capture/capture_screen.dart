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
      if (mounted) {
        setState(() => _searchError = 'Error al buscar. Intenta de nuevo.');
      }
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
      await ref.read(savesApiProvider).createSave(
        token: token,
        placeId: resolved.place.id,
        sourceNetwork: _detectSourceNetwork(_urlController.text),
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
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: TextStyle(color: AppTheme.error, fontSize: 13),
          ),
        ],
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
                subtitle: p.secondaryText != null
                    ? Text(p.secondaryText!)
                    : null,
                onTap: () => _resolve(p),
              ),
            );
          }),
        ],
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
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lugar encontrado',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
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
                  _Tag(
                    label: '${google.latitude!.toStringAsFixed(4)}°N',
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  _Tag(
                    label: '${google.longitude!.toStringAsFixed(4)}°W',
                    color: Colors.white24,
                  ),
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
// TAB MANUAL — REDISEÑADO
// ──────────────────────────────────────────────────────────────────────────────

class _ManualTab extends ConsumerStatefulWidget {
  const _ManualTab();

  @override
  ConsumerState<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends ConsumerState<_ManualTab> {
  // FIX DEFINITIVO: se usan String literals, no double.
  // Con const double en DDC (compilador web) el valor crudo -99.5496 llegaba a
  // TextEditingController sin pasar por toString(), causando TypeError.
  // Con const String no hay ninguna conversión: el valor ya es String.
  static const String _defLat = '27.4779';
  static const String _defLng = '-99.5496';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _urlCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _noteCtrl;

  String _visibility = 'private';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl  = TextEditingController();
    _nameCtrl = TextEditingController();
    _cityCtrl = TextEditingController(text: 'Nuevo Laredo');
    _latCtrl  = TextEditingController(text: _defLat); // String literal directo
    _lngCtrl  = TextEditingController(text: _defLng); // String literal directo
    _noteCtrl = TextEditingController();
    // SIN addListener: el preview usa ValueListenableBuilder para no disparar
    // un setState completo en cada tecla (que era lo que desencadenaba el error).
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? get _token => ref.read(authControllerProvider).asData?.value.token;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
        children: [
          // ── Chip de contexto
          const _ManualHintBanner(),
          const SizedBox(height: 24),

          // ── Preview en vivo: ValueListenableBuilder evita setState completo.
          // Antes los addListener disparaban un rebuild de todo _ManualTabState
          // en cada tecla, lo que re-evaluaba la const double y causaba el TypeError.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameCtrl,
            builder: (_ , nameVal, _) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _cityCtrl,
                builder: (_ , cityVal, _) {
                  final name = nameVal.text.trim();
                  final city = cityVal.text.trim();
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: name.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _PlacePreviewCard(
                              name: name,
                              city: city.isNotEmpty ? city : 'Sin ciudad',
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                },
              );
            },
          ),

          // ── El lugar
          _Section(
            icon: Icons.storefront_rounded,
            label: 'El lugar',
            color: AppTheme.electricSapphire,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nombre del lugar *',
                  prefixIcon: Icon(Icons.storefront_rounded),
                  hintText: 'Tacos El Gordo, Café Central...',
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Escribe el nombre del lugar.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Coordenadas
          _Section(
            icon: Icons.my_location_rounded,
            label: 'Coordenadas',
            color: AppTheme.green,
            trailing: TextButton.icon(
              onPressed: _showCoordsHelp,
              icon: const Icon(Icons.help_outline_rounded, size: 15),
              label: const Text('¿Cómo obtenerlas?'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        prefixIcon: Icon(Icons.swap_vert_rounded),
                      ),
                      validator: _validateCoord,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        prefixIcon: Icon(Icons.swap_horiz_rounded),
                      ),
                      validator: _validateCoord,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Origen: ValueListenableBuilder para el badge de red (sin setState).
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _urlCtrl,
            builder: (_ , urlVal, _) {
              final network = _detectSourceNetwork(urlVal.text);
              return _Section(
                icon: Icons.link_rounded,
                label: 'Origen',
                color: AppTheme.warm,
                children: [
                  TextFormField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Enlace donde lo viste (opcional)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: network != 'manual'
                          ? Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Center(
                                widthFactor: 1,
                                child: _NetworkBadge(network: network),
                              ),
                            )
                          : null,
                    ),
                    validator: _validateUrl,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Nota
          _Section(
            icon: Icons.notes_rounded,
            label: 'Nota',
            color: AppTheme.muted,
            children: [
              TextFormField(
                controller: _noteCtrl,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nota personal (opcional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                  hintText: 'Ir un viernes, pedir los de pastor...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Visibilidad
          _VisibilityPicker(
            value: _visibility,
            onChanged: (v) => setState(() => _visibility = v),
          ),
          const SizedBox(height: 28),

          // ── Botón guardar: ValueListenableBuilder para el label con el nombre.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameCtrl,
            builder: (_ , nameVal, _) {
              final name = nameVal.text.trim();
              return _SaveButton(
                isSaving: _isSaving,
                label: name.isNotEmpty ? 'Guardar "$name"' : 'Guardar lugar',
                onTap: _submit,
              );
            },
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
      _showSnack('Tu sesión ya no está activa.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final place = await ref.read(placesApiProvider).createOwnPlace(
        token: token,
        name: _nameCtrl.text.trim(),
        latitude: double.parse(_latCtrl.text.trim()),
        longitude: double.parse(_lngCtrl.text.trim()),
        city: _emptyToNull(_cityCtrl.text),
      );

      await ref.read(savesApiProvider).createSave(
        token: token,
        placeId: place.id,
        sourceNetwork: _detectSourceNetwork(_urlCtrl.text),
        sourceUrl: _emptyToNull(_urlCtrl.text),
        note: _emptyToNull(_noteCtrl.text),
        visibility: _visibility,
      );

      ref.invalidate(pendingSavesProvider);
      _clearForm();
      _showSnack('¡Lugar guardado!');
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack('Error inesperado: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _urlCtrl.clear();
    _nameCtrl.clear();
    _cityCtrl.text = 'Nuevo Laredo';
    _latCtrl.text = _defLat; // String literal directo, sin conversión
    _lngCtrl.text = _defLng; // String literal directo, sin conversión
    _noteCtrl.clear();
    setState(() => _visibility = 'private');
  }

  void _showCoordsHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CoordsHelpSheet(),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static String? _validateUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Pega un enlace válido.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'El enlace debe empezar con http o https.';
    }
    return null;
  }

  static String? _validateCoord(String? value) {
    if (double.tryParse(value?.trim() ?? '') == null) return 'Valor inválido.';
    return null;
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
// Widgets propios del tab Manual
// ──────────────────────────────────────────────────────────────────────────────

/// Chip que explica cuándo usar el modo manual.
class _ManualHintBanner extends StatelessWidget {
  const _ManualHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warm.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.warm.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.push_pin_rounded,
              color: AppTheme.warm,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lugar propio',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppTheme.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Para lugares que no están en Google Maps',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de preview en vivo. Aparece al empezar a escribir el nombre.
class _PlacePreviewCard extends StatelessWidget {
  const _PlacePreviewCard({required this.name, required this.city});

  final String name;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.deepBrandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pin_drop_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_city_rounded,
                      color: Colors.white60,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Propio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección con encabezado de ícono + label + children.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.label,
    required this.color,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color color;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppTheme.ink,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

/// Selector de visibilidad dentro de un card.
class _VisibilityPicker extends StatelessWidget {
  const _VisibilityPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, size: 16, color: AppTheme.muted),
              SizedBox(width: 6),
              Text(
                'Visibilidad',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            selected: {value},
            onSelectionChanged: (v) => onChanged(v.single),
            segments: const [
              ButtonSegment(
                value: 'private',
                icon: Icon(Icons.lock_rounded, size: 16),
                label: Text('Solo yo'),
              ),
              ButtonSegment(
                value: 'group',
                icon: Icon(Icons.groups_rounded, size: 16),
                label: Text('Grupo'),
              ),
              ButtonSegment(
                value: 'public',
                icon: Icon(Icons.public_rounded, size: 16),
                label: Text('Público'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón de guardar con gradient y sombra. El label muestra el nombre del lugar.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.onTap,
  });

  final bool isSaving;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppTheme.deepBrandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isSaving ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Center(
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

/// Bottom sheet con instrucciones para obtener coordenadas desde Google Maps.
class _CoordsHelpSheet extends StatelessWidget {
  const _CoordsHelpSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¿Cómo obtener coordenadas?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          const _HelpStep(
            number: '1',
            color: AppTheme.electricSapphire,
            text: 'Abre Google Maps en tu teléfono.',
          ),
          const SizedBox(height: 14),
          const _HelpStep(
            number: '2',
            color: AppTheme.electricSapphire,
            text:
                'Mantén presionado el punto exacto del lugar hasta que aparezca un marcador rojo.',
          ),
          const SizedBox(height: 14),
          const _HelpStep(
            number: '3',
            color: AppTheme.electricSapphire,
            text:
                'En la parte inferior verás las coordenadas (ej. 27.4779, -99.5496). Tócalas para copiarlas.',
          ),
          const SizedBox(height: 14),
          const _HelpStep(
            number: '4',
            color: AppTheme.green,
            text: 'Pega la latitud y longitud en los campos correspondientes.',
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.electricSapphire,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si no tienes las coordenadas, las de Nuevo Laredo (27.4779, -99.5496) se cargan por defecto.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.color,
    required this.text,
  });

  final String number;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.ink,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets compartidos (Search + Manual)
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
