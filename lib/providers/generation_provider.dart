import 'dart:convert';

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
  Map<String, dynamic>? activeVariation;
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
    required Map<String, String> selectedCategories,
    Character? character,
    String? additionalContext,
    Prompt? referencePrompt,
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
        selectedCategories: selectedCategories,
        character: character,
        additionalContext: additionalContext,
        referencePrompt: referencePrompt,
        count: count,
      );

      final userPrompt =
          'Here is the base prompt JSON to generate variations from:\n\n${prompt.jsonContent}';

      final parser = _IncrementalJsonParser();

      await for (final chunk
          in provider.generateContentStream(systemPrompt, userPrompt)) {
        final newObjects = parser.addChunk(chunk);

        // Update active variation with the currently incomplete JSON object in the buffer
        final remaining = parser.remainingText.trim();
        final incompleteObject = _extractIncompleteObject(remaining);
        if (incompleteObject != null) {
          final partial = parsePartialJson(incompleteObject);
          if (prompt.jsonContent.isNotEmpty && prompt.lockedFields.isNotEmpty) {
            activeVariation = mergeWithLocks(
              prompt.jsonContent,
              partial,
              prompt.lockedFields,
            );
            final changeTitle = partial['_change_title'] as String?;
            if (changeTitle != null) {
              activeVariation!['_change_title'] = changeTitle;
            }
          } else {
            activeVariation = partial;
          }
        } else {
          activeVariation = null;
        }

        for (final variation in newObjects) {
          final changeTitle = variation['_change_title'] as String?;

          Map<String, dynamic> processed;
          if (prompt.jsonContent.isNotEmpty &&
              prompt.lockedFields.isNotEmpty) {
            processed = mergeWithLocks(
              prompt.jsonContent,
              variation,
              prompt.lockedFields,
            );
            if (changeTitle != null) {
              processed['_change_title'] = changeTitle;
            }
          } else {
            processed = variation;
          }

          generatedVariations = [...generatedVariations, processed];
          activeVariation = null; // Clear active since it has been completed
        }
        notifyListeners();
      }

      activeVariation = null; // Ensure cleared at the end
      notifyListeners();

      // Fallback: if streaming parser didn't yield objects, try full-text parse
      if (generatedVariations.isEmpty) {
        final fullText = parser.remainingText;
        final parsed = tryParseJsonArray(fullText);
        if (parsed != null && parsed.isNotEmpty) {
          final List<Map<String, dynamic>> results = [];
          for (final variation in parsed) {
            if (variation is Map<String, dynamic>) {
              final changeTitle = variation['_change_title'] as String?;
              if (prompt.jsonContent.isNotEmpty &&
                  prompt.lockedFields.isNotEmpty) {
                final merged = mergeWithLocks(
                  prompt.jsonContent,
                  variation,
                  prompt.lockedFields,
                );
                if (changeTitle != null) {
                  merged['_change_title'] = changeTitle;
                }
                results.add(merged);
              } else {
                results.add(variation);
              }
            }
          }
          generatedVariations = results;
        }
      }

      if (generatedVariations.isEmpty) {
        error = 'Failed to parse AI response as a valid JSON array. '
            'The AI may have returned an invalid format. Please try again.';
      }

      isGenerating = false;
      notifyListeners();
    } catch (e) {
      if (generatedVariations.isEmpty) {
        error = 'Generation failed: ${e.toString()}';
      }
      isGenerating = false;
      notifyListeners();
    }
  }

  String _buildSystemPrompt({
    required Prompt prompt,
    required Map<String, String> selectedCategories,
    Character? character,
    String? additionalContext,
    Prompt? referencePrompt,
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
      '1. Each object in the array must have the EXACT SAME keys as the base prompt PLUS a mandatory "_change_title" key.',
    );
    buffer.writeln(
      '2. The "_change_title" field must be 3-5 words summarizing the change (e.g., "Warm Evening Smile", "Neon Club Dance").',
    );

    if (prompt.lockedFields.isNotEmpty) {
      final lockedList = prompt.lockedFields.join(', ');
      buffer.writeln(
        '3. The following fields are LOCKED and must keep their EXACT original values: $lockedList',
      );
    } else {
      buffer.writeln('3. No fields are locked — all fields can be varied.');
    }

    buffer.writeln('4. All other fields can be creatively varied.');
    buffer.writeln(
      '5. Respond with ONLY the JSON array. No other text before or after.',
    );
    buffer.writeln();

    // Build category-specific instructions
    final hasRandom = selectedCategories.containsKey('random');

    if (hasRandom) {
      buffer.writeln(
        'Generate $count creative and diverse variations of the prompt, '
        'changing all unlocked fields freely with creative ideas.',
      );
      final hint = selectedCategories['random'] ?? '';
      if (hint.trim().isNotEmpty) {
        buffer.writeln('DIRECTION HINT: $hint');
      }
    } else {
      final categories = selectedCategories.keys.toList();
      final categoryCount = categories.length;

      if (categoryCount == 1) {
        _writeSingleCategory(buffer, categories.first, selectedCategories[categories.first] ?? '', count);
      } else {
        buffer.writeln(
          'Generate $count variations that SIMULTANEOUSLY vary ALL of the following aspects together '
          'in each variation (not separately — each output prompt should reflect changes in all these areas at once):',
        );
        buffer.writeln();
        for (final cat in categories) {
          final hint = selectedCategories[cat] ?? '';
          _writeCategoryBullet(buffer, cat, hint);
        }
        buffer.writeln();
        buffer.writeln(
          'Each of the $count output prompts must reflect coordinated changes across ALL listed aspects.',
        );
      }
    }

    if ((prompt.manualInstructions ?? '').trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'ADDITIONAL INSTRUCTIONS FROM USER: ${prompt.manualInstructions}',
      );
    }

    if (referencePrompt != null) {
      buffer.writeln();
      buffer.writeln(
        'REFERENCE PROMPT - Use this as inspiration for style and values while maintaining the base prompt\'s schema:',
      );
      buffer.writeln(referencePrompt.jsonContent);
      buffer.writeln();
      buffer.writeln(
        'Instructions: Generate variations inspired by the reference prompt\'s values and style '
        'while strictly preserving the base prompt\'s keys and schema.',
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

    if ((additionalContext ?? '').trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'ADDITIONAL CONTEXT — The user wants you to follow these extra instructions '
        'that may not fit into the categories above. Treat them as hard constraints '
        'and apply them to EVERY generated variation:',
      );
      buffer.writeln(additionalContext);
    }

    return buffer.toString();
  }

  void _writeSingleCategory(
    StringBuffer buffer,
    String category,
    String hint,
    int count,
  ) {
    switch (category) {
      case 'expression':
        buffer.writeln(
          'Generate $count variations focusing on different facial expressions and emotions '
          '(e.g., smiling warmly, laughing, contemplative, surprised, confident, shy, '
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
          'WITHIN that type (e.g., if it mentions a club, vary within club settings).',
        );
        break;
      case 'clothes':
        buffer.writeln(
          'Generate $count variations focusing on different clothing and outfits. '
          'Vary the outfit style, colors, accessories, and overall fashion aesthetic.',
        );
        break;
      default:
        buffer.writeln(
          'Generate $count creative and diverse variations of the prompt, '
          'changing all unlocked fields freely with creative ideas.',
        );
    }
    if (hint.trim().isNotEmpty) {
      buffer.writeln('USER HINT: $hint');
    }
  }

  void _writeCategoryBullet(StringBuffer buffer, String category, String hint) {
    String label;
    String desc;
    switch (category) {
      case 'expression':
        label = 'Expression';
        desc = 'Change facial expression and emotion';
        break;
      case 'pose':
        label = 'Pose';
        desc = 'Change body pose and posture';
        break;
      case 'environment':
        label = 'Environment';
        desc = 'Change the setting or location context';
        break;
      case 'clothes':
        label = 'Clothes';
        desc = 'Change outfit, style, and accessories';
        break;
      default:
        label = category;
        desc = 'Vary creatively';
    }
    if (hint.trim().isNotEmpty) {
      buffer.writeln('• $label: $desc. User instruction: "$hint"');
    } else {
      buffer.writeln('• $label: $desc (AI decides freely).');
    }
  }

  void clearResults() {
    generatedVariations = [];
    activeVariation = null;
    error = null;
    notifyListeners();
  }

  String? _extractIncompleteObject(String text) {
    final idx = text.lastIndexOf('{');
    if (idx == -1) return null;
    final lastClose = text.lastIndexOf('}');
    if (lastClose > idx) {
      return null;
    }
    return text.substring(idx);
  }

  Map<String, dynamic> parsePartialJson(String jsonStr) {
    final Map<String, dynamic> result = {};
    int i = 0;
    
    final firstBrace = jsonStr.indexOf('{');
    if (firstBrace == -1) return result;
    i = firstBrace + 1;
    
    String? currentKey;
    final StringBuffer currentVal = StringBuffer();
    bool inString = false;
    bool escaped = false;
    bool readingKey = false;
    bool readingValue = false;
    
    while (i < jsonStr.length) {
      final c = jsonStr[i];
      
      if (escaped) {
        if (readingValue && currentKey != null) {
          currentVal.write(c);
        }
        escaped = false;
        i++;
        continue;
      }
      
      if (c == '\\') {
        escaped = true;
        i++;
        continue;
      }
      
      if (c == '"') {
        inString = !inString;
        if (inString) {
          if (!readingValue) {
            readingKey = true;
            currentVal.clear();
          } else {
            currentVal.clear();
          }
        } else {
          if (readingKey) {
            currentKey = currentVal.toString();
            readingKey = false;
          } else if (readingValue && currentKey != null) {
            result[currentKey] = currentVal.toString();
            readingValue = false;
            currentKey = null;
          }
        }
        i++;
        continue;
      }
      
      if (inString) {
        if (readingKey || readingValue) {
          currentVal.write(c);
        }
        i++;
        continue;
      }
      
      if (c == ':') {
        if (currentKey != null) {
          readingValue = true;
          currentVal.clear();
        }
      } else if (c == ',' || c == '}') {
        if (readingValue && currentKey != null) {
          final valStr = currentVal.toString().trim();
          if (valStr.isNotEmpty) {
            if (valStr == 'true') result[currentKey] = true;
            else if (valStr == 'false') result[currentKey] = false;
            else if (valStr == 'null') result[currentKey] = null;
            else {
              final numVal = num.tryParse(valStr);
              if (numVal != null) {
                result[currentKey] = numVal;
              } else {
                result[currentKey] = valStr;
              }
            }
          }
          readingValue = false;
          currentKey = null;
        }
      } else {
        if (readingValue && !inString) {
          currentVal.write(c);
        }
      }
      
      i++;
    }
    
    if (readingValue && currentKey != null) {
      result[currentKey] = currentVal.toString();
    }
    
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incremental JSON array parser for streaming
// ─────────────────────────────────────────────────────────────────────────────

class _IncrementalJsonParser {
  final StringBuffer _buffer = StringBuffer();
  bool _foundArrayStart = false;

  /// Returns any unparsed text still in the buffer.
  String get remainingText => _buffer.toString();

  /// Appends [chunk] to the internal buffer and returns any newly completed
  /// top-level JSON objects found within the array.
  List<Map<String, dynamic>> addChunk(String chunk) {
    _buffer.write(chunk);
    return _extractObjects();
  }

  List<Map<String, dynamic>> _extractObjects() {
    final text = _buffer.toString();
    final results = <Map<String, dynamic>>[];

    int searchFrom = 0;

    // Wait for the opening '[' of the JSON array.
    if (!_foundArrayStart) {
      final idx = text.indexOf('[');
      if (idx == -1) return results;
      _foundArrayStart = true;
      searchFrom = idx + 1;
    }

    // Walk the text tracking brace depth to find complete objects.
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    int? objectStart;
    int lastObjectEnd = -1;

    for (int i = searchFrom; i < text.length; i++) {
      final c = text[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (c == '\\' && inString) {
        escaped = true;
        continue;
      }

      if (c == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (c == '{') {
        if (depth == 0) objectStart = i;
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0 && objectStart != null) {
          final objectStr = text.substring(objectStart, i + 1);
          try {
            final obj = jsonDecode(objectStr);
            if (obj is Map<String, dynamic>) {
              results.add(obj);
              lastObjectEnd = i;
            }
          } catch (_) {
            // Not valid JSON yet — continue accumulating.
          }
          objectStart = null;
        }
      }
    }

    // Trim the buffer to remove already-parsed content.
    if (lastObjectEnd >= 0) {
      _buffer.clear();
      _buffer.write(text.substring(lastObjectEnd + 1));
    }

    return results;
  }
}
