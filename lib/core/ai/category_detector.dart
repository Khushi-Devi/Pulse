// ── Smart Categorisation Engine ───────────────────────────────────────────────
// This is the v1 keyword-based NLP engine.
// It reads the task title + description, scores each category,
// and returns the best match. If no match → General.
// v2 will replace this with TFLite ML Kit — same input/output, smarter logic.

import '../../data/task_model.dart';

class CategoryDetector {

  // ── Keyword dictionary ──────────────────────────────────────────────────────
  static const Map<TaskCategory, List<String>> _keywords = {

    TaskCategory.study: [
      'study', 'exam', 'assignment', 'lecture', 'notes', 'revision',
      'homework', 'quiz', 'test', 'chapter', 'textbook', 'research',
      'thesis', 'paper', 'class', 'course', 'college', 'university',
      'school', 'read', 'reading', 'learn', 'learning', 'practice',
      'subject', 'topic', 'concept', 'formula', 'question', 'answer',
    ],

    TaskCategory.work: [
      'meeting', 'report', 'deadline', 'client', 'email', 'project',
      'presentation', 'review', 'sprint', 'standup', 'invoice', 'proposal',
      'manager', 'team', 'office', 'work', 'job', 'task', 'deliver',
      'submit', 'feedback', 'interview', 'hire', 'salary', 'contract',
      'business', 'call', 'zoom', 'slack', 'ticket',
    ],

    TaskCategory.health: [
      'gym', 'workout', 'run', 'doctor', 'medicine', 'sleep', 'exercise',
      'jog', 'yoga', 'diet', 'appointment', 'therapy', 'meditate',
      'walk', 'cycling', 'swim', 'stretch', 'health', 'fitness',
      'calories', 'water', 'vitamins', 'hospital', 'clinic', 'pushup',
      'pullup', 'squat', 'plank', 'protein', 'weight',
    ],

    TaskCategory.coding: [
      'leetcode', 'github', 'bug', 'deploy', 'feature', 'pr',
      'pull request', 'code', 'debug', 'api', 'database', 'commit',
      'refactor', 'test', 'build', 'fix', 'issue', 'repo', 'branch',
      'merge', 'dev', 'develop', 'app', 'website', 'flutter', 'dart',
      'javascript', 'python', 'java', 'react', 'server', 'backend',
      'frontend', 'css', 'html', 'sql', 'function', 'algorithm',
    ],

    TaskCategory.shopping: [
      'buy', 'order', 'grocery', 'cart', 'delivery', 'purchase',
      'store', 'market', 'amazon', 'checkout', 'shop', 'get',
      'pick up', 'milk', 'bread', 'vegetables', 'clothes', 'shoes',
      'online', 'price', 'discount', 'sale', 'gift',
    ],

    TaskCategory.finance: [
      'bill', 'invoice', 'payment', 'budget', 'tax', 'bank',
      'transaction', 'salary', 'rent', 'subscription', 'money',
      'finance', 'expense', 'income', 'savings', 'invest', 'loan',
      'credit', 'debit', 'upi', 'transfer', 'due', 'emi', 'insurance',
    ],

    TaskCategory.personal: [
      'family', 'friend', 'travel', 'holiday', 'birthday', 'event',
      'dinner', 'movie', 'plan', 'trip', 'visit', 'party', 'celebrate',
      'home', 'house', 'clean', 'cook', 'laundry', 'repair', 'fix',
      'personal', 'self', 'journal', 'diary', 'relax', 'hobby',
    ],
  };

  // ── Main detect function ────────────────────────────────────────────────────
  // Takes title + description, returns the best category.
  // This is what gets called every time the user types in the task form.

  static TaskCategory detect(String title, {String description = ''}) {

    // Combine title and description, lowercase everything
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    // Split into words — remove punctuation
    final words = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1) // ignore single letters
        .toList();

    // Score each category
    final Map<TaskCategory, int> scores = {};

    for (final entry in _keywords.entries) {
      final category = entry.key;
      final keywordList = entry.value;

      int score = 0;

      for (final word in words) {
        if (keywordList.contains(word)) {
          // Title words are worth more than description words
          final inTitle = title.toLowerCase().contains(word);
          score += inTitle ? 2 : 1;
        }
      }

      // Also check for multi-word phrases (e.g. "pull request", "pick up")
      for (final keyword in keywordList) {
        if (keyword.contains(' ') && text.contains(keyword)) {
          score += 3; // multi-word match is a strong signal
        }
      }

      if (score > 0) scores[category] = score;
    }

    // No matches → General
    if (scores.isEmpty) return TaskCategory.general;

    // Return the highest scoring category
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);

    // Confidence threshold — if score is only 1, not confident enough
    if (best.value < 2) return TaskCategory.general;

    return best.key;
  }

  // ── Confidence check ────────────────────────────────────────────────────────
  // Returns true if detection is confident enough to auto-assign
  // Returns false if we should just suggest rather than auto-assign

  static bool isConfident(String title, {String description = ''}) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
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

    // Confident if score is 3 or more
    return topScore >= 3;
  }
}