import 'package:flutter/foundation.dart';
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

/// Global key so SnackBars work reliably with GoRouter (esp. web).
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer dart-define (web/prod builds); fall back to .env for local dev.
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
    // Continue; API calls surface errors in the UI.
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

        if (!isAuthenticated && !isAuthRoute) return '/auth';
        if (isAuthenticated && isAuthRoute) return '/home';
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
      scaffoldMessengerKey: scaffoldMessengerKey,
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
class MainShell extends ConsumerStatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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

  Future<void> _quickSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Clear this login so someone else can create or use their own account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authProvider).user?.email;

    return Scaffold(
      body: Column(
        children: [
          if (email != null && email.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Logged in: $email',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _quickSignOut,
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: (index) {
          setState(() => _currentIndex = index);
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



