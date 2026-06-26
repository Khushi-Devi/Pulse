// ── Task Model ────────────────────────────────────────────────────────────────
// Single source of truth for all task data in Pulse.
// All screens read from and write to this model.
// v1: stored in Hive local database.

import 'package:flutter/foundation.dart';

// ── Priority levels ───────────────────────────────────────────────────────────
enum Priority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case Priority.low:    return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high:   return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case Priority.low:    return '⚫';
      case Priority.medium: return '🔵';
      case Priority.high:   return '🟠';
      case Priority.urgent: return '🔴';
    }
  }
}

// ── Task categories ───────────────────────────────────────────────────────────
enum TaskCategory {
  general,
  study,
  work,
  health,
  coding,
  shopping,
  finance,
  personal;

  String get label {
    switch (this) {
      case TaskCategory.general:  return 'General';
      case TaskCategory.study:    return 'Study';
      case TaskCategory.work:     return 'Work';
      case TaskCategory.health:   return 'Health';
      case TaskCategory.coding:   return 'Coding';
      case TaskCategory.shopping: return 'Shopping';
      case TaskCategory.finance:  return 'Finance';
      case TaskCategory.personal: return 'Personal';
    }
  }

  String get emoji {
    switch (this) {
      case TaskCategory.general:  return '📌';
      case TaskCategory.study:    return '📚';
      case TaskCategory.work:     return '💼';
      case TaskCategory.health:   return '🏃';
      case TaskCategory.coding:   return '💻';
      case TaskCategory.shopping: return '🛒';
      case TaskCategory.finance:  return '💰';
      case TaskCategory.personal: return '👤';
    }
  }
}

// ── Recurring frequency ───────────────────────────────────────────────────────
enum RecurringFrequency {
  none,
  daily,
  weekdays,   // Monday to Friday only
  weekly,
  custom;

  String get label {
    switch (this) {
      case RecurringFrequency.none:     return 'None';
      case RecurringFrequency.daily:    return 'Every day';
      case RecurringFrequency.weekdays: return 'Weekdays only';
      case RecurringFrequency.weekly:   return 'Every week';
      case RecurringFrequency.custom:   return 'Custom';
    }
  }
}

// ── Task link (resource links feature) ───────────────────────────────────────
class TaskLink {
  final String label;
  final String url;

  const TaskLink({
    required this.label,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'url':   url,
  };

  factory TaskLink.fromMap(Map<String, dynamic> map) => TaskLink(
    label: map['label'] ?? '',
    url:   map['url']   ?? '',
  );
}

// ── Task model ────────────────────────────────────────────────────────────────
class Task {
  final String             id;
  final String             title;
  final String             description;
  final Priority           priority;
  final TaskCategory       category;
  final DateTime?          deadline;
  final DateTime?          reminderTime;      // ← NEW: when to notify
  final bool               isCompleted;
  final DateTime           createdAt;
  final List<TaskLink>     links;
  final bool               isDailyGoal;       // ← NEW: is this a daily goal?
  final RecurringFrequency recurringFrequency; // ← NEW: how often it repeats

  const Task({
    required this.id,
    required this.title,
    this.description        = '',
    this.priority           = Priority.medium,
    this.category           = TaskCategory.general,
    this.deadline,
    this.reminderTime,
    this.isCompleted        = false,
    required this.createdAt,
    this.links              = const [],
    this.isDailyGoal        = false,
    this.recurringFrequency = RecurringFrequency.none,
  });

  // ── Is this task due today? ───────────────────────────────────────────────
  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year  == now.year  &&
           deadline!.month == now.month &&
           deadline!.day   == now.day;
  }

  // ── Is this task overdue? ─────────────────────────────────────────────────
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return deadline!.isBefore(DateTime.now());
  }

  // ── Should this task appear on a given calendar date? ────────────────────
  bool appearsOnDate(DateTime date) {
    // Daily goal → appears every day
    if (isDailyGoal ||
        recurringFrequency == RecurringFrequency.daily) {
      return true;
    }

    // Weekdays only
    if (recurringFrequency == RecurringFrequency.weekdays) {
      return date.weekday >= 1 && date.weekday <= 5;
    }

    // Weekly → appears on same weekday as creation
    if (recurringFrequency == RecurringFrequency.weekly) {
      return date.weekday == createdAt.weekday;
    }

    // One-off task → only appears on its deadline date
    if (deadline != null) {
      return deadline!.year  == date.year  &&
             deadline!.month == date.month &&
             deadline!.day   == date.day;
    }

    return false;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  Task copyWith({
    String?             id,
    String?             title,
    String?             description,
    Priority?           priority,
    TaskCategory?       category,
    DateTime?           deadline,
    DateTime?           reminderTime,
    bool?               isCompleted,
    DateTime?           createdAt,
    List<TaskLink>?     links,
    bool?               isDailyGoal,
    RecurringFrequency? recurringFrequency,
  }) {
    return Task(
      id:                 id                 ?? this.id,
      title:              title              ?? this.title,
      description:        description        ?? this.description,
      priority:           priority           ?? this.priority,
      category:           category           ?? this.category,
      deadline:           deadline           ?? this.deadline,
      reminderTime:       reminderTime       ?? this.reminderTime,
      isCompleted:        isCompleted        ?? this.isCompleted,
      createdAt:          createdAt          ?? this.createdAt,
      links:              links              ?? this.links,
      isDailyGoal:        isDailyGoal        ?? this.isDailyGoal,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }

  // ── toMap / fromMap ───────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':                 id,
    'title':              title,
    'description':        description,
    'priority':           priority.index,
    'category':           category.index,
    'deadline':           deadline?.toIso8601String(),
    'reminderTime':       reminderTime?.toIso8601String(),
    'isCompleted':        isCompleted,
    'createdAt':          createdAt.toIso8601String(),
    'links':              links.map((l) => l.toMap()).toList(),
    'isDailyGoal':        isDailyGoal,
    'recurringFrequency': recurringFrequency.index,
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id:                 map['id']          ?? '',
    title:              map['title']       ?? '',
    description:        map['description'] ?? '',
    priority:           Priority.values[map['priority'] ?? 1],
    category:           TaskCategory.values[map['category'] ?? 0],
    deadline:           map['deadline']    != null
                          ? DateTime.parse(map['deadline'])
                          : null,
    reminderTime:       map['reminderTime'] != null
                          ? DateTime.parse(map['reminderTime'])
                          : null,
    isCompleted:        map['isCompleted']  ?? false,
    createdAt:          DateTime.parse(map['createdAt']),
    links:              (map['links'] as List<dynamic>? ?? [])
                          .map((l) => TaskLink.fromMap(l))
                          .toList(),
    isDailyGoal:        map['isDailyGoal']        ?? false,
    recurringFrequency: RecurringFrequency.values[
                          map['recurringFrequency'] ?? 0],
  );
}