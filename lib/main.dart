import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:prompt_generator/config/routes.dart';
import 'package:prompt_generator/config/theme.dart';
import 'package:prompt_generator/models/prompt.dart';
import 'package:prompt_generator/models/character.dart';
import 'package:prompt_generator/models/generated_prompt.dart';
import 'package:prompt_generator/models/api_config.dart';
import 'package:prompt_generator/providers/prompt_provider.dart';
import 'package:prompt_generator/providers/character_provider.dart';
import 'package:prompt_generator/providers/generation_provider.dart';
import 'package:prompt_generator/providers/settings_provider.dart';
import 'package:prompt_generator/screens/home/home_screen.dart';
import 'package:prompt_generator/screens/prompt/prompt_editor_screen.dart';
import 'package:prompt_generator/screens/prompt/prompt_detail_screen.dart';
import 'package:prompt_generator/screens/generation/generation_screen.dart';
import 'package:prompt_generator/screens/characters/character_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  Hive.registerAdapter(PromptAdapter());
  Hive.registerAdapter(CharacterAdapter());
  Hive.registerAdapter(GeneratedPromptAdapter());
  Hive.registerAdapter(ApiConfigAdapter());

  await Future.wait([
    Hive.openBox<Prompt>('prompts'),
    Hive.openBox<Character>('characters'),
    Hive.openBox<GeneratedPrompt>('generated_prompts'),
    Hive.openBox<ApiConfig>('settings'),
  ]);

  runApp(const PromptGeneratorApp());
}

class PromptGeneratorApp extends StatelessWidget {
  const PromptGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PromptProvider>(
          create: (_) => PromptProvider()..loadPrompts(),
        ),
        ChangeNotifierProvider<CharacterProvider>(
          create: (_) => CharacterProvider()..loadCharacters(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider<GenerationProvider>(
          create: (_) => GenerationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'PromptForge',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.home,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case AppRoutes.home:
        page = const HomeScreen();
        break;
      case AppRoutes.promptEditor:
        page = const PromptEditorScreen();
        break;
      case AppRoutes.promptDetail:
        final id = settings.arguments as String;
        page = PromptDetailScreen(promptId: id);
        break;
      case AppRoutes.generation:
        page = const GenerationScreen();
        break;
      case AppRoutes.characterEditor:
        final id = settings.arguments as String?;
        page = CharacterEditorScreen(characterId: id);
        break;
      default:
        page = const HomeScreen();
    }

    return _buildSlideRoute(page, settings);
  }

  static PageRouteBuilder<dynamic> _buildSlideRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.6, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}
