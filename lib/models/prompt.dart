import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class Prompt extends HiveObject {
  final String id;

  final String name;

  final String jsonContentRaw;

  final List<String> lockedFields;

  final String? manualInstructions;

  final DateTime createdAt;

  final DateTime updatedAt;


  Prompt({
    required this.id,
    required this.name,
    required this.jsonContentRaw,
    required this.lockedFields,
    this.manualInstructions,
    required this.createdAt,
    required this.updatedAt,
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

  /// Factory that creates a brand-new Prompt with a generated UUID.
  factory Prompt.create({
    required String name,
    required Map<String, dynamic> jsonContent,
    List<String> lockedFields = const [],
    String? manualInstructions,
  }) {
    final now = DateTime.now();
    return Prompt(
      id: const Uuid().v4(),
      name: name,
      jsonContentRaw: jsonEncode(jsonContent),
      lockedFields: List<String>.from(lockedFields),
      manualInstructions: manualInstructions,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Serializes the Prompt to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jsonContent': jsonContent,
      'lockedFields': lockedFields,
      'manualInstructions': manualInstructions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a Prompt from a JSON map.
  factory Prompt.fromJson(Map<String, dynamic> json) {
    final rawContent = json['jsonContent'];
    final String jsonContentStr;
    if (rawContent is String) {
      jsonContentStr = rawContent;
    } else if (rawContent is Map) {
      jsonContentStr = jsonEncode(rawContent);
    } else {
      jsonContentStr = '{}';
    }

    return Prompt(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled',
      jsonContentRaw: jsonContentStr,
      lockedFields: (json['lockedFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      manualInstructions: json['manualInstructions'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns a copy of this Prompt with the given fields replaced.
  Prompt copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? jsonContent,
    List<String>? lockedFields,
    String? manualInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      name: name ?? this.name,
      jsonContentRaw:
          jsonContent != null ? jsonEncode(jsonContent) : jsonContentRaw,
      lockedFields: lockedFields ?? List<String>.from(this.lockedFields),
      manualInstructions: manualInstructions ?? this.manualInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'Prompt(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Prompt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-written Hive TypeAdapter (no build_runner needed)
// ─────────────────────────────────────────────────────────────────────────────

class PromptAdapter extends TypeAdapter<Prompt> {
  @override
  final int typeId = 0;

  @override
  Prompt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Prompt(
      id: fields[0] as String,
      name: fields[1] as String,
      jsonContentRaw: fields[2] as String,
      lockedFields: (fields[3] as List).cast<String>(),
      manualInstructions: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Prompt obj) {
    writer
      ..writeByte(7) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.jsonContentRaw)
      ..writeByte(3)
      ..write(obj.lockedFields)
      ..writeByte(4)
      ..write(obj.manualInstructions)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }
}
