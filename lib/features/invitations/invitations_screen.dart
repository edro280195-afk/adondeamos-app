import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/shimmer_box.dart';
import 'package:adondeamos/features/groups/groups_screen.dart';
import 'package:adondeamos/features/invitations/invitations_controller.dart';
import 'package:adondeamos/shared/models/invitation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones')),
      body: invitations.when(
        data: (items) {
          final pending = items.where((i) => i.isPending).toList();
          if (pending.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 64, color: AppTheme.violetSoft),
                    SizedBox(height: 16),
                    Text(
                      'Sin invitaciones pendientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando alguien te invite a un grupo\naparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: pending.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index < pending.length - 1 ? 10 : 0),
                child: _InvitationTile(invitation: pending[index]),
              );
            },
          );
        },
        loading: () => const _InvitationsLoading(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.muted),
              const SizedBox(height: 12),
              Text(error.toString(), style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(invitationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GroupsScreen()),
        ),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.groups_rounded),
        label: const Text('Ver mis grupos'),
      ),
    );
  }
}

class _InvitationsLoading extends StatelessWidget {
  const _InvitationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ShimmerCard(height: 140),
    );
  }
}

class _InvitationTile extends ConsumerWidget {
  const _InvitationTile({required this.invitation});

  final Invitation invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.violetSoft, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.violetSoft,
                  child: Icon(Icons.groups_rounded, color: AppTheme.violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.groupName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        'Invitado por ${invitation.invitedBy}',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, ref, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, ref, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.green,
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, bool accept) async {
    HapticFeedback.mediumImpact();
    try {
      if (accept) {
        await ref.read(invitationsProvider.notifier).accept(invitation.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Te uniste a ${invitation.groupName}.')),
          );
        }
      } else {
        await ref.read(invitationsProvider.notifier).reject(invitation.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
