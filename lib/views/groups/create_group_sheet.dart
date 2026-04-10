import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
