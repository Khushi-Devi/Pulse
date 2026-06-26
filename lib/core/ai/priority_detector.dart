// ── Smart Priority Detector ───────────────────────────────────────────────────
// Reads task title and suggests a priority level.
// Works alongside CategoryDetector — both run when user types a task title.
// v1: keyword-based. v2: will use ML scoring.

import '../../data/task_model.dart';

class PriorityDetector {

  // ── Keyword dictionary ──────────────────────────────────────────────────────
  static const Map<Priority, List<String>> _keywords = {

    Priority.urgent: [
      'urgent', 'asap', 'now', 'immediately', 'critical', 'emergency',
      'tonight', 'today', 'overdue', 'fix now', 'right now', 'must do',
      'important', 'cant wait', 'cannot wait', 'broken', 'down', 'crash',
      'failing', 'failed', 'blocked', 'blocker', 'due today', 'last minute',
    ],

    Priority.high: [
      'deadline', 'due tomorrow', 'high priority', 'must', 'need to',
      'dont forget', 'do not forget', 'submit', 'deliver', 'finish',
      'complete', 'by tomorrow', 'by tonight', 'before', 'exam',
      'presentation', 'interview', 'meeting', 'launch', 'release',
      'client', 'boss', 'manager', 'review', 'approve', 'sign',
    ],

    Priority.medium: [
      'medium', 'normal', 'medium priority', 'moderate',
      'regular', 'standard', 'average', 'mid', 'neutral',
      'not urgent', 'not important', 'whenever',
    ],

    Priority.low: [
      'someday', 'maybe', 'later', 'eventually', 'low priority',
      'whenever', 'no rush', 'backlog', 'nice to have', 'if possible',
      'optional', 'explore', 'consider', 'think about', 'look into',
      'idea', 'future', 'one day', 'not urgent', 'can wait',
    ],
  };

  // ── Deadline proximity bonus ──────────────────────────────────────────────
  // If user has already picked a deadline, we factor that in too.
  // The closer the deadline → the higher the suggested priority.

  static Priority _deadlineBonus(DateTime? deadline, Priority current) {
    if (deadline == null) return current;

    final now      = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;

    if (daysLeft <= 0)  return Priority.urgent;  // already overdue
    if (daysLeft == 1)  return Priority.urgent;  // due tomorrow
    if (daysLeft <= 3)  {
      // bump up one level if not already urgent
      if (current == Priority.low)    return Priority.medium;
      if (current == Priority.medium) return Priority.high;
      return current;
    }
    if (daysLeft <= 7)  {
      if (current == Priority.low) return Priority.medium;
      return current;
    }

    return current;
  }

  // ── Main detect function ──────────────────────────────────────────────────
  static Priority detect(String title, {
    String description = '',
    DateTime? deadline,
  }) {

    final text  = '${title.toLowerCase()} ${description.toLowerCase()}';
    final words = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    // Score each priority level
    final Map<Priority, int> scores = {
      Priority.urgent: 0,
      Priority.high:   0,
      Priority.low:    0,
    };

    for (final entry in _keywords.entries) {
      final priority    = entry.key;
      final keywordList = entry.value;

      for (final word in words) {
        if (keywordList.contains(word)) {
          // Title words score more than description words
          final inTitle = title.toLowerCase().contains(word);
          scores[priority] = (scores[priority] ?? 0) + (inTitle ? 2 : 1);
        }
      }

      // Check multi-word phrases
      for (final keyword in keywordList) {
        if (keyword.contains(' ') && text.contains(keyword)) {
          scores[priority] = (scores[priority] ?? 0) + 3;
        }
      }
    }

    // Find the highest scoring priority
    Priority suggested = Priority.medium; // default

    int topScore = 0;
    scores.forEach((priority, score) {
      if (score > topScore) {
        topScore  = score;
        suggested = priority;
      }
    });

    // If no keywords matched → default to medium
    if (topScore < 2) suggested = Priority.medium;

    // Apply deadline proximity bonus on top of keyword result
    return _deadlineBonus(deadline, suggested);
  }

  // ── Is suggestion confident? ──────────────────────────────────────────────
  // If confident → pre-select the priority button in the UI
  // If not       → leave medium selected, show suggestion as hint only

  static bool isConfident(String title, {
    String description = '',
    DateTime? deadline,
  }) {
    // Deadline within 1 day is always confident
    if (deadline != null) {
      final daysLeft = deadline.difference(DateTime.now()).inDays;
      if (daysLeft <= 1) return true;
    }

    final text  = '${title.toLowerCase()} ${description.toLowerCase()}';
    final words = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    int topScore = 0;

    for (final entry in _keywords.entries) {
      int score = 0;
      for (final word in words) {
        if (entry.value.contains(word)) {
          score += title.toLowerCase().contains(word) ? 2 : 1;
        }
      }
      if (score > topScore) topScore = score;
    }

    return topScore >= 3;
  }
}