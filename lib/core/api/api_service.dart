import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Abstract contract for any AI text-generation provider.
abstract class AiProvider {
  /// Sends [systemPrompt] and [userPrompt] to the AI model and returns the
  /// generated text response.
  Future<String> generateContent(String systemPrompt, String userPrompt);

  /// Streams text chunks from the AI model as they are generated.
  Stream<String> generateContentStream(String systemPrompt, String userPrompt);
}

/// Parses a Server-Sent Events byte stream into text chunks.
///
/// [extractText] is called for each parsed SSE data payload and should
/// return the text content, or null to skip the event.
Stream<String> parseSseStream(
  Stream<Uint8List> byteStream,
  String? Function(Map<String, dynamic> data) extractText,
) async* {
  String buffer = '';

  await for (final chunk in byteStream.cast<List<int>>().transform(utf8.decoder)) {
    buffer += chunk;

    while (true) {
      final lineEnd = buffer.indexOf('\n');
      if (lineEnd == -1) break;

      final line = buffer.substring(0, lineEnd).trim();
      buffer = buffer.substring(lineEnd + 1);

      if (line.isEmpty || !line.startsWith('data: ')) continue;

      final payload = line.substring(6).trim();
      if (payload == '[DONE]') return;

      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final text = extractText(json);
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      } catch (_) {
        // Skip malformed chunks
      }
    }
  }
}

/// Creates a pre-configured [Dio] instance suitable for AI API calls.
///
/// Features:
/// - 60-second connect and receive timeouts
/// - JSON `Content-Type` / `Accept` headers
/// - An error interceptor that logs failures in debug mode
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180), // AI APIs can be slow
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        debugPrint('──── DIO ERROR ────');
        debugPrint('URI       : ${error.requestOptions.uri}');
        debugPrint('Method    : ${error.requestOptions.method}');
        debugPrint('Status    : ${error.response?.statusCode}');
        debugPrint('Message   : ${error.message}');
        if (error.response?.data != null) {
          debugPrint('Body      : ${error.response?.data}');
        }
        debugPrint('───────────────────');
        handler.next(error);
      },
    ),
  );

  return dio;
}

/// Safely reads the error body from a [DioException] when responseType is ResponseType.stream.
Future<String> getStreamErrorBody(DioException e) async {
  final response = e.response;
  if (response == null) return e.message ?? 'Unknown network error';

  final data = response.data;
  if (data is ResponseBody) {
    try {
      final List<int> bytes = [];
      await for (final chunk in data.stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    } catch (err) {
      return 'Failed to read stream error: $err';
    }
  }

  return data?.toString() ?? e.message ?? 'Unknown response error';
}
