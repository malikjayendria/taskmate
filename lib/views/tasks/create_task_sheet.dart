import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  String? _assigneeId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupViewModel = context.watch<GroupViewModel>();
    final group = groupViewModel.byId(widget.groupId);
    final userViewModel = context.watch<UserViewModel>();
    
    // Only show members of this group
    final members = userViewModel.users.where((u) => group?.members.contains(u.uid) ?? false).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
              DropdownButtonFormField<String>(
                value: _assigneeId,
                decoration: const InputDecoration(
                  labelText: 'Penanggung Jawab (PJ)',
                ),
                items: members
                    .map(
                      (member) => DropdownMenuItem(
                        value: member.uid,
                        child: Text(member.displayName),
                      ),
                    )
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih penanggung jawab';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _assigneeId = value),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Deadline'),
                subtitle: Text(
                  '${_deadline.day}/${_deadline.month}/${_deadline.year} ${_deadline.hour}:${_deadline.minute}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDeadline,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : () => _submit(context),
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
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
      );

      if (time != null) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authViewModel = context.read<AuthViewModel>();
    final userViewModel = context.read<UserViewModel>();
    final creatorId = authViewModel.currentUser?.uid;
    if (creatorId == null) return;
    if (_assigneeId == null) return;

    final assignee = userViewModel.users.firstWhere((u) => u.uid == _assigneeId);

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat tugas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
