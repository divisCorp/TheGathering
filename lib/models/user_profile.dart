/// User profile model aligned with The Gathering design (PR1+).
/// Note: Precise location NEVER stored in profile per privacy requirements.
/// Only coarse city + optional self-reported ward/stake.
class UserProfile {
  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? ageRange;
  final String? bio;
  final List<String> interests; // 4 areas + tags
  final String? city; // Coarse only
  final String? ward;
  final String? stake;
  final bool isVerifiedMember; // Starts false, pending review
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.email,
    this.phone,
    required this.displayName,
    this.ageRange,
    this.bio,
    required this.interests,
    this.city,
    this.ward,
    this.stake,
    required this.isVerifiedMember,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id']?.toString() ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      displayName: data['display_name'] as String? ?? 'Member',
      ageRange: data['age_range'] as String?,
      bio: data['bio'] as String?,
      interests: (data['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      city: data['city'] as String?,
      ward: data['ward'] as String?,
      stake: data['stake'] as String?,
      isVerifiedMember: data['is_verified_member'] as bool? ?? false,
      avatarUrl: data['avatar_url'] as String?,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'age_range': ageRange,
    'bio': bio,
    'interests': interests,
    'city': city,
    'ward': ward,
    'stake': stake,
    'is_verified_member': isVerifiedMember,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  /// Map suitable for Supabase upsert (only DB columns)
  Map<String, dynamic> toSupabase() => toJson();
}
