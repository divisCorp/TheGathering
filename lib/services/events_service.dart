import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for event CRUD, following PR3+ design.
/// Uses Supabase for persistence, geo queries (PostGIS), etc.
class EventsService {
  static final _client = SupabaseService.client;

  /// Create a new event. Returns the created event id or throws.
  static Future<String> createEvent({
    required String title,
    required String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? address,
    double? lat,
    double? lon,
    String locationType = 'public_venue',
    String locationPrivacy = 'post_rsvp',
    required List<String> tags,
    bool isRecurring = false,
    String? recurrenceNote,
    int? maxAttendees,
    double? cost,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Basic keyword filter enforcement (server side would be better, but client for MVP)
    final fullText = '${title} ${description ?? ''}';
    if (_hasBannedKeywords(fullText)) {
      throw Exception('Content violates standards. Please remove inappropriate terms.');
    }

    final response = await _client.from('events').insert({
      'host_id': user.id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'address': address,
      'location': (lat != null && lon != null) 
          ? 'POINT($lon $lat)' // For PostGIS geography
          : null,
      'location_type': locationType,
      'location_privacy': locationPrivacy,
      'tags': tags,
      'is_recurring': isRecurring,
      'recurrence_note': recurrenceNote,
      'max_attendees': maxAttendees,
      'cost': cost,
      'visibility': 'verified_members',
      'status': 'active',
    }).select('id').single();

    return response['id'] as String;
  }

  static bool _hasBannedKeywords(String text) {
    final lower = text.toLowerCase();
    const banned = ['alcohol', 'beer', 'wine', 'bar', 'drinks', 'tobacco', 'vape', 'dating', 'hookup', 'hookah', 'cannabis'];
    return banned.any((k) => lower.contains(k));
  }

  /// Fetch events near a location (basic radius for now).
  /// In full PR4 use PostGIS ST_DWithin.
  static Future<List<GatheringEvent>> fetchNearbyEvents({
    required double lat,
    required double lon,
    double radiusMiles = 15,
  }) async {
    // For demo, fetch all active and filter client-side.
    // Real: use RPC or query with PostGIS.
    final response = await _client
        .from('events')
        .select()
        .eq('status', 'active')
        .order('start_time', ascending: true)
        .limit(50);

    return response.map<GatheringEvent>((json) => _fromJson(json)).toList();
  }

  static GatheringEvent _fromJson(Map<String, dynamic> json) {
    // Simple parser; enhance with lat/lon extraction from geography if needed.
    return GatheringEvent(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      address: json['address'] as String?,
      lat: null, // parse from geography if stored
      lon: null,
      locationType: json['location_type'] as String? ?? 'public_venue',
      locationPrivacy: json['location_privacy'] as String? ?? 'post_rsvp',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceNote: json['recurrence_note'] as String?,
      maxAttendees: json['max_attendees'] as int?,
      cost: (json['cost'] as num?)?.toDouble(),
      visibility: json['visibility'] as String? ?? 'verified_members',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Get events hosted by current user.
  static Future<List<GatheringEvent>> fetchMyEvents() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('events')
        .select()
        .eq('host_id', user.id)
        .order('start_time', ascending: true);
    return response.map<GatheringEvent>((json) => _fromJson(json)).toList();
  }
}
