// ── Task Provider ─────────────────────────────────────────────────────────────
// Riverpod state management for tasks.
// This is the single source of truth for the task list in the UI.
// All screens read from here — never directly from the repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/task_model.dart';
import '../../data/task_repository.dart';
import '../../core/ai/category_detector.dart';
import '../../core/ai/priority_detector.dart';
import '../../core/ai/daily_goal_detector.dart';
import 'package:uuid/uuid.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// ── Task list provider ────────────────────────────────────────────────────────
// This is what all screens listen to.
// Any change here automatically rebuilds the UI.

final taskListProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskNotifier(repository);
});

// ── Filtered providers ────────────────────────────────────────────────────────
// Screens use these to get filtered views of the master list.

// All incomplete tasks sorted by priority
final activeTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => !t.isCompleted)
      .toList()
    ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
});

// Tasks due today
final todayTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => t.isDueToday && !t.isCompleted)
      .toList();
});

// Overdue tasks
final overdueTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => t.isOverdue)
      .toList();
});

// Tasks by category
final tasksByCategoryProvider =
    Provider.family<List<Task>, TaskCategory>((ref, category) {
  return ref.watch(taskListProvider)
      .where((t) => t.category == category)
      .toList();
});

// Tasks for a specific date (calendar)
final tasksForDateProvider =
    Provider.family<List<Task>, DateTime>((ref, date) {
  return ref.watch(taskListProvider)
      .where((t) => t.appearsOnDate(date))
      .toList();
});

// Completion stats for top bar (e.g. 3/7)
final todayStatsProvider = Provider<String>((ref) {
  final all = ref.watch(taskListProvider)
      .where((t) => t.isDueToday)
      .toList();
  final done = all.where((t) => t.isCompleted).length;
  return '${done}/${all.length}';
});

// ── Task Notifier ─────────────────────────────────────────────────────────────
// Handles all business logic — add, edit, delete, complete.
// Also runs AI detectors automatically when a task is created/edited.

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;
  final _uuid = const Uuid();

  TaskNotifier(this._repository) : super([]) {
    _loadTasks();
  }

  // Load all tasks from Hive on startup
  void _loadTasks() {
    state = _repository.getAllTasks();
  }

  // ── Add task ──────────────────────────────────────────────────────────────
  // AI runs here automatically — category + priority detected from title
  Future<GoalDetectionResult> addTask({
    required String title,
    String description     = '',
    Priority? priority,
    TaskCategory? category,
    DateTime? deadline,
    DateTime? reminderTime,
    List<TaskLink> links   = const [],
    bool isDailyGoal       = false,
    RecurringFrequency recurringFrequency = RecurringFrequency.none,
  }) async {
    // ── Run AI detectors ──────────────────────────────────────────────────
    final detectedCategory = category ??
        CategoryDetector.detect(title, description: description);

    final detectedPriority = priority ??
        PriorityDetector.detect(title,
            description: description, deadline: deadline);

    final goalResult = DailyGoalDetector.detect(title);

    // ── Build task ────────────────────────────────────────────────────────
    final task = Task(
      id:                 _uuid.v4(),
      title:              title,
      description:        description,
      priority:           detectedPriority,
      category:           detectedCategory,
      deadline:           deadline,
      reminderTime:       reminderTime,
      createdAt:          DateTime.now(),
      links:              links,
      isDailyGoal:        isDailyGoal || goalResult.isGoal,
      recurringFrequency: recurringFrequency,
    );

    await _repository.addTask(task);
    state = _repository.getAllTasks();

    // Return goal detection result so UI can show the prompt
    return goalResult;
  }

  // ── Edit task ─────────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    state = _repository.getAllTasks();
  }

  // ── Delete task ───────────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    state = _repository.getAllTasks();
  }

  // ── Toggle complete ───────────────────────────────────────────────────────
  Future<void> toggleComplete(String id) async {
    await _repository.toggleComplete(id);
    state = _repository.getAllTasks();
  }

  // ── Re-run AI on title change ─────────────────────────────────────────────
  // Called live as user types in the add task form
  // Returns suggested category + priority without saving anything
  Map<String, dynamic> detectFromTitle(String title, {DateTime? deadline}) {
    return {
      'category':    CategoryDetector.detect(title),
      'priority':    PriorityDetector.detect(title, deadline: deadline),
      'goalResult':  DailyGoalDetector.detect(title),
      'categoryConfident': CategoryDetector.isConfident(title),
      'priorityConfident': PriorityDetector.isConfident(title),
    };
  }
}