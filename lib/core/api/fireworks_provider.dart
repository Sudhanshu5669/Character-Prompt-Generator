import 'package:dio/dio.dart';

import 'package:prompt_generator/core/api/api_service.dart';
import 'package:prompt_generator/core/constants.dart';

/// [AiProvider] implementation for Fireworks AI.
class FireworksProvider implements AiProvider {
  final String _apiKey;
  final String _model;
  final Dio _dio;

  FireworksProvider({
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
    final url = '${AppConstants.fireworksBaseUrl}/chat/completions';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': 4096,
          'temperature': 0.8,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Fireworks returned an empty response.');
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        final error = data['error'];
        if (error != null) {
          throw Exception(
            'Fireworks API error: ${error['message'] ?? error}',
          );
        }
        throw Exception(
          'Fireworks returned no choices. Full response: $data',
        );
      }

      final message =
          choices[0]['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw Exception(
          'Fireworks choice has no message. Choice: ${choices[0]}',
        );
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception(
          'Fireworks message has no content. Message: $message',
        );
      }

      return content;
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with an error HTTP code
        final statusCode = e.response!.statusCode;
        final body = e.response!.data;
        throw Exception(
          'Fireworks request failed (HTTP $statusCode): $body',
        );
      } else {
        // No response at all — connection-level failure
        throw Exception(
          'Fireworks connection failed [${e.type.name}]: ${e.message ?? e.error ?? "No details"}',
        );
      }
    }
  }
}
