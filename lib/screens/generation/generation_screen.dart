import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/core/utils/clipboard_utils.dart';
import 'package:prompt_generator/core/utils/json_utils.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/providers/generation_provider.dart';
import 'package:prompt_generator/providers/prompt_provider.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _copyAll(List<Map<String, dynamic>> variations) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(variations);
    copyToClipboard(jsonStr);
    _showCopySnackbar('All variations copied to clipboard');
  }

  void _copySingle(Map<String, dynamic> variation) {
    final jsonStr = prettyJson(variation);
    copyToClipboard(jsonStr);
    _showCopySnackbar('Variation copied to clipboard');
  }

  void _showCopySnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: GoogleFonts.inter(fontSize: 14)),
          ],
        ),
        backgroundColor: AppColors.primary.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _saveAsPrompt(Map<String, dynamic> variation, int index) {
    final promptProvider = context.read<PromptProvider>();
    final prompt = Prompt(
      id: const Uuid().v4(),
      name: 'Generated Variation ${index + 1}',
      jsonContentRaw: const JsonEncoder.withIndent('  ').convert(variation),
      lockedFields: [],
      manualInstructions: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    promptProvider.addPrompt(prompt);
    _showCopySnackbar('Saved as new prompt: "${prompt.name}"');
  }

  Color _accentColorForIndex(int index) {
    const colors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Generated Variations',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<GenerationProvider>(
            builder: (context, provider, _) {
              if (provider.generatedVariations.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.copy_all_rounded),
                  tooltip: 'Copy All',
                  onPressed: () => _copyAll(provider.generatedVariations),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<GenerationProvider>(
        builder: (context, provider, _) {
          if (provider.isGenerating) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          if (provider.generatedVariations.isEmpty) {
            return _buildEmptyState();
          }

          return _buildVariationsList(provider.generatedVariations);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotateController]),
            builder: (context, child) {
              final scale = 0.85 + (_pulseController.value * 0.3);
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                          AppColors.tertiary,
                          AppColors.primary,
                        ],
                        stops: const [0.0, 0.33, 0.66, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4 * _pulseController.value),
                          blurRadius: 30 + (20 * _pulseController.value),
                          spreadRadius: 5 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary.withOpacity(0.7 + (0.3 * _pulseController.value)),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              final dotCount = (_dotsController.value * 4).floor() % 4;
              final dots = '.' * dotCount;
              return Text(
                'Generating variations$dots',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.3,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(AppColors.primary, AppColors.secondary, _pulseController.value)!,
                  ),
                  borderRadius: BorderRadius.circular(4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.cardColor,
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Generation Failed',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppColors.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No variations generated yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsList(List<Map<String, dynamic>> variations) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: variations.length,
          itemBuilder: (context, index) {
            return _AnimatedVariationCard(
              index: index,
              variation: variations[index],
              accentColor: _accentColorForIndex(index),
              onCopy: () => _copySingle(variations[index]),
              onSave: () => _saveAsPrompt(variations[index], index),
            );
          },
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _buildCopyAllButton(variations),
        ),
      ],
    );
  }

  Widget _buildCopyAllButton(List<Map<String, dynamic>> variations) {
    return Container(
      decoration: AppDecorations.accentGradient.copyWith(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _copyAll(variations),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy_all_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Copy All Variations',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _AnimatedVariationCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> variation;
  final Color accentColor;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  const _AnimatedVariationCard({
    required this.index,
    required this.variation,
    required this.accentColor,
    required this.onCopy,
    required this.onSave,
  });

  @override
  State<_AnimatedVariationCard> createState() => _AnimatedVariationCardState();
}

class _AnimatedVariationCardState extends State<_AnimatedVariationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleCopy() {
    widget.onCopy();
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppDecorations.glassmorphicCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildJsonBody(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            margin: const EdgeInsets.only(left: 0),
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.accentColor.withOpacity(0.15),
            ),
            child: Text(
              'Variation ${widget.index + 1}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonBody() {
    final jsonStr = prettyJson(widget.variation);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildSyntaxHighlightedJson(jsonStr),
      ),
    );
  }

  Widget _buildSyntaxHighlightedJson(String jsonStr) {
    final spans = <TextSpan>[];
    final lines = jsonStr.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      _parseLine(line, spans);
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  void _parseLine(String line, List<TextSpan> spans) {
    final keyValueRegex = RegExp(r'^(\s*)"([^"]+)"(\s*:\s*)(.*)$');
    final match = keyValueRegex.firstMatch(line);

    if (match != null) {
      final indent = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final colon = match.group(3) ?? '';
      final value = match.group(4) ?? '';

      if (indent.isNotEmpty) {
        spans.add(TextSpan(
          text: indent,
          style: const TextStyle(color: Colors.transparent),
        ));
      }
      spans.add(TextSpan(
        text: '"',
        style: TextStyle(color: Colors.white.withOpacity(0.3)),
      ));
      spans.add(TextSpan(
        text: key,
        style: const TextStyle(color: AppColors.primary),
      ));
      spans.add(TextSpan(
        text: '"',
        style: TextStyle(color: Colors.white.withOpacity(0.3)),
      ));
      spans.add(TextSpan(
        text: colon,
        style: TextStyle(color: Colors.white.withOpacity(0.3)),
      ));
      _parseValue(value, spans);
    } else {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        spans.add(const TextSpan(text: ''));
      } else if (_isPunctuation(trimmed)) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: Colors.white.withOpacity(0.3)),
        ));
      } else {
        _parseValue(line, spans);
      }
    }
  }

  bool _isPunctuation(String text) {
    final cleaned = text.replaceAll(RegExp(r'[\s,]'), '');
    return cleaned == '{' ||
        cleaned == '}' ||
        cleaned == '[' ||
        cleaned == ']' ||
        cleaned == '{,' ||
        cleaned == '},' ||
        cleaned == '[,' ||
        cleaned == '],';
  }

  void _parseValue(String value, List<TextSpan> spans) {
    final trimmed = value.trim();
    if (trimmed.startsWith('"')) {
      spans.add(TextSpan(
        text: value,
        style: const TextStyle(color: Colors.white70),
      ));
    } else if (trimmed == '{' ||
        trimmed == '[' ||
        trimmed == '{,' ||
        trimmed == '[,' ||
        trimmed == '}' ||
        trimmed == ']' ||
        trimmed == '},' ||
        trimmed == '],') {
      spans.add(TextSpan(
        text: value,
        style: TextStyle(color: Colors.white.withOpacity(0.3)),
      ));
    } else if (trimmed == 'true' ||
        trimmed == 'false' ||
        trimmed == 'true,' ||
        trimmed == 'false,') {
      spans.add(TextSpan(
        text: value,
        style: TextStyle(color: AppColors.secondary),
      ));
    } else if (trimmed == 'null' || trimmed == 'null,') {
      spans.add(TextSpan(
        text: value,
        style: TextStyle(color: AppColors.tertiary.withOpacity(0.7)),
      ));
    } else {
      spans.add(TextSpan(
        text: value,
        style: TextStyle(color: AppColors.secondary),
      ));
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isCopied
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: _isCopied
                      ? Colors.green.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _handleCopy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isCopied
                                ? Icons.check_circle_rounded
                                : Icons.copy_rounded,
                            key: ValueKey(_isCopied),
                            size: 16,
                            color: _isCopied ? Colors.green : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isCopied ? 'Copied!' : 'Copy',
                            key: ValueKey(_isCopied),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isCopied ? Colors.green : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor.withOpacity(0.3),
                    widget.accentColor.withOpacity(0.15),
                  ],
                ),
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: widget.onSave,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_alt_rounded,
                            size: 16, color: widget.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'Save as Prompt',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
