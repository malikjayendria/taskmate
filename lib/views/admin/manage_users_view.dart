import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'create_user_sheet.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final currentUser = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: userViewModel.users.isEmpty
            ? const Center(
                child: Text('Belum ada pengguna lain yang terdaftar.'),
              )
            : ListView.separated(
                itemCount: userViewModel.users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = userViewModel.users[index];
                  final isSelf = currentUser?.uid == user.uid;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName.characters.first
                            : '?',
                      ),
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                    trailing: isSelf
                        ? Chip(
                            label: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : _RoleDropdown(user: user),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateUserSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Pengguna'),
      ),
    );
  }

  Future<void> _openCreateUserSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SafeArea(child: CreateUserSheet()),
    );
  }
}

class _RoleDropdown extends StatefulWidget {
  const _RoleDropdown({required this.user});

  final AppUser user;

  @override
  State<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<_RoleDropdown> {
  late String _selectedRole;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return _updating
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : DropdownButton<String>(
            value: _selectedRole,
            onChanged: (value) async {
              if (value == null || value == _selectedRole) return;
              setState(() => _updating = true);
              try {
                await context.read<UserViewModel>().updateRole(
                  widget.user.uid,
                  value,
                );
                setState(() => _selectedRole = value);
              } finally {
                if (mounted) setState(() => _updating = false);
              }
            },
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
          );
  }
}
