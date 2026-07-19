import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/chat_providers.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ai_provider_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AIProviderRegistry.initializeDefaults();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = _getThemeMode(settings.themeMode);

    return MaterialApp(
      title: 'Liya',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static ThemeData get _lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainer: Color(0xFFF5F5F5),
          surfaceContainerHighest: Color(0xFFE5E5E5),
          outline: Color(0xFFE0E0E0),
          outlineVariant: Color(0xFFE0E0E0),
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
          titleMedium: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );

  static ThemeData get _darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Color(0xFF111111),
          onSurface: Colors.white,
          surfaceContainer: Color(0xFF1A1A1A),
          surfaceContainerHighest: Color(0xFF2A2A2A),
          outline: Color(0xFF333333),
          outlineVariant: Color(0xFF333333),
          error: Colors.redAccent,
          onError: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFF111111),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF333333),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
}