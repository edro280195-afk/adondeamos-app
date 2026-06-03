import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/animation_constants.dart';
import 'package:adondeamos/features/capture/capture_screen.dart';
import 'package:adondeamos/features/home/home_screen.dart';
import 'package:adondeamos/features/profile/profile_screen.dart';
import 'package:adondeamos/features/saves/saves_screen.dart';
import 'package:adondeamos/shared/widgets/pulse_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _previousIndex = 0;

  static const _screens = [
    HomeScreen(),
    CaptureScreen(),
    SavesScreen(),
    ProfileScreen(),
  ];

  void _onTabChanged(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final direction = _index > _previousIndex ? 1.0 : -1.0;
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(direction * 0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: _screens[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabChanged,
        animationDuration: Anim.micro,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: _AddDestinationIcon(
              key: const ValueKey('nav_add'),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            selectedIcon: _AddDestinationIcon(
              key: const ValueKey('nav_add_sel'),
              selected: true,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            label: 'Guardar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Guardados',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _AddDestinationIcon extends StatelessWidget {
  const _AddDestinationIcon({
    super.key,
    this.selected = false,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: selected
              ? const [AppTheme.blueEnergy, AppTheme.electricSapphire]
              : const [AppTheme.babyBlueIce, AppTheme.blueEnergy],
        ),
        boxShadow: [
          BoxShadow(
            color: (selected ? AppTheme.electricSapphire : AppTheme.blueEnergy)
                .withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    return PulseIcon(enabled: !selected, child: iconWidget);
  }
}
