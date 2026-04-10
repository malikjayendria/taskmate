import 'package:flutter/material.dart';

import 'login_view.dart';

class AuthFlowView extends StatelessWidget {
  const AuthFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primaryContainer, colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TaskMate',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kolaborasi tugas kelompok lebih teratur. '
                        'Hubungi admin untuk mendapatkan akun.',
                      ),
                      SizedBox(height: 32),
                      LoginView(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
