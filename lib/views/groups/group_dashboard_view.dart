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
    final isAdmin = authViewModel.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate'),
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
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Kelompok Kamu'),
            ),
            const GroupListView(),
            const Divider(),
            Expanded(
              child: selectedGroupId == null
                  ? const Center(
                      child: Text('Pilih atau buat kelompok terlebih dahulu'),
                    )
                  : const TaskListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'add-group',
                  onPressed: () => _openCreateGroupSheet(context),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Kelompok'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'add-task',
                  onPressed: selectedGroupId == null
                      ? null
                      : () => _openCreateTaskSheet(context, selectedGroupId),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Tugas'),
                ),
              ],
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
      builder: (_) => const SafeArea(child: CreateGroupSheet()),
    );
  }

  Future<void> _openCreateTaskSheet(BuildContext context, String groupId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
}
