// ignore_for_file: unused_import

import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/core/animations/animation_constants.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/decisions/decisions_controller.dart';
import 'package:adondeamos/shared/models/decision_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DecisionsScreen extends ConsumerWidget {
  const DecisionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(activeDecisionProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: decision == null
          ? const _StartScreen(key: ValueKey('start'))
          : decision.hasMatch
          ? _MatchScreen(key: const ValueKey('match'), decision: decision)
          : decision.options.isEmpty
          ? _AddOptionsScreen(
              key: const ValueKey('options'),
              decision: decision,
            )
          : _VotingScreen(key: const ValueKey('voting'), decision: decision),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA INICIAL
// ─────────────────────────────────────────────────────────────────────────────

class _StartScreen extends ConsumerStatefulWidget {
  const _StartScreen({super.key});

  @override
  ConsumerState<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<_StartScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decidir')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _entranceCtrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceCtrl,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                )),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿A dónde vamos?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Inicia una sesión para votar entre los lugares que guardaste y encontrar el match.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceCtrl,
                  curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                )),
                child: Opacity(
                  opacity: _entranceCtrl.value.clamp(0.0, 1.0),
                  child: _DecisionCard(
                    icon: Icons.person_rounded,
                    title: 'Decisión individual',
                    subtitle: 'Solo yo decido desde mis guardados.',
                    color: AppTheme.violet,
                    onTap: _loading ? null : () => _create(null),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceCtrl,
                  curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
                )),
                child: Opacity(
                  opacity: _entranceCtrl.value.clamp(0.0, 1.0),
                  child: _DecisionCard(
                    icon: Icons.groups_rounded,
                    title: 'Decisión grupal',
                    subtitle: 'Todos los miembros del grupo votan.',
                    color: AppTheme.green,
                    onTap: _loading ? null : () => _create(null),
                  ),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(String? groupId) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ref.read(decisionOpsProvider).createDecision(groupId: groupId);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Anim.micro,
          curve: Anim.enter,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: onTap != null
                ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  radius: 26,
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AGREGAR OPCIONES
// ─────────────────────────────────────────────────────────────────────────────

class _AddOptionsScreen extends ConsumerStatefulWidget {
  const _AddOptionsScreen({super.key, required this.decision});
  final Decision decision;

  @override
  ConsumerState<_AddOptionsScreen> createState() => _AddOptionsScreenState();
}

class _AddOptionsScreenState extends ConsumerState<_AddOptionsScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar opciones'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(activeDecisionProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona lugares',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Elige cómo quieres agregar los lugares candidatos para esta decisión.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : _autoFill,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Llenar desde mis pendientes'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Usa todos tus lugares pendientes como opciones para votar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoFill() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await ref.read(decisionOpsProvider).addFromSaves(widget.decision.id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOTACIÓN — estilo Tinder swipe
// ─────────────────────────────────────────────────────────────────────────────

class _VotingScreen extends ConsumerStatefulWidget {
  const _VotingScreen({super.key, required this.decision});
  final Decision decision;

  @override
  ConsumerState<_VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<_VotingScreen>
    with SingleTickerProviderStateMixin {
  Offset _cardOffset = Offset.zero;
  bool _isVoting = false;

  late AnimationController _flyOutCtrl;
  late Animation<Offset> _flyAnim;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _flyOutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _flyAnim = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _flyOutCtrl.dispose();
    super.dispose();
  }

  String? get _myId => ref.read(authControllerProvider).asData?.value.user?.id;

  List<DecisionOption> get _unvoted => widget.decision.options
      .where((o) => !o.votes.any((v) => v.userId == _myId))
      .toList();

  List<DecisionOption> get _voted => widget.decision.options
      .where((o) => o.votes.any((v) => v.userId == _myId))
      .toList();

  // Progreso del swipe: −1 (izquierda) a +1 (derecha)
  double get _swipeProgress =>
      (_isAnimatingOut ? _flyAnim.value.dx : _cardOffset.dx) / 160;

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isVoting) return;
    setState(() => _cardOffset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isVoting) return;
    if (_cardOffset.dx.abs() < 110) {
      setState(() => _cardOffset = Offset.zero);
      return;
    }
    _vote(_cardOffset.dx > 0);
  }

  Future<void> _vote(bool isYes) async {
    if (_isVoting || _unvoted.isEmpty) return;
    HapticFeedback.mediumImpact();

    final option = _unvoted.first;
    setState(() => _isVoting = true);

    // Anima el card fuera de pantalla
    final startOffset = _cardOffset;
    final endOffset = Offset(isYes ? 700 : -700, _cardOffset.dy * 0.5);
    _flyAnim = Tween<Offset>(begin: startOffset, end: endOffset)
        .animate(CurvedAnimation(parent: _flyOutCtrl, curve: Curves.easeOutCubic));

    setState(() => _isAnimatingOut = true);
    _flyOutCtrl.forward(from: 0);

    // Dispara el API después de un breve delay para que la animación arranque
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      await ref.read(decisionOpsProvider).castVote(
            decisionId: widget.decision.id,
            optionId: option.id,
            isYes: isYes,
          );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        await _flyOutCtrl.animateTo(1);
        setState(() {
          _isVoting = false;
          _isAnimatingOut = false;
          _cardOffset = Offset.zero;
          _flyOutCtrl.reset();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unvoted = _unvoted;
    final voted = _voted;
    final total = widget.decision.options.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('¿A dónde vamos?'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(activeDecisionProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () async {
              try {
                await ref.read(decisionOpsProvider).refresh(widget.decision.id);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progreso
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Text(
                  '${voted.length} de $total',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? voted.length / total : 0,
                      backgroundColor: AppTheme.line,
                      color: AppTheme.green,
                      minHeight: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stack de cartas
          Expanded(
            child: unvoted.isEmpty
                ? const _AllVotedState()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildCardStack(unvoted),
                  ),
          ),

          // Botones de acción
          if (unvoted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    isYes: false,
                    enabled: !_isVoting,
                    onTap: () => _vote(false),
                  ),
                  const SizedBox(width: 32),
                  _ActionButton(
                    isYes: true,
                    enabled: !_isVoting,
                    onTap: () => _vote(true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardStack(List<DecisionOption> unvoted) {
    // Offset activo (drag o animación de salida)
    final activeOffset = _isAnimatingOut
        ? AnimatedBuilder(
            animation: _flyAnim,
            builder: (_, __) {
              final offset = _flyAnim.value;
              final rotate = offset.dx / 800;
              return _buildTopCard(unvoted.first, offset, rotate, _isAnimatingOut ? offset.dx / 160 : _swipeProgress);
            },
          )
        : _buildTopCard(unvoted.first, _cardOffset, _cardOffset.dx / 800, _swipeProgress);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Carta trasera #3 (si existe)
        if (unvoted.length >= 3)
          Transform.translate(
            offset: const Offset(0, 20),
            child: Transform.scale(
              scale: 0.88,
              child: _SwipeCard(option: unvoted[2], swipeProgress: 0, isActive: false),
            ),
          ),

        // Carta trasera #2 (si existe)
        if (unvoted.length >= 2)
          Transform.translate(
            offset: const Offset(0, 10),
            child: Transform.scale(
              scale: 0.94,
              child: _SwipeCard(option: unvoted[1], swipeProgress: 0, isActive: false),
            ),
          ),

        // Carta activa (drag + gesture)
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: activeOffset,
        ),
      ],
    );
  }

  Widget _buildTopCard(DecisionOption option, Offset offset, double rotate, double progress) {
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy * 0.35, 0)
        ..rotateZ(rotate),
      alignment: FractionalOffset.bottomCenter,
      child: _SwipeCard(option: option, swipeProgress: progress.clamp(-1.0, 1.0), isActive: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIPE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.option,
    required this.swipeProgress,
    required this.isActive,
  });

  final DecisionOption option;
  final double swipeProgress; // -1 a +1
  final bool isActive;

  static const _networkColor = {
    'googleMaps': Color(0xFF4285F4),
    'tiktok': Color(0xFF010101),
    'instagram': Color(0xFFE1306C),
    'facebook': Color(0xFF1877F2),
    'whatsapp': Color(0xFF128C7E),
    'youtube': Color(0xFFCC0000),
  };

  static LinearGradient _networkGradient(String network) {
    final color = _networkColor[network] ?? AppTheme.electricSapphire;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.9),
        AppTheme.ultrasonicBlue,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = option.place.displayName;
    final city = option.place.city;
    final yesVotes = option.votes.where((v) => v.isYes).length;
    final noVotes = option.votes.where((v) => !v.isYes).length;

    return AspectRatio(
      aspectRatio: 0.62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo: thumbnail o gradiente
            _CardBackground(save: option.place),

            // Gradiente oscuro para legibilidad del texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.45, 0.7, 1.0],
                ),
              ),
            ),

            // Contenido inferior
            Positioned(
              bottom: 28,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                    ),
                  ),
                  if (city != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (yesVotes + noVotes > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _VoteCount(count: yesVotes, isYes: true),
                        const SizedBox(width: 8),
                        _VoteCount(count: noVotes, isYes: false),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Overlay "SÍ" al deslizar a la derecha
            if (isActive && swipeProgress > 0.08)
              Positioned(
                top: 40,
                left: 24,
                child: Opacity(
                  opacity: swipeProgress.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: -0.15,
                    child: _VoteOverlay(isYes: true),
                  ),
                ),
              ),

            // Overlay "NO" al deslizar a la izquierda
            if (isActive && swipeProgress < -0.08)
              Positioned(
                top: 40,
                right: 24,
                child: Opacity(
                  opacity: (-swipeProgress).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: 0.15,
                    child: _VoteOverlay(isYes: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground({required this.save});
  final dynamic save; // DecisionOption.place

  @override
  Widget build(BuildContext context) {
    final place = save;
    final isGoogle = place?.isGoogle ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: isGoogle
            ? AppTheme.deepBrandGradient
            : const LinearGradient(
                colors: [Color(0xFFF4A340), Color(0xFF3F8EFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Center(
        child: Icon(
          isGoogle ? Icons.map_rounded : Icons.pin_drop_rounded,
          size: 120,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _VoteOverlay extends StatelessWidget {
  const _VoteOverlay({required this.isYes});
  final bool isYes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isYes ? AppTheme.green : AppTheme.error,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isYes ? Icons.favorite_rounded : Icons.close_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            isYes ? 'SÍ' : 'NO',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  const _VoteCount({required this.count, required this.isYes});
  final int count;
  final bool isYes;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final color = isYes ? AppTheme.green : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isYes ? Icons.favorite_rounded : Icons.close_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isYes, required this.enabled, required this.onTap});

  final bool isYes;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isYes ? AppTheme.green : AppTheme.error;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: enabled ? color : color.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))]
              : null,
        ),
        child: Icon(
          isYes ? Icons.favorite_rounded : Icons.close_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _AllVotedState extends StatelessWidget {
  const _AllVotedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.how_to_vote_rounded, color: AppTheme.green, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Ya votaste en todo!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esperando que los demás voten...\nActualiza para ver si ya hay un match.',
              style: TextStyle(color: AppTheme.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH — dark mode celebración
// ─────────────────────────────────────────────────────────────────────────────

class _MatchScreen extends ConsumerStatefulWidget {
  const _MatchScreen({super.key, required this.decision});
  final Decision decision;

  @override
  ConsumerState<_MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<_MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedOptions = widget.decision.options
        .where((o) => widget.decision.matchedPlaceIds.contains(o.place.id))
        .toList();
    final match = matchedOptions.firstOrNull;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo oscuro con gradiente azul profundo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0C1829),
                  Color(0xFF12213A),
                  Color(0xFF0F2244),
                ],
              ),
            ),
          ),

          // Anillos pulsantes centrados
          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(360, 360),
                painter: _PulseRingsPainter(_pulseCtrl.value),
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Column(
              children: [
                // Botón cerrar
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: IconButton(
                      onPressed: () {
                        ref.read(activeDecisionProvider.notifier).clear();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.white38),
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji + título con escala elástica
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: const Column(
                          children: [
                            Text('🎉', style: TextStyle(fontSize: 76)),
                            SizedBox(height: 10),
                            Text(
                              '¡MATCH!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Todos están de acuerdo en ir a:',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Lugar del match con slide + fade
                      if (match != null)
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: _MatchPlaceCard(option: match),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Botones de acción
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 44),
                    child: Column(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(activeDecisionProvider.notifier).clear();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.place_rounded),
                          label: const Text('¡Vamos ahí!'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.electricSapphire,
                            minimumSize: const Size.fromHeight(56),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(activeDecisionProvider.notifier).clear();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white60,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Nueva decisión'),
                        ),
                      ],
                    ),
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

class _MatchPlaceCard extends StatelessWidget {
  const _MatchPlaceCard({required this.option});
  final DecisionOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.deepBrandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.place_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.place.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (option.place.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white38, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        option.place.city!,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter que dibuja anillos concéntricos pulsantes.
class _PulseRingsPainter extends CustomPainter {
  const _PulseRingsPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.55;

    for (int i = 0; i < 4; i++) {
      final phase = (progress + i * 0.25) % 1.0;
      final radius = phase * maxR;
      final opacity = (1.0 - phase) * 0.18;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppTheme.electricSapphire.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseRingsPainter old) => old.progress != progress;
}
