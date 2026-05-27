import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/config/routes.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/providers/prompt_provider.dart';
import 'package:prompt_generator/providers/character_provider.dart';
import 'package:prompt_generator/providers/settings_provider.dart';
import 'package:prompt_generator/providers/generation_provider.dart';
import 'package:prompt_generator/core/utils/clipboard_utils.dart';
import 'package:prompt_generator/core/utils/json_utils.dart';
import 'package:prompt_generator/widgets/loading_overlay.dart';

class PromptDetailScreen extends StatefulWidget {
  final String promptId;

  const PromptDetailScreen({super.key, required this.promptId});

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  Character? _selectedCharacter;
  String _selectedReferencePromptId = '__none__';

  // Multi-select generation state
  final Set<String> _selectedCategories = {'random'};
  final Map<String, TextEditingController> _hintControllers = {
    'expression': TextEditingController(),
    'pose': TextEditingController(),
    'environment': TextEditingController(),
    'clothes': TextEditingController(),
    'random': TextEditingController(),
  };
  int _promptCount = 5;
  final TextEditingController _additionalContextController = TextEditingController();

  bool _hasNavigatedToGeneration = false;

  GenerationProvider? _generationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<GenerationProvider>();
    if (_generationProvider != provider) {
      _generationProvider?.removeListener(_onGenerationChanged);
      _generationProvider = provider;
      _generationProvider!.addListener(_onGenerationChanged);
    }
  }

  @override
  void dispose() {
    _generationProvider?.removeListener(_onGenerationChanged);
    _additionalContextController.dispose();
    for (final c in _hintControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onGenerationChanged() {
    final provider = _generationProvider;
    if (provider == null || !mounted) return;

    if (!provider.isGenerating && provider.error != null) {
      _showErrorDialog(provider.error!);
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Generation Failed',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            error,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promptProvider = context.watch<PromptProvider>();
    final characterProvider = context.watch<CharacterProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final generationProvider = context.watch<GenerationProvider>();

    final prompt = promptProvider.getById(widget.promptId);

    if (prompt == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Prompt not found',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final jsonContent = prompt.jsonContent;

    // Get all other prompts for reference selection (excluding current)
    final otherPrompts = promptProvider.prompts.where((p) => p.id != widget.promptId).toList();

    return LoadingOverlay(
      isLoading: generationProvider.isGenerating,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            prompt.name,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.promptEditor,
                  arguments: prompt.id,
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JSON Visualizer Card
              _buildJsonVisualizerCard(prompt, jsonContent),
              const SizedBox(height: 24),

              // Reference Prompt Selector
              _buildReferencePromptSelector(otherPrompts),
              const SizedBox(height: 16),

              // Character selector for Context
              _buildCharacterSelector(characterProvider),
              const SizedBox(height: 28),

              // Variation Buttons Grid Header
              Text(
                'Generate Variations',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 14),

              // Variations Grid (2x2) + Clothes button
              _buildVariationsGrid(context, prompt, settingsProvider, generationProvider),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferencePromptSelector(List<Prompt> otherPrompts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_outline_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reference Prompt (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReferencePromptId,
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: '__none__',
                    child: Text(
                      'None (No reference prompt)',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ),
                  ...otherPrompts.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (String? val) {
                  setState(() {
                    _selectedReferencePromptId = val ?? '__none__';
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonVisualizerCard(Prompt prompt, Map<String, dynamic> json) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            key: const ValueKey('json_card_header'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Base Prompt JSON',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    copyToClipboard(prettyJson(json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Copied JSON to clipboard',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.white24,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          // JSON Viewer Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: json.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Empty JSON prompt. Tap edit to add fields.',
                        style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: json.entries.map((entry) {
                      final isLocked = prompt.lockedFields.contains(entry.key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isLocked
                              ? Colors.white.withOpacity(0.05)
                              : Colors.transparent,
                          border: Border.all(
                            color: isLocked
                                ? Colors.white.withOpacity(0.15)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLocked) ...[
                              const Icon(Icons.lock_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '"${entry.key}": ',
                              style: GoogleFonts.firaCode(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLocked ? Colors.white70 : Colors.white54,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '"${entry.value}"',
                                style: GoogleFonts.firaCode(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          if (prompt.manualInstructions != null && prompt.manualInstructions!.trim().isNotEmpty) ...[
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Instructions:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prompt.manualInstructions!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterSelector(CharacterProvider characterProvider) {
    final characters = characterProvider.characters;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Character Context (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Character?>(
                value: _selectedCharacter,
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<Character?>(
                    value: null,
                    child: Text(
                      'None (No character context)',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ),
                  ...characters.map((char) {
                    return DropdownMenuItem<Character?>(
                      value: char,
                      child: Row(
                        children: [
                          Text(
                            char.avatarEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            char.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (Character? val) {
                  setState(() {
                    _selectedCharacter = val;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsGrid(
    BuildContext context,
    Prompt prompt,
    SettingsProvider settingsProvider,
    GenerationProvider generationProvider,
  ) {
    const categories = [
      {'id': 'expression', 'label': 'Expression', 'icon': Icons.sentiment_satisfied_alt_rounded, 'hint': 'e.g., laughing, contemplative, fierce...'},
      {'id': 'pose',       'label': 'Pose',       'icon': Icons.accessibility_new_rounded,       'hint': 'e.g., sitting, jumping, arms crossed...'},
      {'id': 'environment','label': 'Environment','icon': Icons.landscape_rounded,               'hint': 'e.g., rooftop at night, forest, neon alley...'},
      {'id': 'clothes',    'label': 'Clothes',    'icon': Icons.checkroom_rounded,               'hint': 'e.g., evening dress, streetwear, armour...'},
      {'id': 'random',     'label': 'Random',     'icon': Icons.shuffle_rounded,                 'hint': 'Optional direction hint...'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category chips ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final id = cat['id'] as String;
            final label = cat['label'] as String;
            final icon = cat['icon'] as IconData;
            final selected = _selectedCategories.contains(id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedCategories.remove(id);
                  } else {
                    // Deselect 'random' when picking specific cats and vice-versa
                    if (id == 'random') {
                      _selectedCategories.clear();
                    } else {
                      _selectedCategories.remove('random');
                    }
                    _selectedCategories.add(id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected ? Colors.white : AppColors.cardColor,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
                    width: selected ? 0 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: selected ? Colors.black : Colors.white54),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.black : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ── Per-category hint fields (only for selected) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: _selectedCategories.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: _selectedCategories.map((id) {
                    final cat = categories.firstWhere((c) => c['id'] == id);
                    final label = cat['label'] as String;
                    final hint = cat['hint'] as String;
                    final icon = cat['icon'] as IconData;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.cardColor,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 15, color: Colors.white54),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'optional hint',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _hintControllers[id],
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: hint,
                              hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        // ── Count stepper ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.cardColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded, size: 18, color: Colors.white54),
              const SizedBox(width: 10),
              Text(
                'Prompts to generate',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () { if (_promptCount > 1) setState(() => _promptCount--); },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 18, color: Colors.white70),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$_promptCount',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () { if (_promptCount < 20) setState(() => _promptCount++); },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Additional Context field ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.cardColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    'Additional Context',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'optional',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _additionalContextController,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'e.g., keep the lighting warm, avoid outdoor scenes, use realistic style...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Generate button ──
        GestureDetector(
          onTap: _selectedCategories.isEmpty
              ? null
              : () => _triggerGeneration(context, prompt, settingsProvider, generationProvider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _selectedCategories.isEmpty ? Colors.white12 : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _selectedCategories.isEmpty ? Colors.white38 : Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedCategories.isEmpty ? 'Select a category' : 'Generate  $_promptCount prompt${_promptCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _selectedCategories.isEmpty ? Colors.white38 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _triggerGeneration(
    BuildContext context,
    Prompt prompt,
    SettingsProvider settingsProvider,
    GenerationProvider generationProvider,
  ) {
    _hasNavigatedToGeneration = false;

    if (!settingsProvider.hasValidApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Please configure an API key in Settings first',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Resolve reference prompt from ID
    Prompt? referencePrompt;
    if (_selectedReferencePromptId != '__none__') {
      referencePrompt = context.read<PromptProvider>().getById(_selectedReferencePromptId);
    }

    // Build selectedCategories map from UI state
    final Map<String, String> selectedCategories = {
      for (final cat in _selectedCategories)
        cat: _hintControllers[cat]?.text.trim() ?? '',
    };

    // If somehow empty, default to random
    if (selectedCategories.isEmpty) {
      selectedCategories['random'] = '';
    }

    final additionalContext = _additionalContextController.text.trim();

    // Navigate immediately to allow the user to watch prompt variations stream in real-time
    Navigator.pushNamed(context, AppRoutes.generation);

    generationProvider.generateVariations(
      prompt: prompt,
      config: settingsProvider.config,
      selectedCategories: selectedCategories,
      character: _selectedCharacter,
      additionalContext: additionalContext.isNotEmpty ? additionalContext : null,
      referencePrompt: referencePrompt,
      count: _promptCount,
    );
  }
}
