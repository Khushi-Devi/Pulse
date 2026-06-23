import 'package:flutter/material.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF181818),
      body: Center(
        child: Text(
          'Focus',
          style: TextStyle(color: Colors.white54, fontSize: 24),
        ),
      ),
    );
  }
}