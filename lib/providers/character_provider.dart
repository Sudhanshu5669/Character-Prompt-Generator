import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/core/constants.dart';

class CharacterProvider extends ChangeNotifier {
  List<Character> _characters = [];

  List<Character> get characters {
    final sorted = List<Character>.from(_characters);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  Box<Character> get _box => Hive.box<Character>(AppConstants.hiveBoxCharacters);

  void loadCharacters() {
    _characters = _box.values.toList();
    notifyListeners();
  }

  Future<void> addCharacter(Character character) async {
    await _box.put(character.id, character);
    _characters.add(character);
    notifyListeners();
  }

  Future<void> updateCharacter(Character character) async {
    await _box.put(character.id, character);
    final index = _characters.indexWhere((c) => c.id == character.id);
    if (index != -1) {
      _characters[index] = character;
    } else {
      _characters.add(character);
    }
    notifyListeners();
  }

  Future<void> deleteCharacter(String id) async {
    await _box.delete(id);
    _characters.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Character? getById(String id) {
    try {
      return _characters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
