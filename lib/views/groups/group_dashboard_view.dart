import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../tasks/task_list_view.dart';
import 'create_group_sheet.dart';
import 'group_list_view.dart';
import '../tasks/create_task_sheet.dart';
import '../admin/manage_users_view.dart';

class GroupDashboardView extends StatelessWidget {
  const GroupDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final groupViewModel = context.watch<GroupViewModel>();

    final selectedGroupId = groupViewModel.selectedGroupId;
    final selectedGroup = groupViewModel.selectedGroup;
    final isAdmin = authViewModel.isAdmin;
    final user = authViewModel.currentUser;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 170,
                forceElevated: innerBoxIsScrolled,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 12,
                    end: 16,
                  ),
                  title: const Text('TaskMate'),
                  background: _DashboardHeader(
                    displayName: (user?.displayName ?? '').trim().isEmpty
                        ? 'Halo'
                        : user!.displayName,
                    email: user?.email ?? '',
                    groupName: selectedGroup?.name,
                    isAdmin: isAdmin,
                  ),
                ),
                actions: [
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.manage_accounts),
                      tooltip: 'Kelola Pengguna',
                      onPressed: () => _openManageUsers(context),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: authViewModel.signOut,
                    tooltip: 'Keluar',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Kelompok',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isAdmin)
                                TextButton.icon(
                                  onPressed: () =>
                                      _openCreateGroupSheet(context),
                                  icon: const Icon(Icons.group_add, size: 18),
                                  label: const Text('Buat'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const GroupListView(
                            padding: EdgeInsets.zero,
                            height: 54,
                          ),
                          if (selectedGroup != null) ...[
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: selectedGroup.description.trim().isEmpty
                                  ? const SizedBox.shrink()
                                  : Text(
                                      selectedGroup.description,
                                      key: ValueKey(selectedGroup.id),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tugas',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isAdmin)
                        FilledButton.icon(
                          onPressed: selectedGroupId == null
                              ? null
                              : () => _openCreateTaskSheet(
                                  context,
                                  selectedGroupId,
                                ),
                          icon: const Icon(Icons.add_task, size: 18),
                          label: const Text('Tambah'),
                        ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: selectedGroupId == null
                ? _EmptyDashboardState(
                    key: const ValueKey('empty'),
                    isAdmin: isAdmin,
                  )
                : const TaskListView(key: ValueKey('tasks')),
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'quick-actions',
              onPressed: () =>
                  _openQuickActions(context, selectedGroupId: selectedGroupId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _openManageUsers(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManageUsersView()));
  }

  Future<void> _openCreateGroupSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SafeArea(child: CreateGroupSheet()),
    );
  }

  Future<void> _openCreateTaskSheet(BuildContext context, String groupId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreateTaskSheet(groupId: groupId),
        ),
      ),
    );
  }

  Future<void> _openQuickActions(
    BuildContext context, {
    required String? selectedGroupId,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Buat Kelompok'),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateGroupSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_task),
                title: const Text('Buat Tugas'),
                subtitle: selectedGroupId == null
                    ? const Text('Pilih kelompok terlebih dahulu')
                    : null,
                enabled: selectedGroupId != null,
                onTap: selectedGroupId == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _openCreateTaskSheet(context, selectedGroupId);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.displayName,
    required this.email,
    required this.groupName,
    required this.isAdmin,
  });

  final String displayName;
  final String email;
  final String? groupName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headline = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: scheme.onPrimary,
      letterSpacing: -0.6,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.primaryContainer],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: _GlowBlob(color: scheme.tertiary.withOpacity(0.25), size: 160),
        ),
        Positioned(
          bottom: -45,
          left: -20,
          child: _GlowBlob(
            color: scheme.secondary.withOpacity(0.20),
            size: 180,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat datang', style: TextStyle(color: scheme.onPrimary)),
              const SizedBox(height: 6),
              Text(displayName, style: headline, maxLines: 1),
              if (email.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  style: TextStyle(color: scheme.onPrimary.withOpacity(0.9)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: scheme.onPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      groupName ?? 'Belum pilih kelompok',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: scheme.onPrimary.withOpacity(0.20),
                        ),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 60, spreadRadius: 10),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.layers, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pilih kelompok untuk mulai',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Kamu bisa membuat kelompok baru atau memilih salah satu kelompok yang sudah ada.'
                      : 'Pilih kelompok yang tersedia, lalu daftar tugas akan muncul di sini.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
