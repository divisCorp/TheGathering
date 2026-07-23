import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/providers/app_ui_provider.dart';
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/screens/create_event_screen.dart';
import 'package:the_gathering/screens/home_screen.dart';
import 'package:the_gathering/screens/my_activities_screen.dart';
import 'package:the_gathering/screens/profile_screen.dart';

/// Main shell with bottom navigation + sign-out strip.
class MainShell extends ConsumerStatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    CreateEventScreen(),
    MyActivitiesScreen(),
    ProfileScreen(),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  void _onTab(int index) {
    setState(() => _currentIndex = index);
    // Returning to a tab should pick up fresh data.
    if (index == 0) {
      ref.read(discoverRefreshTickProvider.notifier).state++;
    } else if (index == 2) {
      ref.read(activitiesRefreshTickProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authProvider).user?.email;

    return Scaffold(
      floatingActionButton: _currentIndex == 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add),
              label: const Text('Host'),
            ),
      body: Column(
        children: [
          if (email != null && email.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        onPressed: () => context.push('/reports'),
                        child: const Text('Reports'),
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
          Expanded(
            // Keep tab state alive so map/filters don't reset constantly.
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: _onTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'My Activities',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
