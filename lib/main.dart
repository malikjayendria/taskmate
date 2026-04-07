import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Menghubungkan ke inti Firebase
import 'firebase_options.dart'; // File konfigurasi yang tadi kita buat
import 'views/task_list_view.dart'; // Halaman daftar tugas yang kita buat sebelumnya

void main() async {
  // 1. Pastikan semua komponen Flutter siap sebelum menjalankan Firebase
  WidgetsFlutterBinding.ensureInitialized(); 

  // 2. Inisialisasi Firebase menggunakan konfigurasi otomatis
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMate - Tugas Kelompok',
      debugShowCheckedModeBanner: false, // Menghilangkan pita debug di pojok kanan
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Menggunakan desain terbaru dari Google
      ),
      // 3. Menetapkan TaskListView sebagai halaman pertama (Home)
      home: TaskListView(), 
    );
  }
}