import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  static const _statuses = ['To Do', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final isAdmin = context.watch<AuthViewModel>().isAdmin;

    if (taskViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskViewModel.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                isAdmin
                    ? 'Belum ada tugas di kelompok ini.'
                    : 'Tidak ada tugas yang ditugaskan untukmu di kelompok ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final task = taskViewModel.tasks[index];
        final subtitle = isAdmin
            ? 'PJ: ${task.assigneeName} • ${dateFormat.format(task.deadline)}'
            : dateFormat.format(task.deadline);

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    initialValue: task.status,
                    onSelected: (value) =>
                        taskViewModel.updateStatus(task.id, value),
                    itemBuilder: (context) {
                      return _statuses
                          .map(
                            (status) => PopupMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList();
                    },
                    child: _StatusPill(status: task.status),
                  ),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'reassign') {
                          _showReassignDialog(context, task.id, task.groupId);
                        } else if (value == 'delete') {
                          _showDeleteConfirm(context, task.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'reassign',
                          child: ListTile(
                            leading: Icon(Icons.person_add),
                            title: Text('Ganti PJ'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: taskViewModel.tasks.length,
    );
  }

  static _PillColors _statusColors(String status, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'Completed':
        return _PillColors(
          bg: const Color(0xFFE7F6EE),
          fg: const Color(0xFF116B3A),
          border: const Color(0xFFBFE7D0),
        );
      case 'In Progress':
        return _PillColors(
          bg: const Color(0xFFFFF2D9),
          fg: const Color(0xFF7A4A00),
          border: const Color(0xFFFFD89A),
        );
      default:
        return _PillColors(
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurfaceVariant,
          border: scheme.outlineVariant.withOpacity(0.7),
        );
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TaskViewModel>().deleteTask(taskId);
    }
  }

  Future<void> _showReassignDialog(
    BuildContext context,
    String taskId,
    String groupId,
  ) async {
    final userViewModel = context.read<UserViewModel>();
    userViewModel.startListening();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<UserViewModel>(
          builder: (context, vm, child) {
            final users = vm.users;
            return AlertDialog(
              title: const Text('Ganti Penanggung Jawab'),
              content: users.isEmpty
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                user.displayName.trim().isNotEmpty
                                    ? user.displayName.trim().characters.first
                                    : '?',
                              ),
                            ),
                            title: Text(user.displayName),
                            onTap: () => Navigator.pop(context, user),
                          );
                        },
                      ),
                    ),
            );
          },
        );
      },
    ).then((selectedUser) async {
      if (selectedUser is AppUser && context.mounted) {
        final groupViewModel = context.read<GroupViewModel>();
        // Pastikan user ada di grup
        final group = groupViewModel.byId(groupId);
        if (group != null && !group.members.contains(selectedUser.uid)) {
          await groupViewModel.addMember(groupId, selectedUser.uid);
        }

        if (context.mounted) {
          await context.read<TaskViewModel>().updateAssignee(
            taskId,
            selectedUser.uid,
            selectedUser.displayName,
          );
        }
      }
    });
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = TaskListView._statusColors(status, context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: colors.fg,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillColors {
  const _PillColors({required this.bg, required this.fg, required this.border});

  final Color bg;
  final Color fg;
  final Color border;
}
