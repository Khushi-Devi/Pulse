import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF181818),
      body: Center(
        child: Text(
          'Tasks',
          style: TextStyle(color: Colors.white54, fontSize: 24),
        ),
      ),
    );
  }
}