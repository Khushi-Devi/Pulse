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

// ── Task list notifier ────────────────────────────────────────────────────────
class TaskNotifier extends Notifier<List<Task>> {
  final _uuid = const Uuid();

  @override
  List<Task> build() {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.getAllTasks();
  }

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  // ── Add task ────────────────────────────────────────────────────────────
  Future<GoalDetectionResult> addTask({
    required String title,
    String description = '',
    Priority? priority,
    TaskCategory? category,
    DateTime? deadline,
    DateTime? reminderTime,
    List<TaskLink> links = const [],
    bool isDailyGoal = false,
    RecurringFrequency recurringFrequency = RecurringFrequency.none,
  }) async {
    final detectedCategory = category ??
        CategoryDetector.detect(title, description: description);

    final detectedPriority = priority ??
        PriorityDetector.detect(title,
            description: description, deadline: deadline);

    final goalResult = DailyGoalDetector.detect(title);

    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: detectedPriority,
      category: detectedCategory,
      deadline: deadline,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
      links: links,
      isDailyGoal: isDailyGoal || goalResult.isGoal,
      recurringFrequency: recurringFrequency,
    );

    await _repository.addTask(task);
    state = _repository.getAllTasks();

    return goalResult;
  }

  // ── Update task ──────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    state = _repository.getAllTasks();
  }

  // ── Delete task ──────────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    state = _repository.getAllTasks();
  }

  // ── Toggle complete ──────────────────────────────────────────────────────
  Future<void> toggleComplete(String id) async {
    await _repository.toggleComplete(id);
    state = _repository.getAllTasks();
  }

  // ── Live AI detection (while typing) ────────────────────────────────────
  Map<String, dynamic> detectFromTitle(String title, {DateTime? deadline}) {
    return {
      'category': CategoryDetector.detect(title),
      'priority': PriorityDetector.detect(title, deadline: deadline),
      'goalResult': DailyGoalDetector.detect(title),
      'categoryConfident': CategoryDetector.isConfident(title),
      'priorityConfident': PriorityDetector.isConfident(title),
    };
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final taskListProvider = NotifierProvider<TaskNotifier, List<Task>>(() {
  return TaskNotifier();
});

final activeTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => !t.isCompleted)
      .toList()
    ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
});

final todayTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => t.isDueToday && !t.isCompleted)
      .toList();
});

final overdueTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskListProvider)
      .where((t) => t.isOverdue)
      .toList();
});

final tasksByCategoryProvider =
    Provider.family<List<Task>, TaskCategory>((ref, category) {
  return ref.watch(taskListProvider)
      .where((t) => t.category == category)
      .toList();
});

final tasksForDateProvider =
    Provider.family<List<Task>, DateTime>((ref, date) {
  return ref.watch(taskListProvider)
      .where((t) => t.appearsOnDate(date))
      .toList();
});

final todayStatsProvider = Provider<String>((ref) {
  final all = ref.watch(taskListProvider)
      .where((t) => t.isDueToday)
      .toList();
  final done = all.where((t) => t.isCompleted).length;
  return '$done/${all.length}';
});