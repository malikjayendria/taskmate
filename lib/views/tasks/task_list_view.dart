import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/task_models.dart';
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
    final groupViewModel = context.watch<GroupViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    
    final selectedGroup = groupViewModel.selectedGroup;
    final isAdmin = authViewModel.isAdmin;
    final currentUser = authViewModel.currentUser;

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

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final task = taskViewModel.tasks[index];
        final isPJ = task.assigneeId == currentUser?.uid;
        final isLeader = selectedGroup?.leaderId == currentUser?.uid;
        final canUpdateStatus = isAdmin || isLeader || isPJ;
        
        final subtitleWidget = Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'PJ: ${task.assigneeName} • '),
              TextSpan(
                text: dateFormat.format(task.deadline),
                style: TextStyle(
                  color: task.isOverdue ? Colors.red : null,
                  fontWeight: task.isOverdue ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        );

        return Card(
          child: ExpansionTile(
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: subtitleWidget,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isOverdue) ...[
                  const _OverduePill(),
                  const SizedBox(width: 8),
                ],
                PopupMenuButton<String>(
                  enabled: canUpdateStatus,
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
                if (isAdmin || isLeader)
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description.isNotEmpty) ...[
                      const Text(
                        'Deskripsi:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(task.description),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catatan Progress:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddNoteDialog(context, task.id),
                          icon: const Icon(Icons.add_comment, size: 18),
                          label: const Text('Tambah Catatan'),
                        ),
                      ],
                    ),
                    if (task.notes.isEmpty)
                      const Text(
                        'Belum ada catatan.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      )
                    else
                      ...task.notes.map((note) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  note.createdByName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM HH:mm').format(note.createdAt),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(note.text),
                            const Divider(height: 8),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ],
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
    final groupViewModel = context.read<GroupViewModel>();
    final group = groupViewModel.byId(groupId);
    userViewModel.startListening();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<UserViewModel>(
          builder: (context, vm, child) {
            final members = vm.users.where((u) => group?.members.contains(u.uid) ?? false).toList();
            return AlertDialog(
              title: const Text('Ganti Penanggung Jawab'),
              content: members.isEmpty
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final user = members[index];
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
        await context.read<TaskViewModel>().updateAssignee(
          taskId,
          selectedUser.uid,
          selectedUser.displayName,
        );
      }
    });
  }

  Future<void> _showAddNoteDialog(BuildContext context, String taskId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Catatan Progress'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan catatan...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      if (currentUser == null) return;

      final note = TaskNote(
        text: controller.text.trim(),
        createdBy: currentUser.uid,
        createdByName: currentUser.displayName,
        createdAt: DateTime.now(),
      );

      await context.read<TaskViewModel>().addTaskNote(taskId, note);
    }
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

class _OverduePill extends StatelessWidget {
  const _OverduePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFF991B1B)),
          SizedBox(width: 4),
          Text(
            'Overdue',
            style: TextStyle(
              color: Color(0xFF991B1B),
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
