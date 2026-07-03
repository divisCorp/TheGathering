import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_event_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for Supabase keys (easier than dart-define every time)
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY');

  // Initialize Supabase (PR1: foundational)
  // Wrapped to allow running without valid keys during development
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('WARNING: Supabase init failed (using placeholder keys?): $e');
    print('The app UI should still load. Set real keys in .env for full functionality.');
  }

  runApp(const ProviderScope(child: TheGatheringApp()));
}

class TheGatheringApp extends ConsumerWidget {
  const TheGatheringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainShell(initialTab: 0),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MainShell(initialTab: 3),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'The Gathering',
      themeMode: ThemeMode.dark,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    final seed = const Color(0xFF1E3A5F);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final seed = const Color(0xFF1E3A5F); // Deep navy base for wholesome dark feel
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
      ),
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

/// Simple main shell with bottom navigation for PR2+.
/// Tabs: Discover (Home), Create (stub), My Activities (stub), Profile
class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),           // Discover
    CreateEventScreen(),    // Create (PR3)
    _MyActivitiesStub(),    // My Activities (PR5+)
    ProfileScreen(),        // Profile (PR2)
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Optional: router push if needed for deep linking
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Stub for My Activities (PR5+)
class _MyActivitiesStub extends StatelessWidget {
  const _MyActivitiesStub({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Activities')),
        body: const Center(child: Text('RSVPs and history coming in PR5')),
      );
}

