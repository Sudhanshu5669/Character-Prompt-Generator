# PromptForge — Advanced Features & Monochrome UI Checklist

## 1. Pure Monochrome (Black & White) Visual Overhaul
- [x] Refactor `lib/config/theme.dart`:
  - [x] Set background to pure black (`0xFF000000`) and surface/card to elegant dark gray (`0xFF121212`, `0xFF1A1A1A`)
  - [x] Change primary/secondary/accent colors to absolute white (`0xFFFFFFFF`), light gray (`0xFFE0E0E0`), and medium gray (`0xFF8E8E93`)
  - [x] Remove all gradient decors, radial glows, and neon colors. Change chips, dialogs, lists to solid outlines or flat monochrome fills
- [x] Overhaul `lib/widgets/loading_overlay.dart` to a clean, B&W minimal spinner/pulsing circle (no neon or sweep gradients)
- [x] Audit and remove all gradient text ShaderMasks, linear gradients, and neon colored icons/glows in:
  - [x] `lib/screens/home/home_screen.dart` (App Bar title, bottom navigation, item cards, FAB)
  - [x] `lib/screens/prompt/prompt_detail_screen.dart` (JSON cards, selector fields, 5 variation buttons)
  - [x] `lib/screens/prompt/prompt_editor_screen.dart` (Toggle buttons, key fields, bottom Save button)
  - [x] `lib/screens/generation/generation_screen.dart` (Loader circle, copy all button, action buttons, syntax colors)
  - [x] `lib/screens/characters/character_editor_screen.dart` (Avatar circle, suggestion chips, bottom Save button)

## 2. Clothes Variation Option
- [x] Update `GenerationProvider.generateVariations` to accept `'clothes'` type and `String? clothesInstructions`
- [x] Incorporate clothes instruction logic and randomized outfit prompting in `_buildSystemPrompt()`
- [x] In `prompt_detail_screen.dart`, add a prominent **Clothes** button in the variation grid (making it a 5-button layout: 4 in 2x2 grid, Clothes full-width below it)
- [x] Implement a clean text input dialog when clicking **Clothes** to let the user specify outfits or leave it empty

## 3. AI-Generated Change Titles
- [x] Update system prompt to instruct the AI to return a mandatory `_change_title` key (3-5 words summarizing the change) in each variation object
- [x] Update `generation_screen.dart` to extract `_change_title` and display it as the title/header of each variation card
- [x] Remove `_change_title` from the visualizer's code block for a clean look
- [x] Pre-fill the Prompt name with `_change_title` when the user taps **Save as Prompt** (and strip `_change_title` from the saved JSON payload)

## 4. Reference-Based Variations
- [x] In `prompt_detail_screen.dart`, add a "Reference Prompt (Optional)" dropdown that lists all other saved prompts
- [x] Pass the selected `referencePrompt` to `generateVariations()`
- [x] Update `_buildSystemPrompt()` in `generation_provider.dart` to instruct the AI to generate variations inspired by the reference prompt's values and style while strictly preserving the base prompt's keys and schema (with freedom to add useful fields)

## 5. Multi-Select Prompt Deletion
- [x] Implement multi-select state in `_PromptsTab` inside `home_screen.dart`:
  - [x] Add `bool _isSelectMode = false` and `Set<String> _selectedIds = {}`
  - [x] Update prompt cards `onLongPress` to enter selection mode and `onTap` to toggle selection when in selection mode
  - [x] Display clean checkboxes on card items when in selection mode
  - [x] Dynamically update `SliverAppBar`: when selection mode is active, display the selected count, a Trash button for batch deletion (with confirmation dialog), and a Cancel button to exit selection mode
- [x] In `_confirmDeleteSelected` batch deletion method, delete all selected prompt IDs from `PromptProvider`

## 6. Verification
- [x] Run `flutter analyze` to ensure code is clean of errors and warnings
- [x] Run `flutter test` to ensure JSON utility functions are working properly
- [ ] Build a release APK to verify the final compilation works
