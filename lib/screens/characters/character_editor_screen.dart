import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/providers/character_provider.dart';

class CharacterEditorScreen extends StatefulWidget {
  final String? characterId;

  const CharacterEditorScreen({super.key, this.characterId});

  @override
  State<CharacterEditorScreen> createState() => _CharacterEditorScreenState();
}

class _CharacterEditorScreenState extends State<CharacterEditorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _nameController = TextEditingController();
  final _traitController = TextEditingController();
  final _situationController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _traitFocusNode = FocusNode();
  final _situationFocusNode = FocusNode();

  String _selectedEmoji = '🧑';
  List<String> _personalityTraits = [];
  List<String> _situationPoints = [];
  bool _isEditing = false;
  Character? _existingCharacter;

  static const List<String> _emojiOptions = [
    '🧑', '👩', '👨', '🧒', '👶', '🧓', '🦸', '🧙', '🧝', '🧛',
    '🧟', '🤖', '👻', '🎭', '🐱', '🐶', '🦊', '🐻', '🐼', '🦁',
    '🐯', '🦄', '🐉', '👸', '🤴', '🥷', '🧜', '🧚', '🦹', '👼',
  ];

  static const List<String> _suggestedTraits = [
    'cheerful', 'shy', 'bold', 'mysterious', 'energetic', 'calm',
    'sarcastic', 'romantic', 'fierce', 'playful', 'elegant', 'wild',
  ];

  static const List<String> _suggestedSituations = [
    'at a café', 'on a rooftop', 'in a club', 'at the beach',
    'in a forest', 'on stage', 'in a library', 'at a party',
    'on the street', 'in the rain', 'at sunset', 'in a studio',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    if (widget.characterId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCharacter();
      });
    }
  }

  void _loadCharacter() {
    final provider = context.read<CharacterProvider>();
    final character = provider.characters.firstWhere(
      (c) => c.id == widget.characterId,
      orElse: () => Character(
        id: '',
        name: '',
        avatarEmoji: '🧑',
        personalityTraits: [],
        situationPoints: [],
        createdAt: DateTime.now(),
      ),
    );
    if (character.id.isNotEmpty) {
      setState(() {
        _existingCharacter = character;
        _nameController.text = character.name;
        _selectedEmoji = character.avatarEmoji;
        _personalityTraits = List<String>.from(character.personalityTraits);
        _situationPoints = List<String>.from(character.situationPoints);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _traitController.dispose();
    _situationController.dispose();
    _nameFocusNode.dispose();
    _traitFocusNode.dispose();
    _situationFocusNode.dispose();
    super.dispose();
  }

  void _openEmojiPicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Avatar',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an emoji for your character',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _emojiOptions.length,
                itemBuilder: (ctx, i) {
                  final emoji = _emojiOptions[i];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      Navigator.of(ctx).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white70
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTrait() {
    final trait = _traitController.text.trim().toLowerCase();
    if (trait.isNotEmpty && !_personalityTraits.contains(trait)) {
      setState(() {
        _personalityTraits.add(trait);
        _traitController.clear();
      });
    }
  }

  void _addSituation() {
    final situation = _situationController.text.trim().toLowerCase();
    if (situation.isNotEmpty && !_situationPoints.contains(situation)) {
      setState(() {
        _situationPoints.add(situation);
        _situationController.clear();
      });
    }
  }

  void _saveCharacter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Please enter a character name',
                  style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
          backgroundColor: Colors.white24,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final provider = context.read<CharacterProvider>();

    if (_isEditing && _existingCharacter != null) {
      final updated = _existingCharacter!.copyWith(
        name: name,
        avatarEmoji: _selectedEmoji,
        personalityTraits: _personalityTraits,
        situationPoints: _situationPoints,
      );
      provider.updateCharacter(updated);
    } else {
      final character = Character(
        id: const Uuid().v4(),
        name: name,
        avatarEmoji: _selectedEmoji,
        personalityTraits: _personalityTraits,
        situationPoints: _situationPoints,
        createdAt: DateTime.now(),
      );
      provider.addCharacter(character);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Character' : 'New Character',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmojiSelector(),
              const SizedBox(height: 28),
              _buildNameField(),
              const SizedBox(height: 32),
              _buildSectionHeader(
                icon: Icons.psychology_rounded,
                title: 'Personality Traits',
              ),
              const SizedBox(height: 12),
              _buildChipsSection(
                items: _personalityTraits,
                onDelete: (item) =>
                    setState(() => _personalityTraits.remove(item)),
              ),
              const SizedBox(height: 12),
              _buildAddField(
                controller: _traitController,
                focusNode: _traitFocusNode,
                hint: 'Add a personality trait...',
                onAdd: _addTrait,
              ),
              const SizedBox(height: 12),
              _buildSuggestedChips(
                suggestions: _suggestedTraits,
                existing: _personalityTraits,
                onTap: (trait) => setState(() {
                  if (!_personalityTraits.contains(trait)) {
                    _personalityTraits.add(trait);
                  }
                }),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(
                icon: Icons.place_rounded,
                title: 'Situation Points',
              ),
              const SizedBox(height: 12),
              _buildChipsSection(
                items: _situationPoints,
                onDelete: (item) =>
                    setState(() => _situationPoints.remove(item)),
              ),
              const SizedBox(height: 12),
              _buildAddField(
                controller: _situationController,
                focusNode: _situationFocusNode,
                hint: 'Add a situation point...',
                onAdd: _addSituation,
              ),
              const SizedBox(height: 12),
              _buildSuggestedChips(
                suggestions: _suggestedSituations,
                existing: _situationPoints,
                onTap: (situation) => setState(() {
                  if (!_situationPoints.contains(situation)) {
                    _situationPoints.add(situation);
                  }
                }),
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return Center(
      child: GestureDetector(
        onTap: _openEmojiPicker,
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  'Tap to change',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Character Name',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface,
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Enter character name...',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white24,
              ),
              prefixIcon: Icon(
                Icons.person_rounded,
                color: Colors.white54,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildChipsSection({
    required List<String> items,
    required Function(String) onDelete,
  }) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No items added yet',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white24,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Chip(
            label: Text(
              item,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
            onDeleted: () => onDelete(item),
            backgroundColor: Colors.white.withOpacity(0.1),
            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onAdd(),
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, color: Colors.black, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedChips({
    required List<String> suggestions,
    required List<String> existing,
    required Function(String) onTap,
  }) {
    final available =
        suggestions.where((s) => !existing.contains(s)).toList();

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white24,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: available.map((item) {
            return GestureDetector(
              onTap: () => onTap(item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saveCharacter,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing ? Icons.check_rounded : Icons.add_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _isEditing ? 'Update Character' : 'Create Character',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
