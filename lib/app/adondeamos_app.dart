import 'dart:async';

import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/auth/auth_screen.dart';
import 'package:adondeamos/features/shell/app_shell.dart';
import 'package:adondeamos/shared/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// URL recibida por share-intent pendiente de procesar.
final pendingSharedUrlProvider =
    NotifierProvider<_PendingUrlNotifier, String?>(_PendingUrlNotifier.new);

class _PendingUrlNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? url) => state = url;
  void clear() => state = null;
}

class AdondeamosApp extends ConsumerStatefulWidget {
  const AdondeamosApp({super.key});

  @override
  ConsumerState<AdondeamosApp> createState() => _AdondeamosAppState();
}

class _AdondeamosAppState extends ConsumerState<AdondeamosApp> {
  StreamSubscription? _shareSub;

  @override
  void initState() {
    super.initState();

    // En caliente: app ya abierta cuando llega un share.
    _shareSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia);

    // En frío: app iniciada desde el share sheet.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedMedia(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  void _handleSharedMedia(List<SharedMediaFile> media) {
    for (final file in media) {
      // Los shares de texto/URL llegan como tipo text o url.
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        final url = _extractUrl(file.path);
        if (url != null) {
          ref.read(pendingSharedUrlProvider.notifier).set(url);
          break;
        }
      }
    }
  }

  static final _urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  static String? _extractUrl(String text) {
    final m = _urlRegex.firstMatch(text);
    return m?.group(0);
  }

  @override
  Widget build(BuildContext context) {
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
