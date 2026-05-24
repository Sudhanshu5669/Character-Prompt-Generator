import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_generator/core/utils/json_utils.dart';

void main() {
  group('JSON Utility Tests', () {
    test('prettyJson formats map with indentation', () {
      final map = {'a': 1, 'b': 'test'};
      final formatted = prettyJson(map);
      expect(formatted.contains('\n'), true);
      expect(formatted.contains('  "a": 1'), true);
    });

    test('tryParseJson parses valid JSON string', () {
      final text = '{"subject": "robot", "style": "cinematic"}';
      final parsed = tryParseJson(text);
      expect(parsed, isNotNull);
      expect(parsed!['subject'], 'robot');
      expect(parsed['style'], 'cinematic');
    });

    test('tryParseJson returns null on invalid JSON', () {
      final text = '{invalid json}';
      final parsed = tryParseJson(text);
      expect(parsed, isNull);
    });

    test('tryParseJsonArray strips markdown code blocks and parses array', () {
      final text = '```json\n[{"name": "test1"}, {"name": "test2"}]\n```';
      final parsed = tryParseJsonArray(text);
      expect(parsed, isNotNull);
      expect(parsed!.length, 2);
      expect(parsed[0]['name'], 'test1');
      expect(parsed[1]['name'], 'test2');
    });

    test('mergeWithLocks restores locked original values in variation', () {
      final original = {'subject': 'a cute cat', 'environment': 'beach', 'pose': 'sitting'};
      final variation = {'subject': 'a fierce dog', 'environment': 'forest', 'pose': 'running'};
      final lockedFields = ['subject', 'pose'];

      final merged = mergeWithLocks(original, variation, lockedFields);

      // Locked fields must remain as in original
      expect(merged['subject'], 'a cute cat');
      expect(merged['pose'], 'sitting');

      // Unlocked fields are taken from variation
      expect(merged['environment'], 'forest');
    });
  });
}
