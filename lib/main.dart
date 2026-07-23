import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/router_provider.dart';

/// Global key so SnackBars work reliably with GoRouter (esp. web).
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface unexpected errors instead of a blank red screen on web.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[PlatformError] $error\n$stack');
    }
    return true;
  };

  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  String supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (supabaseAnonKey.isEmpty) {
    supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    if (!const bool.fromEnvironment('dart.vm.product')) {
      await dotenv.load(fileName: '.env');
      supabaseUrl = dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'YOUR_SUPABASE_URL',
          );
      supabaseAnonKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
          dotenv.env['SUPABASE_ANON_KEY'] ??
          const String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: 'YOUR_SUPABASE_ANON_KEY',
          );
    }
  }

  if (kDebugMode &&
      (supabaseUrl.contains('YOUR_') ||
          supabaseAnonKey.contains('YOUR_') ||
          supabaseUrl.isEmpty ||
          supabaseAnonKey.isEmpty)) {
    debugPrint(
      '[main] WARNING: Supabase keys are placeholders or empty. '
      'Auth will fail. Use --dart-define or a valid .env.',
    );
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[main] Supabase initialize ERROR: $e');
    }
  }

  runApp(const ProviderScope(child: TheGatheringApp()));
}

class TheGatheringApp extends ConsumerWidget {
  const TheGatheringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stable router — must NOT be recreated when auth loading flips.
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'The Gathering',
      scaffoldMessengerKey: scaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return Material(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Something went wrong.\n${details.exceptionAsString()}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }

  ThemeData _buildLightTheme() {
    const seed = Color(0xFF1E3A5F);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  ThemeData _buildDarkTheme() {
    const seed = Color(0xFF1E3A5F);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }
}
