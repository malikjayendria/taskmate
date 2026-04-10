import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/task_models.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key, required this.groupId});

  final String groupId;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;
  bool _isLoadingMembers = true;
  List<AppUser> _members = [];
  String? _assigneeId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  Future<void> _loadMembers() async {
    final group = context.read<GroupViewModel>().byId(widget.groupId);
    if (group == null) {
      setState(() {
        _isLoadingMembers = false;
      });
      return;
    }

    final members = await context.read<UserViewModel>().fetchUsersByIds(
      group.members,
    );
    setState(() {
      _members = members;
      _assigneeId = members.isNotEmpty ? members.first.uid : null;
      _isLoadingMembers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tugas Baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Tugas'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _assigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Penanggung Jawab',
                    ),
                    items: _members
                        .map(
                          (member) => DropdownMenuItem(
                            value: member.uid,
                            child: Text(member.displayName),
                          ),
                        )
                        .toList(),
                    validator: (value) {
                      if (_members.isEmpty) {
                        return 'Belum ada anggota yang dapat dipilih';
                      }
                      if (value == null || value.isEmpty) {
                        return 'Pilih penanggung jawab';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() => _assigneeId = value),
                  ),
            if (!_isLoadingMembers && _members.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Tidak ada anggota pada kelompok ini. Tambahkan anggota '
                'sebelum membuat tugas.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text(
                '${_deadline.day}/${_deadline.month}/${_deadline.year}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDeadline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting || _members.isEmpty
                  ? null
                  : () => _submit(context),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _deadline = selected);
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final creatorId = context.read<AuthViewModel>().currentUser?.uid;
    if (creatorId == null) return;
    if (_assigneeId == null) return;

    final assignee = _members.firstWhere(
      (member) => member.uid == _assigneeId,
      orElse: () => AppUser(
        uid: _assigneeId!,
        email: '',
        displayName: 'Tidak diketahui',
        photoUrl: null,
        groupIds: const [],
        role: 'user',
        createdAt: DateTime.now(),
      ),
    );

    setState(() => _isSubmitting = true);
    try {
      final task = TaskModel(
        id: '',
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeId: assignee.uid,
        assigneeName: assignee.displayName,
        status: 'To Do',
        deadline: _deadline,
        createdBy: creatorId,
        createdAt: DateTime.now(),
      );

      await context.read<TaskViewModel>().createTask(task);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
