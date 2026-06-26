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
  await Hive.initFlutter();
  await TaskRepository.init();
  runApp(const ProviderScope(child: PulseApp()));
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
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1C1C1E),
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

  // ── Nav items ─────────────────────────────────────────────────────────────
  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.grid_view_rounded,      label: 'Today'),
    _NavItem(icon: Icons.track_changes_rounded,  label: 'Goals'),
    _NavItem(icon: Icons.timer_outlined,         label: 'Focus'),
    _NavItem(icon: Icons.bar_chart_rounded,      label: 'Stats'),
  ];

  void _onFabPressed() {
    debugPrint('FAB pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      // ── Top bar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // 🔥 Streak
            _TopPill(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFF97316),
              value: '0',
            ),
            const SizedBox(width: 6),
            // ✅ Tasks done
            _TopPill(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF10B981),
              value: '0/0',
            ),
            const SizedBox(width: 6),
            // ⚡ Focus score
            _TopPill(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFFACC15),
              value: '0',
            ),
          ],
        ),
        actions: [
          // Gradient initials avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFACC15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'KD',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _screens[_currentIndex],

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6, right: 2),
        child: FloatingActionButton.small(
          onPressed: _onFabPressed,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
        ),
      ),

      // ── Bottom nav ────────────────────────────────────────────────────────
      bottomNavigationBar: _PulseBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Top pill widget ───────────────────────────────────────────────────────────
class _TopPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _TopPill({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Bottom nav widget ─────────────────────────────────────────────────────────
class _PulseBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _PulseBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(
          top: BorderSide(color: Color(0xFF222222), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: active
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: active
                    ? BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 0.5,
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      size: 22,
                      color: active ? Colors.white : const Color(0xFF444444),
                    ),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Text(
                        items[i].label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}