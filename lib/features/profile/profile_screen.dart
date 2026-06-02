import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/features/groups/groups_screen.dart';
import 'package:adondeamos/features/invitations/invitations_screen.dart';
import 'package:adondeamos/features/lists/lists_screen.dart';
import 'package:adondeamos/features/decisions/decisions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _checkingApi = false;
  bool _apiOk = false;

  void _navigateTo(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).asData?.value;
    final user = auth?.user;
    final httpClient = ref.watch(httpClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          AnimatedListItem(
            index: 0,
            delayMs: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.surface, AppTheme.surfaceBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.violetSoft,
                      child: Text(
                        _initials(user?.name),
                        style: const TextStyle(
                          color: AppTheme.violet,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Usuario',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user?.email ?? 'Sin correo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedListItem(
            index: 1,
            child: _ProfileTile(
              icon: _checkingApi
                  ? Icons.sync_rounded
                  : (_apiOk ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded),
              iconColor: _apiOk ? AppTheme.green : AppTheme.violet,
              title: 'API',
              subtitle: httpClient.baseUrl,
              onTap: () => _checkApi(httpClient),
              trailing: _checkingApi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(index: 2, child: const _SectionLabel(label: 'Social')),
          AnimatedListItem(
            index: 3,
            child: _ProfileTile(
              icon: Icons.groups_rounded,
              title: 'Mis grupos',
              subtitle: 'Crea grupos y colabora con amigos.',
              onTap: () => _navigateTo(context, const GroupsScreen()),
            ),
          ),
          AnimatedListItem(
            index: 4,
            child: _ProfileTile(
              icon: Icons.mail_rounded,
              title: 'Invitaciones',
              subtitle: 'Acepta o rechaza invitaciones a grupos.',
              onTap: () => _navigateTo(context, const InvitationsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(index: 5, child: const _SectionLabel(label: 'Organizar')),
          AnimatedListItem(
            index: 6,
            child: _ProfileTile(
              icon: Icons.list_alt_rounded,
              title: 'Mis listas',
              subtitle: 'Listas personales y grupales de lugares.',
              onTap: () => _navigateTo(context, const ListsScreen()),
            ),
          ),
          AnimatedListItem(
            index: 7,
            child: _ProfileTile(
              icon: Icons.how_to_vote_rounded,
              title: 'Decidir',
              subtitle: 'Inicia una sesión de votación y encuentra el match.',
              onTap: () => _navigateTo(context, const DecisionsScreen()),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedListItem(
            index: 8,
            child: FilledButton.tonalIcon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkApi(HttpApiClient client) async {
    HapticFeedback.lightImpact();
    setState(() {
      _checkingApi = true;
      _apiOk = false;
    });
    try {
      await client.sendJson('GET', '/health');
      setState(() => _apiOk = true);
      _showMessage('API disponible ✓');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('No pude conectar con el API.');
    } finally {
      if (mounted) setState(() => _checkingApi = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? 'A')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts[0].characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              minLeadingWidth: 44,
              leading: CircleAvatar(
                backgroundColor: AppTheme.violetSoft,
                child: Icon(icon, color: iconColor ?? AppTheme.violet),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
              trailing: trailing ??
                  (onTap != null
                      ? const Icon(Icons.chevron_right_rounded, color: AppTheme.muted)
                      : null),
            ),
          ),
        ),
      ),
    );
  }
}
