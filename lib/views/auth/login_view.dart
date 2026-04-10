import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masuk ke akunmu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
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
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: authViewModel.isBusy ? null : () => _submit(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: authViewModel.isBusy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Masuk'),
          ),
          if (authViewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              authViewModel.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Belum punya akun? Hubungi admin agar dibuatkan akun baru.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal login, silakan coba lagi')),
      );
    }
  }
}
