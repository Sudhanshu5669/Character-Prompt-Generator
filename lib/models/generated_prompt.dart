import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class GeneratedPrompt extends HiveObject {
  final String id;
  final String parentPromptId;
  final String jsonContentRaw;
  final String generationType;
  final DateTime createdAt;

  GeneratedPrompt({
    required this.id,
    required this.parentPromptId,
    required this.jsonContentRaw,
    required this.generationType,
    required this.createdAt,
  });

  /// Convenience getter that deserializes the stored JSON string into a Map.
  Map<String, dynamic> get jsonContent {
    try {
      final decoded = jsonDecode(jsonContentRaw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Factory that creates a brand-new GeneratedPrompt with a generated UUID.
  factory GeneratedPrompt.create({
    required String parentPromptId,
    required Map<String, dynamic> jsonContent,
    required String generationType,
  }) {
    return GeneratedPrompt(
      id: const Uuid().v4(),
      parentPromptId: parentPromptId,
      jsonContentRaw: jsonEncode(jsonContent),
      generationType: generationType,
      createdAt: DateTime.now(),
    );
  }

  /// Serializes the GeneratedPrompt to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentPromptId': parentPromptId,
      'jsonContent': jsonContent,
      'generationType': generationType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a GeneratedPrompt from a JSON map.
  factory GeneratedPrompt.fromJson(Map<String, dynamic> json) {
    final rawContent = json['jsonContent'];
    final String jsonContentStr;
    if (rawContent is String) {
      jsonContentStr = rawContent;
    } else if (rawContent is Map) {
      jsonContentStr = jsonEncode(rawContent);
    } else {
      jsonContentStr = '{}';
    }

    return GeneratedPrompt(
      id: json['id'] as String? ?? const Uuid().v4(),
      parentPromptId: json['parentPromptId'] as String? ?? '',
      jsonContentRaw: jsonContentStr,
      generationType: json['generationType'] as String? ?? 'random',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'GeneratedPrompt(id: $id, type: $generationType, parent: $parentPromptId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GeneratedPrompt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-written Hive TypeAdapter
// ─────────────────────────────────────────────────────────────────────────────

class GeneratedPromptAdapter extends TypeAdapter<GeneratedPrompt> {
  @override
  final int typeId = 2;

  @override
  GeneratedPrompt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return GeneratedPrompt(
      id: fields[0] as String,
      parentPromptId: fields[1] as String,
      jsonContentRaw: fields[2] as String,
      generationType: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedPrompt obj) {
    writer
      ..writeByte(5) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentPromptId)
      ..writeByte(2)
      ..write(obj.jsonContentRaw)
      ..writeByte(3)
      ..write(obj.generationType)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
