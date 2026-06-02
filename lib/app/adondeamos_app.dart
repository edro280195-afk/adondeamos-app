import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/auth/auth_screen.dart';
import 'package:adondeamos/features/shell/app_shell.dart';
import 'package:adondeamos/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdondeamosApp extends ConsumerWidget {
  const AdondeamosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Adondeamos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: auth.when(
        data: (state) =>
            state.isSignedIn ? const AppShell() : const AuthScreen(),
        loading: () => const _SplashScreen(),
        error: (error, _) => AuthScreen(initialError: error.toString()),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 82),
            SizedBox(height: 18),
            Text(
              'Adondeamos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
