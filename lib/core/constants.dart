/// App-wide constants used across the Prompt Generator application.
class AppConstants {
  AppConstants._(); // prevent instantiation

  // ── API Base URLs ──────────────────────────────────────────────────────────

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const String fireworksBaseUrl =
      'https://api.fireworks.ai/inference/v1';

  // ── Hive Box Names ─────────────────────────────────────────────────────────

  static const String hiveBoxPrompts = 'prompts';
  static const String hiveBoxCharacters = 'characters';
  static const String hiveBoxGenerated = 'generated_prompts';
  static const String hiveBoxSettings = 'settings';

  // ── Defaults ───────────────────────────────────────────────────────────────

  static const int defaultVariationCount = 5;
}
