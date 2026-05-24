import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/core/constants.dart';

class PromptProvider extends ChangeNotifier {
  List<Prompt> _prompts = [];

  List<Prompt> get prompts {
    final sorted = List<Prompt>.from(_prompts);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Box<Prompt> get _box => Hive.box<Prompt>(AppConstants.hiveBoxPrompts);

  void loadPrompts() {
    _prompts = _box.values.toList();
    notifyListeners();
  }

  Future<void> addPrompt(Prompt prompt) async {
    await _box.put(prompt.id, prompt);
    _prompts.add(prompt);
    notifyListeners();
  }

  Future<void> updatePrompt(Prompt prompt) async {
    final updated = prompt.copyWith(updatedAt: DateTime.now());
    await _box.put(updated.id, updated);
    final index = _prompts.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _prompts[index] = updated;
    } else {
      _prompts.add(updated);
    }
    notifyListeners();
  }

  Future<void> deletePrompt(String id) async {
    await _box.delete(id);
    _prompts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Prompt? getById(String id) {
    try {
      return _prompts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
