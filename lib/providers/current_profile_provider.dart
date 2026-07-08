import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_gathering/models/user_profile.dart';
import 'package:the_gathering/services/profiles_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Simple Riverpod provider for the current user's profile.
/// Loads from Supabase on first access and allows refresh after edits.
final currentProfileProvider =
    StateNotifierProvider<CurrentProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => CurrentProfileNotifier(),
);

class CurrentProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  CurrentProfileNotifier() : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await ProfilesService.fetchCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Call this after saving profile in ProfileScreen to refresh everywhere.
  Future<void> refresh() async {
    await _loadProfile();
  }

  /// Quick access to current user id (if authenticated).
  String? get currentUserId => SupabaseService.currentUser?.id;
}
