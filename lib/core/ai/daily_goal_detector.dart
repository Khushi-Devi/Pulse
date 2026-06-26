// ── Daily Goal Detector ───────────────────────────────────────────────────────
// Detects if a task title contains a recurring daily commitment.
// If detected → app prompts user to convert it into a Daily Goal.
// Example: "5 LeetCode questions per day" → triggers Daily Goal prompt.

import '../../data/task_model.dart';

class DailyGoalDetector {

  // ── Trigger phrases ───────────────────────────────────────────────────────
  static const List<String> _dailyTriggers = [
    'per day', 'a day', '/day', 'daily', 'every day',
    'each day', 'everyday', 'day by day', 'each morning',
    'each night', 'each evening', 'morning routine',
    'night routine', 'daily routine',
  ];

  static const List<String> _weeklyTriggers = [
    'per week', 'a week', '/week', 'weekly', 'every week',
    'each week', 'once a week', 'twice a week',
  ];

  // ── Detection result ──────────────────────────────────────────────────────
  // Returns what kind of goal was detected — none, daily, or weekly.

  static GoalDetectionResult detect(String title) {
    final text = title.toLowerCase().trim();

    // Check daily triggers first
    for (final trigger in _dailyTriggers) {
      if (text.contains(trigger)) {
        return GoalDetectionResult(
          isGoal:    true,
          frequency: RecurringFrequency.daily,
          trigger:   trigger,
          suggested: _buildSuggestedTitle(title, trigger),
        );
      }
    }

    // Check weekly triggers
    for (final trigger in _weeklyTriggers) {
      if (text.contains(trigger)) {
        return GoalDetectionResult(
          isGoal:    true,
          frequency: RecurringFrequency.weekly,
          trigger:   trigger,
          suggested: _buildSuggestedTitle(title, trigger),
        );
      }
    }

    // Nothing detected
    return GoalDetectionResult(
      isGoal:    false,
      frequency: RecurringFrequency.none,
      trigger:   '',
      suggested: title,
    );
  }

  // ── Build a clean goal title ──────────────────────────────────────────────
  // Strips the trigger phrase from the title for a cleaner goal name.
  // "5 LeetCode questions per day" → "5 LeetCode questions"

  static String _buildSuggestedTitle(String title, String trigger) {
    return title
        .toLowerCase()
        .replaceAll(trigger, '')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ')
        .trim();
  }

  // ── Extract quantity from title ───────────────────────────────────────────
  // "5 LeetCode questions per day" → returns 5
  // Used to pre-fill the daily goal target count.

  static int? extractQuantity(String title) {
    final match = RegExp(r'\b(\d+)\b').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

// ── Detection result container ────────────────────────────────────────────────
class GoalDetectionResult {
  final bool               isGoal;
  final RecurringFrequency frequency;
  final String             trigger;    // which phrase triggered it
  final String             suggested;  // cleaned up goal title

  const GoalDetectionResult({
    required this.isGoal,
    required this.frequency,
    required this.trigger,
    required this.suggested,
  });
}