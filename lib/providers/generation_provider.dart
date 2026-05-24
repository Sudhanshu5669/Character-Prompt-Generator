import 'package:flutter/foundation.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/models/api_config.dart';
import 'package:prompt_generator/core/api/api_service.dart';
import 'package:prompt_generator/core/api/gemini_provider.dart';
import 'package:prompt_generator/core/api/fireworks_provider.dart';
import 'package:prompt_generator/core/utils/json_utils.dart';

class GenerationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> generatedVariations = [];
  bool isGenerating = false;
  String? error;

  AiProvider _getProvider(ApiConfig config) {
    switch (config.activeProvider) {
      case 'fireworks':
        return FireworksProvider(
          apiKey: config.fireworksApiKey ?? '',
          model: config.fireworksModel,
        );
      case 'gemini':
      default:
        return GeminiProvider(
          apiKey: config.geminiApiKey ?? '',
          model: config.geminiModel,
        );
    }
  }

  Future<void> generateVariations({
    required Prompt prompt,
    required ApiConfig config,
    required String type,
    Character? character,
    int count = 5,
  }) async {
    isGenerating = true;
    error = null;
    generatedVariations = [];
    notifyListeners();

    try {
      final provider = _getProvider(config);

      final systemPrompt = _buildSystemPrompt(
        prompt: prompt,
        type: type,
        character: character,
        count: count,
      );

      final userPrompt =
          'Here is the base prompt JSON to generate variations from:\n\n${prompt.jsonContent}';

      final response = await provider.generateContent(
        systemPrompt,
        userPrompt,
      );

      final parsed = tryParseJsonArray(response);

      if (parsed == null || parsed.isEmpty) {
        error = 'Failed to parse AI response as a valid JSON array. '
            'The AI may have returned an invalid format. Please try again.';
        isGenerating = false;
        notifyListeners();
        return;
      }

      final baseJson = prompt.jsonContent;
      final List<Map<String, dynamic>> results = [];

      for (final variation in parsed) {
        if (variation is Map<String, dynamic>) {
          if (baseJson.isNotEmpty && prompt.lockedFields.isNotEmpty) {
            final merged = mergeWithLocks(
              baseJson,
              variation,
              prompt.lockedFields,
            );
            results.add(merged);
          } else {
            results.add(variation);
          }
        }
      }

      generatedVariations = results;
      isGenerating = false;
      notifyListeners();
    } catch (e) {
      error = 'Generation failed: ${e.toString()}';
      isGenerating = false;
      notifyListeners();
    }
  }

  String _buildSystemPrompt({
    required Prompt prompt,
    required String type,
    Character? character,
    int count = 5,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'You are a prompt variation generator. You MUST respond with ONLY a valid JSON array '
      'containing exactly $count prompt objects. No other text, no markdown, no explanation.',
    );
    buffer.writeln();
    buffer.writeln('RULES:');
    buffer.writeln(
      '1. Each object in the array must have the EXACT SAME keys as the base prompt.',
    );

    if (prompt.lockedFields.isNotEmpty) {
      final lockedList = prompt.lockedFields.join(', ');
      buffer.writeln(
        '2. The following fields are LOCKED and must keep their EXACT original values: $lockedList',
      );
    } else {
      buffer.writeln('2. No fields are locked — all fields can be varied.');
    }

    buffer.writeln('3. All other fields can be creatively varied.');
    buffer.writeln(
      '4. Respond with ONLY the JSON array. No other text before or after.',
    );
    buffer.writeln();

    switch (type) {
      case 'expression':
        buffer.writeln(
          'Generate $count variations focusing on different facial expressions and emotions '
          '(e.g., smiling warmly, laughing, looking contemplative, surprised, confident, shy, '
          'angry, peaceful, excited, melancholic). Each variation should have a distinct emotional quality.',
        );
        break;
      case 'pose':
        buffer.writeln(
          'Generate $count variations focusing on different body poses and positions '
          '(e.g., standing confidently, sitting casually, leaning against a wall, walking, running, '
          'jumping, dancing, lying down, crouching, stretching). Each variation should have a distinct physical posture.',
        );
        break;
      case 'environment':
        buffer.writeln(
          'Generate $count variations focusing on different environments and settings. '
          'If the current environment suggests a specific type of location, generate variations '
          'WITHIN that type. For example, if it mentions a club, vary within club settings '
          '(dancing on floor, at the bar, in VIP area, near DJ booth, on the terrace). '
          'If it mentions outdoors, vary outdoor settings.',
        );
        break;
      case 'random':
      default:
        buffer.writeln(
          'Generate $count creative and diverse variations of the prompt, '
          'changing all unlocked fields freely with creative ideas.',
        );
        break;
    }

    if ((prompt.manualInstructions ?? '').trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'ADDITIONAL INSTRUCTIONS FROM USER: ${prompt.manualInstructions}',
      );
    }

    if (character != null) {
      buffer.writeln();
      buffer.writeln(
        "CHARACTER CONTEXT - Use this character's traits to influence the variations:",
      );
      buffer.writeln('Name: ${character.name}');
      if (character.personalityTraits.isNotEmpty) {
        buffer.writeln(
          'Personality: ${character.personalityTraits.join(", ")}',
        );
      }
      if (character.situationPoints.isNotEmpty) {
        buffer.writeln(
          'Situations: ${character.situationPoints.join(", ")}',
        );
      }
    }

    return buffer.toString();
  }

  void clearResults() {
    generatedVariations = [];
    error = null;
    notifyListeners();
  }
}
