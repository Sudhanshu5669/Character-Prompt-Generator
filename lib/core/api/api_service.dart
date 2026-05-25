import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Abstract contract for any AI text-generation provider.
abstract class AiProvider {
  /// Sends [systemPrompt] and [userPrompt] to the AI model and returns the
  /// generated text response.
  Future<String> generateContent(String systemPrompt, String userPrompt);
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
