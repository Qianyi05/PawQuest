import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'package:pawquest/providers/daily_quest_provider.dart';
import 'package:pawquest/providers/step_provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/screens/responsive_main_screen.dart'; // Main shell
import 'package:pawquest/screens/splash_screen.dart'; // Launch screen
import 'package:pawquest/screens/login_screen.dart'; // Login screen
import 'package:pawquest/screens/world_map_screen.dart';
import 'package:pawquest/screens/foodsticker_screen.dart';
import 'package:pawquest/screens/weather_screen.dart';
import 'package:pawquest/screens/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (error) {
    debugPrint('Environment file was not loaded: $error');
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  // Initialize StepProvider exactly once.
  final stepProvider = StepProvider();
  final dailyQuestProvider = DailyQuestProvider();
  stepProvider.attachDailyQuestProvider(dailyQuestProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StepProvider>.value(
          value: stepProvider,
        ),
        ChangeNotifierProvider<DailyQuestProvider>.value(
          value: dailyQuestProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const PawQuestApp(),
    ),
  );

  // Firestore may be slow or temporarily unavailable. Loading saved steps
  // must not block Flutter from drawing its first frame.
  unawaited(
    stepProvider.loadSavedSteps().catchError((Object error, StackTrace stack) {
      debugPrint('Failed to load saved steps: $error');
      debugPrintStack(stackTrace: stack);
    }),
  );
}

class PawQuestApp extends StatelessWidget {
  const PawQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().palette;
    return MaterialApp(
      title: 'PawQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(palette),
      initialRoute: '/', // Initial route
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(), // Registered login route
        '/main': (context) =>
            const ResponsiveMainScreen(), // Optional main-shell route
        '/map': (context) => const WorldMapScreen(),
        '/badges': (context) => const FoodStickerScreen(),
        '/weather': (context) => const WeatherScreen(),
      },
    );
  }
}
