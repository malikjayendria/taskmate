import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final List<String> _selectedMemberIds = [];
  String? _selectedLeaderId;

  @override
  void initState() {
    super.initState();
    context.read<UserViewModel>().startListening();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = context.watch<UserViewModel>().users;

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
              Text(
                'Buat Kelompok',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Kelompok'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama harus diisi';
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
              const SizedBox(height: 16),
              Text(
                'Pilih Anggota',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allUsers.map((user) {
                  final isSelected = _selectedMemberIds.contains(user.uid);
                  return FilterChip(
                    label: Text(user.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMemberIds.add(user.uid);
                        } else {
                          _selectedMemberIds.remove(user.uid);
                          if (_selectedLeaderId == user.uid) {
                            _selectedLeaderId = null;
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLeaderId,
                decoration: const InputDecoration(labelText: 'Ketua Kelompok'),
                items: allUsers
                    .where((u) => _selectedMemberIds.contains(u.uid))
                    .map((u) => DropdownMenuItem(
                          value: u.uid,
                          child: Text(u.displayName),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedLeaderId = value),
                validator: (value) {
                  if (value == null) return 'Pilih ketua kelompok';
                  return null;
                },
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
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final ownerId = context.read<AuthViewModel>().currentUser?.uid;
    if (ownerId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<GroupViewModel>().createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            ownerId: ownerId,
            leaderId: _selectedLeaderId!,
            members: _selectedMemberIds,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat kelompok: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
