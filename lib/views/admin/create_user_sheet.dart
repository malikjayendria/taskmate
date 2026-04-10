import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

class CreateUserSheet extends StatefulWidget {
  const CreateUserSheet({super.key});

  @override
  State<CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'user';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pengguna Baru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!value.contains('@')) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password sementara',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'user'),
              decoration: const InputDecoration(labelText: 'Peran'),
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
                  : const Text('Buat Akun'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan: bagikan password sementara kepada pengguna. '
              'Mereka bisa menggantinya di halaman profil (fitur mendatang).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final success = await context.read<AuthViewModel>().adminCreateUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        role: _role,
      );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna berhasil dibuat')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuat akun')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
