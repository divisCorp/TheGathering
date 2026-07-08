import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/event.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_activities_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_event_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try dart-define first (recommended for web builds and production)
  // Fall back to .env for local development (mobile + web dev)
  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  String supabaseAnonKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY') ??
                         const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    await dotenv.load(fileName: '.env');
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_URL');
    supabaseAnonKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
                      dotenv.env['SUPABASE_ANON_KEY'] ??
                      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (_) {
    // In production, use a proper crash reporting service (Sentry, Firebase Crashlytics)
  }

  runApp(const ProviderScope(child: TheGatheringApp()));
}

class TheGatheringApp extends ConsumerWidget {
  const TheGatheringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/auth',
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/auth';

        if (!isAuthenticated && !isAuthRoute) {
          return '/auth';
        }
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainShell(initialTab: 0),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MainShell(initialTab: 3),
        ),
        GoRoute(
          path: '/event',
          builder: (context, state) {
            final event = state.extra as GatheringEvent;
            return EventDetailScreen(event: event);
          },
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
    const seed = Color(0xFF1E3A5F);
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
    const seed = Color(0xFF1E3A5F); // Deep navy base for wholesome dark feel
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

/// Simple main shell with bottom navigation.
/// Tabs: Discover (Home), Create, My Activities (RSVPs + hosted), Profile
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
    MyActivitiesScreen(),   // My Activities - now wired with RSVPs
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



