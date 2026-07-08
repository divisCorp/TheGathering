import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_gathering/models/user_profile.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Service for user profile CRUD (PR2).
/// Uses Supabase profiles table + Storage for avatars.
/// Matches RLS policies (users manage own profile).
class ProfilesService {
  static final _client = SupabaseService.client;

  /// Fetch the current user's profile from DB.
  /// Falls back to metadata + defaults if no row yet.
  static Future<UserProfile?> fetchCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        // Merge some auth data
        final profile = UserProfile.fromSupabase(response);
        return UserProfile(
          id: profile.id,
          email: user.email ?? profile.email,
          phone: user.phone ?? profile.phone,
          displayName: profile.displayName,
          ageRange: profile.ageRange,
          bio: profile.bio,
          interests: profile.interests,
          city: profile.city,
          ward: profile.ward,
          stake: profile.stake,
          isVerifiedMember: profile.isVerifiedMember,
          avatarUrl: profile.avatarUrl,
          createdAt: profile.createdAt,
        );
      }
    } catch (_) {
      // Table may not exist or RLS issue in early setup
    }

    // Fallback from user metadata + defaults (from PR1 signup)
    final meta = user.userMetadata ?? {};
    return UserProfile(
      id: user.id,
      email: user.email,
      phone: meta['phone'] as String?,
      displayName: meta['display_name'] as String? ?? user.email?.split('@').first ?? 'Member',
      interests: (meta['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      isVerifiedMember: meta['is_verified_member'] as bool? ?? false,
      avatarUrl: null,
      createdAt: DateTime.parse(user.createdAt as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Upsert full profile data.
  /// Also updates some user metadata for backward compat.
  static Future<UserProfile> saveProfile(UserProfile profile) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = profile.toSupabase();
    // Ensure id matches auth user
    data['id'] = user.id;

    final response = await _client
        .from('profiles')
        .upsert(data)
        .select()
        .single();

    // Also sync key fields to auth metadata (used in signup flow)
    await SupabaseService.updateUserMetadata({
      'display_name': profile.displayName,
      'interests': profile.interests,
      'city': profile.city,
      'is_verified_member': profile.isVerifiedMember,
    });

    return UserProfile.fromSupabase(response);
  }

  /// Upload avatar image to Supabase Storage (avatars bucket).
  /// Returns a public URL (requires the bucket to be public).
  /// Assumes bucket 'avatars' exists and has proper policies.
  static Future<String> uploadAvatar(XFile image, String userId) async {
    final bytes = await image.readAsBytes();
    final fileExt = image.path.split('.').last.toLowerCase();
    final fileName = 'avatar-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '$userId/$fileName';

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/*'),
    );

    // IMPORTANT: Bucket 'avatars' must be created as PUBLIC in Supabase dashboard
    // for getPublicUrl to work without auth tokens.
    // Also apply policies from supabase/storage_policies.sql
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }
}
