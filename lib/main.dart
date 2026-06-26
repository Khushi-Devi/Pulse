import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/focus/focus_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'data/task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Init Hive ─────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  await TaskRepository.init();

  runApp(
    // ── Wrap with Riverpod ──────────────────────────────────────────────────
    const ProviderScope(
      child: PulseApp(),
    ),
  );
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181818),
        colorScheme: const ColorScheme.dark(
          background: Color(0xFF181818),
          surface: Color(0xFF252525),
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      home: const PulseHome(),
    );
  }
}

class PulseHome extends StatefulWidget {
  const PulseHome({super.key});

  @override
  State<PulseHome> createState() => _PulseHomeState();
}

class _PulseHomeState extends State<PulseHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TasksScreen(),
    GoalsScreen(),
    FocusScreen(),
    AnalyticsScreen(),
  ];

  void _onFabPressed() {
    debugPrint('FAB pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 15, color: Color(0xFFF97316)),
                  SizedBox(width: 4),
                  Text('0',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 15, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('0/0',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, size: 15, color: Color(0xFFFACC15)),
                  SizedBox(width: 4),
                  Text('0',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF252525),
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: FloatingActionButton.small(
          onPressed: _onFabPressed,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.black, size: 20),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF2A2A2A),
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined, color: Color(0xFF555555)),
            selectedIcon: Icon(Icons.today, color: Colors.white),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined, color: Color(0xFF555555)),
            selectedIcon: Icon(Icons.flag, color: Colors.white),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, color: Color(0xFF555555)),
            selectedIcon: Icon(Icons.timer, color: Colors.white),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Color(0xFF555555)),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}