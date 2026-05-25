import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:prompt_generator/config/routes.dart';
import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/providers/prompt_provider.dart';
import 'package:prompt_generator/providers/character_provider.dart';
import 'package:prompt_generator/providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    if (index < 2) {
      _fabAnimController.reset();
      _fabAnimController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: const [
          _PromptsTab(),
          _CharactersTab(),
          _SettingsTab(),
        ],
      ),
      floatingActionButton: _currentIndex < 2
          ? ScaleTransition(
              scale: _fabScaleAnim,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    if (_currentIndex == 0) {
                      Navigator.pushNamed(context, AppRoutes.promptEditor);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.characterEditor);
                    }
                  },
                  backgroundColor: Colors.white,
                  elevation: 0,
                  hoverElevation: 0,
                  focusElevation: 0,
                  highlightElevation: 0,
                  child: const Icon(Icons.add_rounded, size: 28, color: Colors.black),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.article_rounded,
                label: 'Prompts',
                isSelected: _currentIndex == 0,
                onTap: () => _onTabChanged(0),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Characters',
                isSelected: _currentIndex == 1,
                onTap: () => _onTabChanged(1),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: _currentIndex == 2,
                onTap: () => _onTabChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white38,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white38,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              width: isSelected ? 20 : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isSelected ? Colors.white70 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROMPTS TAB
// ─────────────────────────────────────────────
class _PromptsTab extends StatefulWidget {
  const _PromptsTab();

  @override
  State<_PromptsTab> createState() => _PromptsTabState();
}

class _PromptsTabState extends State<_PromptsTab> with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;
  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listAnimController.forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  void _enterSelectMode(String promptId) {
    setState(() {
      _isSelectMode = true;
      _selectedIds = {promptId};
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds = {};
    });
  }

  void _toggleSelection(String promptId) {
    setState(() {
      if (_selectedIds.contains(promptId)) {
        _selectedIds.remove(promptId);
        if (_selectedIds.isEmpty) {
          _isSelectMode = false;
        }
      } else {
        _selectedIds.add(promptId);
      }
    });
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete $count Prompt${count == 1 ? '' : 's'}',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete $count selected prompt${count == 1 ? '' : 's'}? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final provider = context.read<PromptProvider>();
      for (final id in _selectedIds) {
        provider.deletePrompt(id);
      }
      _exitSelectMode();
    }
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final m = diff.inDays ~/ 30;
      return '$m month${m == 1 ? '' : 's'} ago';
    }
    final y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }

  Future<void> _confirmDelete(BuildContext context, Prompt prompt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Prompt',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${prompt.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<PromptProvider>().deletePrompt(prompt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptProvider>(
      builder: (context, provider, _) {
        final prompts = provider.prompts;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              toolbarHeight: 70,
              title: _isSelectMode
                  ? Text(
                      '${_selectedIds.length} selected',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'PromptForge',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
              actions: _isSelectMode
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                        tooltip: 'Delete Selected',
                        onPressed: () => _confirmDeleteSelected(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        tooltip: 'Cancel Selection',
                        onPressed: _exitSelectMode,
                      ),
                    ]
                  : [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          '${prompts.length} prompt${prompts.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
            ),
            if (prompts.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(context))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final prompt = prompts[index];
                      final delay = index * 0.1;
                      final itemAnim = CurvedAnimation(
                        parent: _listAnimController,
                        curve: Interval(
                          (delay).clamp(0.0, 1.0),
                          (delay + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(itemAnim),
                        child: FadeTransition(
                          opacity: itemAnim,
                          child: _buildPromptCard(context, prompt),
                        ),
                      );
                    },
                    childCount: prompts.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 56,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Prompts Yet',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first prompt to get started\nwith AI-powered generation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.promptEditor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Create Prompt',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, Prompt prompt) {
    final Map<String, dynamic> fields = prompt.jsonContent;
    final fieldCount = fields.length;
    final lockedCount = prompt.lockedFields.length;
    final isSelected = _selectedIds.contains(prompt.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _isSelectMode
            ? () => _toggleSelection(prompt.id)
            : () => Navigator.pushNamed(
                  context,
                  AppRoutes.promptDetail,
                  arguments: prompt.id,
                ),
        onLongPress: _isSelectMode
            ? null
            : () => _enterSelectMode(prompt.id),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? Colors.white.withOpacity(0.12)
                : AppColors.cardColor,
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (_isSelectMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 16),
              ],
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Icon(
                    Icons.data_object_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(
                          '$fieldCount field${fieldCount == 1 ? '' : 's'}',
                        ),
                        const SizedBox(width: 8),
                        if (lockedCount > 0)
                          _buildChip(
                            '$lockedCount locked',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isSelectMode) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(prompt.updatedAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white60,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHARACTERS TAB
// ─────────────────────────────────────────────
class _CharactersTab extends StatefulWidget {
  const _CharactersTab();

  @override
  State<_CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<_CharactersTab> with SingleTickerProviderStateMixin {
  late AnimationController _gridAnimController;

  @override
  void initState() {
    super.initState();
    _gridAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _gridAnimController.forward();
  }

  @override
  void dispose() {
    _gridAnimController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteCharacter(BuildContext context, Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Character',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete "${character.name}"? This cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CharacterProvider>().deleteCharacter(character.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterProvider>(
      builder: (context, provider, _) {
        final characters = provider.characters;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              toolbarHeight: 70,
              title: Text(
                'Characters',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '${characters.length} character${characters.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (characters.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(context))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final character = characters[index];
                      final delay = index * 0.08;
                      final itemAnim = CurvedAnimation(
                        parent: _gridAnimController,
                        curve: Interval(
                          (delay).clamp(0.0, 1.0),
                          (delay + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      return ScaleTransition(
                        scale: itemAnim,
                        child: FadeTransition(
                          opacity: itemAnim,
                          child: _buildCharacterCard(context, character),
                        ),
                      );
                    },
                    childCount: characters.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Characters Yet',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create characters with unique personalities\nto enrich your prompt generation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.characterEditor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Create Character',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character character) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.characterEditor,
        arguments: character.id,
      ),
      onLongPress: () => _confirmDeleteCharacter(context, character),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.cardColor,
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  character.avatarEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              character.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: character.personalityTraits
                    .take(3)
                    .map((trait) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Text(
                            trait,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _showGeminiKey = false;
  bool _showFireworksKey = false;
  bool _isTesting = false;

  late TextEditingController _geminiKeyController;
  late TextEditingController _fireworksKeyController;
  late TextEditingController _geminiModelController;
  late TextEditingController _fireworksModelController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _geminiKeyController = TextEditingController(text: settings.config.geminiApiKey ?? '');
    _fireworksKeyController = TextEditingController(text: settings.config.fireworksApiKey ?? '');
    _geminiModelController = TextEditingController(text: settings.config.geminiModel ?? '');
    _fireworksModelController = TextEditingController(text: settings.config.fireworksModel ?? '');
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _fireworksKeyController.dispose();
    _geminiModelController.dispose();
    _fireworksModelController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      final settings = context.read<SettingsProvider>();
      await settings.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Connection successful!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.white24,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connection failed: ${e.toString()}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isGemini = settings.config.activeProvider == 'gemini';
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              toolbarHeight: 70,
              title: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.cardColor,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'API Configuration',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Get your Gemini API key from Google AI Studio (aistudio.google.com) or your Fireworks API key from fireworks.ai. Enter your key below to enable AI generation.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white54,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Provider selector
                  Text(
                    'AI Provider',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.cardColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => settings.setActiveProvider('gemini'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isGemini ? Colors.white : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Gemini',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isGemini ? FontWeight.w600 : FontWeight.w400,
                                    color: isGemini ? Colors.black : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => settings.setActiveProvider('fireworks'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: !isGemini ? Colors.white : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Fireworks',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: !isGemini ? FontWeight.w600 : FontWeight.w400,
                                    color: !isGemini ? Colors.black : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Gemini section
                  _buildSectionHeader('Gemini Configuration'),
                  const SizedBox(height: 12),
                  _buildSettingsField(
                    label: 'API Key',
                    controller: _geminiKeyController,
                    obscure: !_showGeminiKey,
                    hint: 'Enter your Gemini API key',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showGeminiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showGeminiKey = !_showGeminiKey),
                    ),
                    onChanged: (val) => settings.setGeminiApiKey(val),
                  ),
                  const SizedBox(height: 14),
                  _buildSettingsField(
                    label: 'Model Name',
                    controller: _geminiModelController,
                    hint: 'e.g., gemini-2.0-flash',
                    onChanged: (val) => settings.setGeminiModel(val),
                  ),

                  const SizedBox(height: 28),

                  // Fireworks section
                  _buildSectionHeader('Fireworks Configuration'),
                  const SizedBox(height: 12),
                  _buildSettingsField(
                    label: 'API Key',
                    controller: _fireworksKeyController,
                    obscure: !_showFireworksKey,
                    hint: 'Enter your Fireworks API key',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showFireworksKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showFireworksKey = !_showFireworksKey),
                    ),
                    onChanged: (val) => settings.setFireworksApiKey(val),
                  ),
                  const SizedBox(height: 14),
                  _buildSettingsField(
                    label: 'Model Name',
                    controller: _fireworksModelController,
                    hint: 'e.g., accounts/fireworks/models/llama-v3p1-8b-instruct',
                    onChanged: (val) => settings.setFireworksModel(val),
                  ),

                  const SizedBox(height: 32),

                  // Test connection button
                  GestureDetector(
                    onTap: _isTesting ? null : _testConnection,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _isTesting ? Colors.white12 : Colors.white,
                      ),
                      child: Center(
                        child: _isTesting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Testing...',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_tethering_rounded, color: Colors.black, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Test Connection',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Version info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'PromptForge',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
