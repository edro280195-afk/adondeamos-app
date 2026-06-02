import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/features/groups/groups_controller.dart';
import 'package:adondeamos/shared/models/group_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(groupDetailProvider(groupId));

    return detail.when(
      data: (group) => _GroupDetailBody(group: group),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ),
    );
  }
}

class _GroupDetailBody extends ConsumerWidget {
  const _GroupDetailBody({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                group.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.deepBrandGradient),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                onPressed: () => _showInviteDialog(context, ref),
                tooltip: 'Invitar',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${group.members.length} ${group.members.length == 1 ? 'miembro' : 'miembros'}',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...group.members.map((m) => _MemberTile(member: m)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Invitar'),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar al grupo'),
        content: TextField(
          controller: emailCtrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo del invitado',
            hintText: 'correo@ejemplo.com',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _invite(ctx, ref, emailCtrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _invite(ctx, ref, emailCtrl.text),
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext ctx, WidgetRef ref, String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.pop(ctx);
    try {
      await ref.read(groupsProvider.notifier).inviteMember(
            groupId: group.id,
            email: trimmed,
          );
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Invitación enviada.')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'owner';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: isOwner ? AppTheme.violetSoft : const Color(0xFFEDF7F2),
            child: Text(
              member.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: isOwner ? AppTheme.violet : AppTheme.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(member.email),
          trailing: DecoratedBox(
            decoration: BoxDecoration(
              color: isOwner ? AppTheme.violetSoft : const Color(0xFFEDF7F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                isOwner ? 'Creador' : 'Miembro',
                style: TextStyle(
                  color: isOwner ? AppTheme.violet : AppTheme.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
