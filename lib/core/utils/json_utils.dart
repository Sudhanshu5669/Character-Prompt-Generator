import 'dart:convert';

/// Returns a pretty-printed JSON string with 2-space indentation.
String prettyJson(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

/// Safely parses a JSON object string. Returns `null` on any error.
Map<String, dynamic>? tryParseJson(String text) {
  try {
    final stripped = _stripMarkdownCodeBlock(text);
    final decoded = jsonDecode(stripped);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Merges [original] and [generated] maps, keeping [original] values for any
/// key listed in [lockedFields].
///
/// Keys from [generated] that are **not** locked will overwrite the
/// corresponding keys in [original]. Any key present only in [original]
/// is preserved.
Map<String, dynamic> mergeWithLocks(
  Map<String, dynamic> original,
  Map<String, dynamic> generated,
  List<String> lockedFields,
) {
  final merged = Map<String, dynamic>.from(generated);

  // Restore locked fields from the original map.
  for (final key in lockedFields) {
    if (original.containsKey(key)) {
      merged[key] = original[key];
    }
  }

  // Keep any original keys that the generated map doesn't contain.
  for (final entry in original.entries) {
    if (!merged.containsKey(entry.key)) {
      merged[entry.key] = entry.value;
    }
  }

  return merged;
}

/// Returns `true` if [text] is a valid JSON object (i.e., a `{ ... }` structure).
bool isValidJson(String text) {
  try {
    final stripped = _stripMarkdownCodeBlock(text);
    final decoded = jsonDecode(stripped);
    return decoded is Map<String, dynamic>;
  } catch (_) {
    return false;
  }
}

/// Safely parses a JSON array string. Returns `null` on any error.
///
/// Also handles the common AI pattern of wrapping the JSON inside
/// markdown code blocks:
/// ```json
/// [ ... ]
/// ```
List<Map<String, dynamic>>? tryParseJsonArray(String text) {
  try {
    final stripped = _stripMarkdownCodeBlock(text);
    final decoded = jsonDecode(stripped);

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    return null;
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Strips markdown code-block fences that AI models sometimes wrap JSON in.
///
/// Handles patterns like:
/// ```json\n{...}\n```
/// ```\n{...}\n```
String _stripMarkdownCodeBlock(String text) {
  String trimmed = text.trim();

  // Match opening fence: ```json or ``` (with optional language tag)
  final openFencePattern = RegExp(r'^```\w*\s*\n?');
  final closeFencePattern = RegExp(r'\n?```\s*$');

  if (openFencePattern.hasMatch(trimmed) &&
      closeFencePattern.hasMatch(trimmed)) {
    trimmed = trimmed.replaceFirst(openFencePattern, '');
    trimmed = trimmed.replaceFirst(closeFencePattern, '');
  }

  return trimmed.trim();
}
