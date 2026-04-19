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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoleDropdown(user: user),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditNameDialog(context, user);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(context, user);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit Nama'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Hapus User', style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Future<void> _showEditNameDialog(BuildContext context, AppUser user) async {
    final controller = TextEditingController(text: user.displayName);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Pengguna'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await context.read<UserViewModel>().updateDisplayName(
                      user.uid,
                      controller.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama berhasil diperbarui')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui nama: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, AppUser user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Apakah Anda yakin ingin menghapus ${user.displayName}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<UserViewModel>().deleteUser(user.uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateUserSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
