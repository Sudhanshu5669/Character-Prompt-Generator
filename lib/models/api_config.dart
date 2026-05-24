import 'package:hive/hive.dart';

class ApiConfig extends HiveObject {
  final String? geminiApiKey;
  final String? fireworksApiKey;
  final String activeProvider;
  final String geminiModel;
  final String fireworksModel;

  ApiConfig({
    this.geminiApiKey,
    this.fireworksApiKey,
    this.activeProvider = 'gemini',
    this.geminiModel = 'gemini-2.0-flash',
    this.fireworksModel = 'accounts/fireworks/models/llama-v3-70b-instruct',
  });

  /// Whether a valid API key is configured for the active provider.
  bool get hasActiveKey {
    if (activeProvider == 'gemini') {
      return geminiApiKey != null && geminiApiKey!.isNotEmpty;
    }
    return fireworksApiKey != null && fireworksApiKey!.isNotEmpty;
  }

  /// Returns the API key for the currently active provider.
  String? get activeApiKey {
    if (activeProvider == 'gemini') {
      return geminiApiKey;
    }
    return fireworksApiKey;
  }

  /// Returns the model string for the currently active provider.
  String get activeModel {
    if (activeProvider == 'gemini') {
      return geminiModel;
    }
    return fireworksModel;
  }

  /// Returns a copy of this ApiConfig with the given fields replaced.
  ApiConfig copyWith({
    String? geminiApiKey,
    String? fireworksApiKey,
    String? activeProvider,
    String? geminiModel,
    String? fireworksModel,
  }) {
    return ApiConfig(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      fireworksApiKey: fireworksApiKey ?? this.fireworksApiKey,
      activeProvider: activeProvider ?? this.activeProvider,
      geminiModel: geminiModel ?? this.geminiModel,
      fireworksModel: fireworksModel ?? this.fireworksModel,
    );
  }

  @override
  String toString() =>
      'ApiConfig(provider: $activeProvider, model: $activeModel)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-written Hive TypeAdapter
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfigAdapter extends TypeAdapter<ApiConfig> {
  @override
  final int typeId = 3;

  @override
  ApiConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ApiConfig(
      geminiApiKey: fields[0] as String?,
      fireworksApiKey: fields[1] as String?,
      activeProvider: fields[2] as String? ?? 'gemini',
      geminiModel: fields[3] as String? ?? 'gemini-2.0-flash',
      fireworksModel: fields[4] as String? ??
          'accounts/fireworks/models/llama-v3-70b-instruct',
    );
  }

  @override
  void write(BinaryWriter writer, ApiConfig obj) {
    writer
      ..writeByte(5) // number of fields
      ..writeByte(0)
      ..write(obj.geminiApiKey)
      ..writeByte(1)
      ..write(obj.fireworksApiKey)
      ..writeByte(2)
      ..write(obj.activeProvider)
      ..writeByte(3)
      ..write(obj.geminiModel)
      ..writeByte(4)
      ..write(obj.fireworksModel);
  }
}
