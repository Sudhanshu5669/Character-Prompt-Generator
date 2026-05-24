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
                color: AppColors.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
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
                  color: AppColors.cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 20),
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

              // Variations Grid
              _buildVariationsGrid(context, prompt, settingsProvider, generationProvider),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJsonVisualizerCard(Prompt prompt, Map<String, dynamic> json) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
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
                        color: AppColors.secondary,
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
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.secondary),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.secondary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.04)),
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
                              ? AppColors.primary.withOpacity(0.05)
                              : Colors.transparent,
                          border: Border.all(
                            color: isLocked
                                ? AppColors.primary.withOpacity(0.15)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLocked) ...[
                              const Icon(Icons.lock_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '"${entry.key}": ',
                              style: GoogleFonts.firaCode(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLocked ? AppColors.primary : AppColors.secondary,
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
            Container(height: 1, color: Colors.white.withOpacity(0.04)),
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
        color: AppColors.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_rounded,
                  color: AppColors.primary.withOpacity(0.7), size: 20),
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
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Character?>(
                value: _selectedCharacter,
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                hint: Text(
                  'Select a character persona...',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white24),
                ),
                isExpanded: true,
                items: [
                  DropdownMenuItem<Character?>(
                    value: null,
                    child: Text(
                      'None (No character context)',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildGenerationButton(
          title: 'Random',
          subtitle: '5 diverse variations',
          icon: Icons.shuffle_rounded,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _triggerGeneration(
            context,
            prompt,
            settingsProvider,
            generationProvider,
            'random',
          ),
        ),
        _buildGenerationButton(
          title: 'Expression',
          subtitle: 'Emotional variations',
          icon: Icons.sentiment_satisfied_alt_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _triggerGeneration(
            context,
            prompt,
            settingsProvider,
            generationProvider,
            'expression',
          ),
        ),
        _buildGenerationButton(
          title: 'Pose',
          subtitle: 'Action & physical posture',
          icon: Icons.accessibility_new_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF00E676)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _triggerGeneration(
            context,
            prompt,
            settingsProvider,
            generationProvider,
            'pose',
          ),
        ),
        _buildGenerationButton(
          title: 'Environment',
          subtitle: 'Settings & settings sub-venues',
          icon: Icons.map_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF2979FF), Color(0xFF651FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _triggerGeneration(
            context,
            prompt,
            settingsProvider,
            generationProvider,
            'environment',
          ),
        ),
      ],
    );
  }

  Widget _buildGenerationButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient.map((color) => color.withOpacity(0.08)) as Gradient,
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withOpacity(0.15),
                  size: 16,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white38,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _triggerGeneration(
    BuildContext context,
    Prompt prompt,
    SettingsProvider settingsProvider,
    GenerationProvider generationProvider,
    String type,
  ) async {
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
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Trigger variations generation
    await generationProvider.generateVariations(
      prompt: prompt,
      config: settingsProvider.config,
      type: type,
      character: _selectedCharacter,
    );

    if (!context.mounted) return;

    if (generationProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  generationProvider.error!,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (generationProvider.generatedVariations.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.generation);
    }
  }
}

// Helper to support gradient mapping with opacity
extension on Gradient {
  Gradient map(Color Function(Color) mapper) {
    if (this is LinearGradient) {
      final lg = this as LinearGradient;
      return LinearGradient(
        colors: lg.colors.map(mapper).toList(),
        begin: lg.begin,
        end: lg.end,
        stops: lg.stops,
        tileMode: lg.tileMode,
        transform: lg.transform,
      );
    }
    return this;
  }
}
