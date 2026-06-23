import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF181818),
      body: Center(
        child: Text(
          'Analytics',
          style: TextStyle(color: Colors.white54, fontSize: 24),
        ),
      ),
    );
  }
}