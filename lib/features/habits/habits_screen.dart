import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF181818),
      body: Center(
        child: Text(
          'Habits',
          style: TextStyle(color: Colors.white54, fontSize: 24),
        ),
      ),
    );
  }
}