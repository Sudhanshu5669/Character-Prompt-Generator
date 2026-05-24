import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/providers/prompt_provider.dart';
import 'package:prompt_generator/core/utils/json_utils.dart';

class PromptEditorScreen extends StatefulWidget {
  const PromptEditorScreen({super.key});

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _jsonController;
  late final TextEditingController _instructionsController;
  late final AnimationController _switchAnimController;

  bool _isJsonView = false;
  bool _isEditing = false;
  String? _editingPromptId;
  bool _jsonValid = true;

  final List<_FieldEntry> _fields = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _jsonController = TextEditingController();
    _instructionsController = TextEditingController();
    _switchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditing) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _editingPromptId = args;
        _isEditing = true;
        _loadPromptData(args);
      }
    }
  }

  void _loadPromptData(String promptId) {
    final provider = context.read<PromptProvider>();
    final prompt = provider.getById(promptId);
    if (prompt != null) {
      _nameController.text = prompt.name;
      _instructionsController.text = prompt.manualInstructions ?? '';

      _fields.clear();
      if (prompt.jsonContent is Map<String, dynamic>) {
        final map = prompt.jsonContent as Map<String, dynamic>;
        map.forEach((key, value) {
          _fields.add(_FieldEntry(
            keyController: TextEditingController(text: key),
            valueController: TextEditingController(text: value.toString()),
            isLocked: prompt.lockedFields.contains(key),
          ));
        });
      }
      _syncFieldsToJson();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jsonController.dispose();
    _instructionsController.dispose();
    _switchAnimController.dispose();
    for (final f in _fields) {
      f.keyController.dispose();
      f.valueController.dispose();
    }
    super.dispose();
  }

  void _syncFieldsToJson() {
    final map = <String, dynamic>{};
    for (final f in _fields) {
      final key = f.keyController.text.trim();
      if (key.isNotEmpty) {
        map[key] = f.valueController.text;
      }
    }
    _jsonController.text = prettyJson(map);
    _jsonValid = true;
  }

  void _syncJsonToFields() {
    final parsed = tryParseJson(_jsonController.text);
    if (parsed == null) {
      setState(() => _jsonValid = false);
      return;
    }
    setState(() => _jsonValid = true);
    final lockedKeys = _fields
        .where((f) => f.isLocked)
        .map((f) => f.keyController.text.trim())
        .toSet();

    for (final f in _fields) {
      f.keyController.dispose();
      f.valueController.dispose();
    }
    _fields.clear();

    if (parsed is Map<String, dynamic>) {
      parsed.forEach((key, value) {
        _fields.add(_FieldEntry(
          keyController: TextEditingController(text: key),
          valueController: TextEditingController(text: value.toString()),
          isLocked: lockedKeys.contains(key),
        ));
      });
    }
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldEntry(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
        isLocked: false,
      ));
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].keyController.dispose();
      _fields[index].valueController.dispose();
      _fields.removeAt(index);
    });
  }

  void _toggleLock(int index) {
    setState(() {
      _fields[index].isLocked = !_fields[index].isLocked;
    });
  }

  void _toggleView() {
    setState(() {
      if (_isJsonView) {
        _syncJsonToFields();
        _isJsonView = false;
        _switchAnimController.reverse();
      } else {
        _syncFieldsToJson();
        _isJsonView = true;
        _switchAnimController.forward();
      }
    });
  }

  void _validateJson() {
    final valid = isValidJson(_jsonController.text);
    setState(() => _jsonValid = valid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              valid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              valid ? 'Valid JSON ✓' : 'Invalid JSON — please fix syntax errors',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: valid ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _savePrompt() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Please enter a prompt name',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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

    if (_isJsonView) {
      _syncJsonToFields();
      if (!_jsonValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Please fix JSON errors before saving',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    final jsonContent = <String, dynamic>{};
    final lockedFields = <String>[];

    for (final field in _fields) {
      final key = field.keyController.text.trim();
      if (key.isNotEmpty) {
        jsonContent[key] = field.valueController.text;
        if (field.isLocked) {
          lockedFields.add(key);
        }
      }
    }

    final provider = context.read<PromptProvider>();
    final now = DateTime.now();

    if (_editingPromptId != null) {
      final existingPrompt = provider.getById(_editingPromptId!);
      if (existingPrompt != null) {
        final updated = existingPrompt.copyWith(
          name: _nameController.text.trim(),
          jsonContent: jsonContent,
          lockedFields: lockedFields,
          manualInstructions: _instructionsController.text.trim(),
          updatedAt: now,
        );
        provider.updatePrompt(updated);
      }
    } else {
      final prompt = Prompt(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        jsonContentRaw: jsonEncode(jsonContent),
        lockedFields: lockedFields,
        manualInstructions: _instructionsController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      provider.addPrompt(prompt);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _editingPromptId != null ? 'Edit Prompt' : 'New Prompt',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prompt Name
                    _buildLabel('Prompt Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Enter prompt name...',
                      maxLines: 1,
                    ),

                    const SizedBox(height: 24),

                    // View Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fields',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildViewToggle(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Form or JSON view
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _isJsonView
                          ? _buildJsonView()
                          : _buildFormView(),
                    ),

                    const SizedBox(height: 24),

                    // Manual Instructions
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.cardColor.withOpacity(0.5),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          leading: Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.primary.withOpacity(0.7),
                            size: 22,
                          ),
                          title: Text(
                            'Manual Instructions',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          iconColor: Colors.white38,
                          collapsedIconColor: Colors.white38,
                          children: [
                            _buildTextField(
                              controller: _instructionsController,
                              hint: 'Add any special instructions for AI generation...',
                              maxLines: 5,
                              minLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
            ),
            child: GestureDetector(
              onTap: _savePrompt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        _editingPromptId != null ? 'Update Prompt' : 'Save Prompt',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isJsonView ? _toggleView : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: !_isJsonView ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_list_rounded,
                    size: 16,
                    color: !_isJsonView ? AppColors.primary : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Form',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: !_isJsonView ? FontWeight.w600 : FontWeight.w400,
                      color: !_isJsonView ? AppColors.primary : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: !_isJsonView ? _toggleView : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isJsonView ? AppColors.secondary.withOpacity(0.2) : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.data_object_rounded,
                    size: 16,
                    color: _isJsonView ? AppColors.secondary : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'JSON',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _isJsonView ? FontWeight.w600 : FontWeight.w400,
                      color: _isJsonView ? AppColors.secondary : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      key: const ValueKey('form_view'),
      children: [
        ...List.generate(_fields.length, (index) {
          final field = _fields[index];
          return AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: field.isLocked
                      ? AppColors.primary.withOpacity(0.06)
                      : AppColors.cardColor.withOpacity(0.4),
                  border: Border.all(
                    color: field.isLocked
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.white.withOpacity(0.04),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: field.keyController,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Field name',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.06),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: TextField(
                        controller: field.valueController,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Value',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _toggleLock(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: field.isLocked
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                          boxShadow: field.isLocked
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          field.isLocked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 18,
                          color: field.isLocked
                              ? AppColors.primary
                              : Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: () => _removeField(index),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: AppColors.tertiary.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Add Field button
        GestureDetector(
          onTap: _addField,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Field',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJsonView() {
    return Column(
      key: const ValueKey('json_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            border: Border.all(
              color: _jsonValid
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.tertiary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _jsonController,
            maxLines: 15,
            minLines: 8,
            style: GoogleFonts.firaCode(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: '{\n  "key": "value"\n}',
              hintStyle: GoogleFonts.firaCode(
                fontSize: 13,
                color: Colors.white.withOpacity(0.15),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (!_jsonValid)
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppColors.tertiary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Invalid JSON syntax',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),
            GestureDetector(
              onTap: _validateJson,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Validate',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white60,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.2),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FieldEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;
  bool isLocked;

  _FieldEntry({
    required this.keyController,
    required this.valueController,
    required this.isLocked,
  });
}
