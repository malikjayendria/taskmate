import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 60,
  });

  final EdgeInsetsGeometry padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    final groupViewModel = context.watch<GroupViewModel>();
    final isAdmin = context.watch<AuthViewModel>().isAdmin;

    if (groupViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupViewModel.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Error: ${groupViewModel.errorMessage}',
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (groupViewModel.groups.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada kelompok tersedia.\nHubungi admin untuk menambahkanmu.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemBuilder: (context, index) {
          final group = groupViewModel.groups[index];
          final isSelected = group.id == groupViewModel.selectedGroupId;

          return _GroupPill(
            name: group.name,
            selected: isSelected,
            isAdmin: isAdmin,
            onTap: () => groupViewModel.selectGroup(group.id),
            onLongPress: isAdmin ? () => _showAdminMenu(context, group) : null,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: groupViewModel.groups.length,
      ),
    );
  }

  void _showAdminMenu(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Nama/Deskripsi'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Hapus Kelompok',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, group);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, GroupModel group) async {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Kelompok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Kelompok'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await context.read<GroupViewModel>().updateGroup(
                groupId: group.id,
                name: nameController.text.trim(),
                description: descController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    GroupModel group,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kelompok'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kelompok "${group.name}"? '
          'Semua tugas di dalamnya juga akan terhapus. Akun anggota tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<GroupViewModel>().deleteGroup(group.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _GroupPill extends StatelessWidget {
  const _GroupPill({
    required this.name,
    required this.selected,
    required this.isAdmin,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final bool selected;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : scheme.surface;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? scheme.primary.withOpacity(0.35)
                  : scheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin && selected) ...[
                Icon(Icons.edit, size: 14, color: fg.withOpacity(0.9)),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
