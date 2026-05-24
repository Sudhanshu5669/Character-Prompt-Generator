import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class Character extends HiveObject {
  final String id;
  final String name;
  final String avatarEmoji;
  final List<String> personalityTraits;
  final List<String> situationPoints;
  final DateTime createdAt;

  Character({
    required this.id,
    required this.name,
    this.avatarEmoji = '🧑',
    required this.personalityTraits,
    required this.situationPoints,
    required this.createdAt,
  });

  /// Factory that creates a brand-new Character with a generated UUID.
  factory Character.create({
    required String name,
    String avatarEmoji = '🧑',
    List<String> personalityTraits = const [],
    List<String> situationPoints = const [],
  }) {
    return Character(
      id: const Uuid().v4(),
      name: name,
      avatarEmoji: avatarEmoji,
      personalityTraits: List<String>.from(personalityTraits),
      situationPoints: List<String>.from(situationPoints),
      createdAt: DateTime.now(),
    );
  }

  /// Serializes the Character to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarEmoji': avatarEmoji,
      'personalityTraits': personalityTraits,
      'situationPoints': situationPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a Character from a JSON map.
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Unnamed',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🧑',
      personalityTraits: (json['personalityTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      situationPoints: (json['situationPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns a copy of this Character with the given fields replaced.
  Character copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    List<String>? personalityTraits,
    List<String>? situationPoints,
    DateTime? createdAt,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      personalityTraits:
          personalityTraits ?? List<String>.from(this.personalityTraits),
      situationPoints:
          situationPoints ?? List<String>.from(this.situationPoints),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Character(id: $id, name: $name, emoji: $avatarEmoji)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Character && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-written Hive TypeAdapter
// ─────────────────────────────────────────────────────────────────────────────

class CharacterAdapter extends TypeAdapter<Character> {
  @override
  final int typeId = 1;

  @override
  Character read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Character(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarEmoji: fields[2] as String? ?? '🧑',
      personalityTraits: (fields[3] as List).cast<String>(),
      situationPoints: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Character obj) {
    writer
      ..writeByte(6) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.personalityTraits)
      ..writeByte(4)
      ..write(obj.situationPoints)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}
