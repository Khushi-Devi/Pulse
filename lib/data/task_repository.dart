// ── Task Repository ───────────────────────────────────────────────────────────
// All read/write operations for tasks.
// v1: Hive local storage (offline first).
// v2: will add Firebase Firestore sync on top.

import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';

class TaskRepository {
  static const String _boxName = 'tasks';

  // ── Open the Hive box ─────────────────────────────────────────────────────
  // Call this once at app startup in main.dart
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  // ── Create ────────────────────────────────────────────────────────────────
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  // ── Read all ──────────────────────────────────────────────────────────────
  List<Task> getAllTasks() {
    return _box.values
        .map((map) => Task.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  // ── Read single ───────────────────────────────────────────────────────────
  Task? getTask(String id) {
    final map = _box.get(id);
    if (map == null) return null;
    return Task.fromMap(Map<String, dynamic>.from(map));
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  // ── Mark complete / incomplete ────────────────────────────────────────────
  Future<void> toggleComplete(String id) async {
    final task = getTask(id);
    if (task == null) return;
    await updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  // ── Get tasks by category ─────────────────────────────────────────────────
  List<Task> getByCategory(TaskCategory category) {
    return getAllTasks()
        .where((t) => t.category == category)
        .toList();
  }

  // ── Get tasks due today ───────────────────────────────────────────────────
  List<Task> getDueToday() {
    return getAllTasks()
        .where((t) => t.isDueToday && !t.isCompleted)
        .toList();
  }

  // ── Get overdue tasks ─────────────────────────────────────────────────────
  List<Task> getOverdue() {
    return getAllTasks()
        .where((t) => t.isOverdue)
        .toList();
  }

  // ── Get tasks for a specific date (calendar) ──────────────────────────────
  List<Task> getTasksForDate(DateTime date) {
    return getAllTasks()
        .where((t) => t.appearsOnDate(date))
        .toList();
  }

  // ── Get incomplete tasks sorted by priority ───────────────────────────────
  List<Task> getActiveSortedByPriority() {
    final tasks = getAllTasks()
        .where((t) => !t.isCompleted)
        .toList();

    tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return tasks;
  }

  // ── Clear all (for testing/reset) ─────────────────────────────────────────
  Future<void> clearAll() async {
    await _box.clear();
  }
}