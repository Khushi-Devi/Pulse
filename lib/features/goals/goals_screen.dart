import 'package:flutter/material.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF181818),
      body: Center(
        child: Text(
          'Daily Goals',
          style: TextStyle(color: Colors.white54, fontSize: 24),
        ),
      ),
    );
  }
}