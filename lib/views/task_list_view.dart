import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../services/database_services.dart';

class TaskListView extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tugas Kelompok')),
      body: StreamBuilder<List<TaskModel>>(
        stream: _dbService.getTasks(), // Mengambil data real-time dari Firestore
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan'));
          if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();

          final tasks = snapshot.data ?? [];

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title), // Nama Tugas [cite: 74]
                subtitle: Text('PJ: ${task.assignedTo} | Status: ${task.status}'), // Detail [cite: 75, 76]
                trailing: Text('${task.deadline.day}/${task.deadline.month}'), // Deadline [cite: 77]
                onTap: () {
                  // Fitur 5: Update Status Tugas [cite: 78, 79]
                  _dbService.updateTaskStatus(task.id, 'Completed');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Contoh menambah tugas baru secara manual untuk testing [cite: 66, 68]
          _dbService.addTask(TaskModel(
            id: '',
            title: 'Mengerjakan Laporan Tubes',
            assignedTo: 'Malik',
            status: 'To Do',
            deadline: DateTime.now().add(Duration(days: 7)),
          ));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}