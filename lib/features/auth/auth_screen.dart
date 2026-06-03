import 'dart:async';

import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/animation_constants.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialError});

  final String? initialError;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _hasCheckedBiometrics = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoBiometrics();
    });
  }

  Future<void> _checkAutoBiometrics() async {
    if (_hasCheckedBiometrics) return;
    _hasCheckedBiometrics = true;

    final controller = ref.read(authControllerProvider.notifier);
    final hasCreds = await controller.hasSavedCredentials();
    if (hasCreds && mounted && !_isRegister) {
      await controller.loginWithBiometrics();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _toggleMode(bool register) {
    HapticFeedback.selectionClick();
    setState(() => _isRegister = register);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;
    final error = auth.hasError ? auth.error.toString() : widget.initialError;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            children: [
              AnimatedListItem(
                index: 0,
                delayMs: 0,
                child: const BrandLogo(
                  size: 54,
                  showWordmark: true,
                  subtitle: 'Lugares guardados para planes reales',
                ),
              ),
              const SizedBox(height: 26),
              AnimatedListItem(index: 1, child: const _LoginStoryPanel()),
              const SizedBox(height: 22),
              AnimatedListItem(
                index: 2,
                child: _ModeSwitch(
                  isRegister: _isRegister,
                  onChanged: _toggleMode,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedListItem(
                index: 3,
                child: _AuthFormCard(
                  isRegister: _isRegister,
                  isLoading: isLoading,
                  error: error,
                  nameController: _nameController,
                  usernameController: _usernameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  onSubmit: _submit,
                  onBiometricLogin: _isRegister
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .loginWithBiometrics(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegister) {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: name,
            username: username,
            email: email,
            password: password,
          );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .login(username: username, password: password);
  }
}

class _LoginStoryPanel extends StatefulWidget {
  const _LoginStoryPanel();

  @override
  State<_LoginStoryPanel> createState() => _LoginStoryPanelState();
}

class _LoginStoryPanelState extends State<_LoginStoryPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _startTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.surface, Color(0xFFEAF5FF), Color(0xFFD9ECFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guarda el lugar cuando aparece. Decide después sin buscarlo otra vez.',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 25,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 92,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const pointWidth = 72.0;
                      final maxLeft = constraints.maxWidth - pointWidth;
                      final centerLeft = maxLeft / 2;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: lerpDouble(-18, 0, _ctrl.value),
                            top: 10,
                            child: Opacity(
                              opacity: _ctrl.value.clamp(0.0, 1.0),
                              child: const _RoutePoint(
                                icon: Icons.smart_display_rounded,
                                label: 'Reel',
                              ),
                            ),
                          ),
                          if (_ctrl.value > 0.2)
                            Positioned.fill(
                              child: Opacity(
                                opacity: (_ctrl.value - 0.2).clamp(0.0, 1.0),
                                child: const _RouteLine(),
                              ),
                            ),
                          Positioned(
                            left: lerpDouble(
                              centerLeft + 34,
                              centerLeft,
                              _ctrl.value,
                            ),
                            top: 38,
                            child: Opacity(
                              opacity: (_ctrl.value - 0.3).clamp(0.0, 1.0),
                              child: const _RoutePoint(
                                icon: Icons.bookmark_rounded,
                                label: 'Guardado',
                                emphasized: true,
                              ),
                            ),
                          ),
                          Positioned(
                            left: lerpDouble(
                              constraints.maxWidth + 18,
                              maxLeft,
                              _ctrl.value,
                            ),
                            top: 10,
                            child: Opacity(
                              opacity: (_ctrl.value - 0.5).clamp(0.0, 1.0),
                              child: const _RoutePoint(
                                icon: Icons.how_to_vote_rounded,
                                label: 'Match',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                _MiniProof(icon: Icons.link_rounded, text: 'Links'),
                SizedBox(width: 8),
                _MiniProof(icon: Icons.groups_rounded, text: 'Grupos'),
                SizedBox(width: 8),
                _MiniProof(icon: Icons.place_rounded, text: 'Planes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RouteLinePainter());
  }
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.blueEnergy.withValues(alpha: 0.25);

    final path = Path()
      ..moveTo(42, 48)
      ..cubicTo(
        size.width * 0.30,
        6,
        size.width * 0.43,
        92,
        size.width - 44,
        42,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: emphasized ? AppTheme.deepBrandGradient : null,
              color: emphasized ? null : AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: emphasized ? AppTheme.electricSapphire : AppTheme.line,
              ),
              boxShadow: emphasized
                  ? [
                      BoxShadow(
                        color: AppTheme.electricSapphire.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              width: emphasized ? 52 : 46,
              height: emphasized ? 52 : 46,
              child: Icon(
                icon,
                color: emphasized
                    ? AppTheme.surface
                    : AppTheme.electricSapphire,
                size: emphasized ? 25 : 22,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProof extends StatelessWidget {
  const _MiniProof({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.blueEnergy, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isRegister, required this.onChanged});

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Entrar',
                selected: !isRegister,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _ModeButton(
                label: 'Crear cuenta',
                selected: isRegister,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Anim.micro,
        curve: Anim.enter,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.electricSapphire.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.electricSapphire : AppTheme.muted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AuthFormCard extends StatefulWidget {
  const _AuthFormCard({
    required this.isRegister,
    required this.isLoading,
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.error,
    this.onBiometricLogin,
  });

  final bool isRegister;
  final bool isLoading;
  final String? error;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback? onBiometricLogin;

  @override
  State<_AuthFormCard> createState() => _AuthFormCardState();
}

class _AuthFormCardState extends State<_AuthFormCard> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricSapphire.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: Anim.micro,
                child: Text(
                  key: ValueKey(widget.isRegister),
                  widget.isRegister
                      ? 'Empieza tu memoria de lugares'
                      : 'Bienvenido de vuelta',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: Anim.micro,
                child: Text(
                  key: ValueKey('sub${widget.isRegister}'),
                  widget.isRegister
                      ? 'Crea una cuenta para guardar planes y decidir en grupo.'
                      : 'Entra para seguir organizando tus lugares pendientes.',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (widget.isRegister) ...[
                AnimatedSize(
                  duration: Anim.micro,
                  curve: Anim.enter,
                  child: widget.isRegister
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: widget.nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
              TextField(
                controller: widget.usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              if (widget.isRegister) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: widget.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (widget.error != null) ...[
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: Anim.micro,
                  opacity: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.errorSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.error!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.isLoading ? null : widget.onSubmit,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.surface,
                        ),
                      )
                    : Icon(
                        widget.isRegister
                            ? Icons.arrow_forward_rounded
                            : Icons.login_rounded,
                      ),
                label: Text(widget.isRegister ? 'Crear cuenta' : 'Entrar'),
              ),
              if (widget.onBiometricLogin != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onBiometricLogin,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Entrar con huella o Face ID'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
