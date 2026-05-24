import 'package:dio/dio.dart';

import 'package:prompt_generator/core/api/api_service.dart';
import 'package:prompt_generator/core/constants.dart';

/// [AiProvider] implementation for Google Gemini.
class GeminiProvider implements AiProvider {
  final String _apiKey;
  final String _model;
  final Dio _dio;

  GeminiProvider({
    required String apiKey,
    required String model,
    Dio? dio,
  })  : _apiKey = apiKey,
        _model = model,
        _dio = dio ?? createDioClient();

  @override
  Future<String> generateContent(
    String systemPrompt,
    String userPrompt,
  ) async {
    final url =
        '${AppConstants.geminiBaseUrl}/models/$_model:generateContent';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'x-goog-api-key': _apiKey,
          },
        ),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\n$userPrompt'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 4096,
          },
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Gemini returned an empty response.');
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        final error = data['error'];
        if (error != null) {
          throw Exception(
            'Gemini API error: ${error['message'] ?? error}',
          );
        }
        throw Exception(
          'Gemini returned no candidates. Full response: $data',
        );
      }

      final content =
          candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw Exception(
          'Gemini candidate has no content. Candidate: ${candidates[0]}',
        );
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception(
          'Gemini content has no parts. Content: $content',
        );
      }

      final text = parts[0]['text'] as String?;
      if (text == null || text.isEmpty) {
        throw Exception(
          'Gemini part has no text. Parts: $parts',
        );
      }

      return text;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception(
        'Gemini request failed (HTTP $statusCode): '
        '${body ?? e.message}',
      );
    }
  }
}
