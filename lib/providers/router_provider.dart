import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/screens/auth_screen.dart';
import 'package:the_gathering/screens/event_detail_screen.dart';
import 'package:the_gathering/screens/main_shell.dart';
import 'package:the_gathering/screens/reports_inbox_screen.dart';

/// Notifies GoRouter when auth changes — without recreating the router.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

/// Stable GoRouter instance. Creating a new GoRouter on every auth rebuild
/// was wiping AuthScreen state mid-signup (Create Account looked like a no-op).
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuthenticated = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/auth';

      if (!isAuthenticated && !isAuthRoute) return '/auth';
      // Only leave auth after a real session — not while typing/submitting.
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
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsInboxScreen(),
      ),
    ],
  );
});
