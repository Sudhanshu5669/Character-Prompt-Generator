import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prompt_generator/models/api_config.dart';
import 'package:prompt_generator/core/constants.dart';
import 'package:prompt_generator/core/api/api_service.dart';
import 'package:prompt_generator/core/api/gemini_provider.dart';
import 'package:prompt_generator/core/api/fireworks_provider.dart';

class SettingsProvider extends ChangeNotifier {
  ApiConfig _config = ApiConfig(
    geminiApiKey: '',
    fireworksApiKey: '',
    activeProvider: 'gemini',
    geminiModel: 'gemini-2.0-flash',
    fireworksModel: 'accounts/fireworks/models/llama-v3p1-70b-instruct',
  );

  ApiConfig get config => _config;

  Box<ApiConfig> get _box => Hive.box<ApiConfig>(AppConstants.hiveBoxSettings);

  void loadSettings() {
    if (_box.isNotEmpty) {
      _config = _box.getAt(0)!;
    } else {
      _box.add(_config);
    }
    notifyListeners();
  }

  Future<void> updateConfig(ApiConfig config) async {
    _config = config;
    if (_box.isNotEmpty) {
      await _box.putAt(0, config);
    } else {
      await _box.add(config);
    }
    notifyListeners();
  }

  // Helper Setters for home_screen settings form
  Future<void> setActiveProvider(String provider) async {
    await updateConfig(_config.copyWith(activeProvider: provider));
  }

  Future<void> setGeminiApiKey(String key) async {
    await updateConfig(_config.copyWith(geminiApiKey: key));
  }

  Future<void> setGeminiModel(String model) async {
    await updateConfig(_config.copyWith(geminiModel: model));
  }

  Future<void> setFireworksApiKey(String key) async {
    await updateConfig(_config.copyWith(fireworksApiKey: key));
  }

  Future<void> setFireworksModel(String model) async {
    await updateConfig(_config.copyWith(fireworksModel: model));
  }

  bool get hasValidApiKey {
    if (_config.activeProvider == 'gemini') {
      return (_config.geminiApiKey ?? '').trim().isNotEmpty;
    } else if (_config.activeProvider == 'fireworks') {
      return (_config.fireworksApiKey ?? '').trim().isNotEmpty;
    }
    return false;
  }

  String get activeProviderName {
    switch (_config.activeProvider) {
      case 'fireworks':
        return 'Fireworks';
      case 'gemini':
      default:
        return 'Gemini';
    }
  }

  // Robust testConnection helper
  Future<bool> testConnection() async {
    try {
      final AiProvider provider;
      if (_config.activeProvider == 'fireworks') {
        provider = FireworksProvider(
          apiKey: _config.fireworksApiKey ?? '',
          model: _config.fireworksModel,
        );
      } else {
        provider = GeminiProvider(
          apiKey: _config.geminiApiKey ?? '',
          model: _config.geminiModel,
        );
      }

      final response = await provider.generateContent(
        'You are a testing assistant. Reply with the single word: "OK". Nothing else.',
        'Ping',
      );

      return response.trim().toUpperCase().contains('OK');
    } catch (_) {
      return false;
    }
  }
}
