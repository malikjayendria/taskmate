import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final task = taskViewModel.tasks[index];
        final subtitle = isAdmin
            ? 'PJ: ${task.assigneeName} • ${dateFormat.format(task.deadline)}'
            : dateFormat.format(task.deadline);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          child: ListTile(
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle),
            trailing: isAdmin
                ? PopupMenuButton<String>(
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
                    child: Chip(
                      label: Text(task.status),
                      backgroundColor: _statusColor(task.status, context),
                    ),
                  )
                : Chip(
                    label: Text(task.status),
                    backgroundColor: _statusColor(task.status, context),
                  ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: taskViewModel.tasks.length,
    );
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade100;
      case 'In Progress':
        return Colors.orange.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }
}
