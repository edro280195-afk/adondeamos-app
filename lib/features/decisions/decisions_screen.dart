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
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: decision == null
          ? const _StartScreen(key: ValueKey('start'))
          : decision.hasMatch
              ? _MatchScreen(key: const ValueKey('match'), decision: decision)
              : decision.options.isEmpty
                  ? _AddOptionsScreen(
                      key: const ValueKey('options'), decision: decision)
                  : _VotingScreen(
                      key: const ValueKey('voting'), decision: decision),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PANTALLA INICIAL
// ──────────────────────────────────────────────────────────────────────────────

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
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
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
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

// ──────────────────────────────────────────────────────────────────────────────
// AGREGAR OPCIONES
// ──────────────────────────────────────────────────────────────────────────────

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
          onPressed: () => ref.read(activeDecisionProvider.notifier).clear(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona lugares',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// VOTACIÓN
// ──────────────────────────────────────────────────────────────────────────────

class _VotingScreen extends ConsumerWidget {
  const _VotingScreen({super.key, required this.decision});

  final Decision decision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.read(authControllerProvider).asData?.value.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votar'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => ref.read(activeDecisionProvider.notifier).clear(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                await ref.read(decisionOpsProvider).refresh(decision.id);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: decision.options.length,
        itemBuilder: (_, index) {
          final option = decision.options[index];
          final myVote = myUserId != null
              ? option.votes.where((v) => v.userId == myUserId).firstOrNull
              : null;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < decision.options.length - 1 ? 12 : 0,
            ),
            child: _OptionCard(
              option: option,
              myVote: myVote,
              onVote: (isYes) async {
                HapticFeedback.lightImpact();
                try {
                  await ref.read(decisionOpsProvider).castVote(
                        decisionId: decision.id,
                        optionId: option.id,
                        isYes: isYes,
                      );
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.myVote,
    required this.onVote,
  });

  final DecisionOption option;
  final Vote? myVote;
  final void Function(bool isYes) onVote;

  @override
  Widget build(BuildContext context) {
    final name =
        option.place.name ??
        option.place.googlePlaceId?.substring(0, 10) ??
        'Lugar de Google';
    final yesCount = option.votes.where((v) => v.isYes).length;
    final noCount = option.votes.where((v) => !v.isYes).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            option.isMatch ? Border.all(color: AppTheme.green, width: 2) : null,
        boxShadow: option.isMatch
            ? [
                BoxShadow(
                  color: AppTheme.green.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (option.isMatch)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEDF7F2),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '¡Match!',
                        style: TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (option.place.city != null) ...[
              const SizedBox(height: 4),
              Text(
                option.place.city!,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ],
            // Barra de progreso de votos
            if (yesCount + noCount > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: yesCount,
                        child: Container(color: AppTheme.green),
                      ),
                      if (noCount > 0) ...[
                        const SizedBox(width: 3),
                        Flexible(
                          flex: noCount,
                          child: Container(color: AppTheme.error.withValues(alpha: 0.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '$yesCount sí · $noCount no',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const Spacer(),
                _VoteButton(
                  isYes: false,
                  selected: myVote?.isYes == false,
                  onTap: () => onVote(false),
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  isYes: true,
                  selected: myVote?.isYes == true,
                  onTap: () => onVote(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.isYes,
    required this.selected,
    required this.onTap,
  });

  final bool isYes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isYes ? AppTheme.green : AppTheme.error;
    final bg = selected ? color : color.withValues(alpha: 0.1);
    final fg = selected ? Colors.white : color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Anim.micro,
          curve: Anim.enter,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isYes ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                color: fg,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isYes ? 'Sí' : 'No',
                style: TextStyle(color: fg, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MATCH — con animación de celebración
// ──────────────────────────────────────────────────────────────────────────────

class _MatchScreen extends ConsumerStatefulWidget {
  const _MatchScreen({super.key, required this.decision});

  final Decision decision;

  @override
  ConsumerState<_MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<_MatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedOptions = widget.decision.options
        .where((o) => widget.decision.matchedPlaceIds.contains(o.place.id))
        .toList();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.icyBlue,
              AppTheme.babyBlueIce,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 72)),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Match!',
                        style: TextStyle(
                          color: AppTheme.ultrasonicBlue,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Todos están de acuerdo en ir a:',
                        style: TextStyle(color: AppTheme.muted, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ...matchedOptions.map(
                        (opt) => _MatchPlaceCard(option: opt),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(activeDecisionProvider.notifier)
                            .clear(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.electricSapphire,
                          foregroundColor: AppTheme.surface,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('¡Listo, a disfrutar!'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchPlaceCard extends StatelessWidget {
  const _MatchPlaceCard({required this.option});

  final DecisionOption option;

  @override
  Widget build(BuildContext context) {
    final name =
        option.place.name ??
        option.place.googlePlaceId?.substring(0, 10) ??
        'Lugar de Google';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.place_rounded,
                color: AppTheme.electricSapphire,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (option.place.city != null) ...[
                const SizedBox(height: 4),
                Text(
                  option.place.city!,
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
