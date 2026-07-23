import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/services/supabase_service.dart';

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
    final fullText = '$title ${description ?? ''}';
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
      // Prefer RPC for geography; leave null on insert when coords provided.
      'location': null,
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

    final id = response['id'] as String;

    // Set PostGIS geography reliably (works better than raw WKT inserts).
    if (lat != null && lon != null) {
      try {
        await _client.rpc('set_event_location', params: {
          'event_id': id,
          'lat': lat,
          'lon': lon,
        });
      } catch (_) {
        // Fallback: WKT via update (requires geography cast support)
        try {
          await _client.from('events').update({
            'location': 'SRID=4326;POINT($lon $lat)',
          }).eq('id', id).eq('host_id', user.id);
        } catch (_) {
          // Event exists without pin — still usable in list fallback.
        }
      }
    }

    return id;
  }

  static bool _hasBannedKeywords(String text) {
    final lower = text.toLowerCase();
    const banned = ['alcohol', 'beer', 'wine', 'bar', 'drinks', 'tobacco', 'vape', 'dating', 'hookup', 'hookah', 'cannabis'];
    return banned.any((k) => lower.contains(k));
  }

  /// Fetch events using PostGIS RPC for real radius filtering (PR4).
  /// Uses the nearby_events function. Falls back if RPC not yet available.
  static Future<List<GatheringEvent>> fetchNearbyEvents({
    required double lat,
    required double lon,
    double radiusMiles = 15,
    int limit = 20,
    int offset = 0,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc('nearby_events', params: {
        'lat': lat,
        'lon': lon,
        'radius_miles': radiusMiles,
        'search': search,
        'lim': limit,
        'off': offset,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });

      return (response as List<dynamic>)
          .map<GatheringEvent>((json) => _fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return fetchUpcomingEvents(
        limit: limit,
        offset: offset,
        search: search,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// All active upcoming events (no geo). Used when map radius is empty
  /// so beta still has a useful list feed.
  static Future<List<GatheringEvent>> fetchUpcomingEvents({
    int limit = 40,
    int offset = 0,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('events').select().eq('status', 'active');

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }
    if (startDate != null) {
      query = query.gte('start_time', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('start_time', endDate.toIso8601String());
    }

    final response = await query
        .order('start_time', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map<GatheringEvent>((json) => _fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static GatheringEvent _fromJson(Map<String, dynamic> json) {
    return GatheringEvent.fromSupabase(json);
  }

  /// Invite text for sharing (clipboard / messages).
  static String inviteText(GatheringEvent event) {
    final when = event.startTime.toLocal();
    final date =
        '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
    final time =
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final buf = StringBuffer()
      ..writeln('You\'re invited to a Gathering activity!')
      ..writeln()
      ..writeln(event.title)
      ..writeln('$date at $time')
      ..writeln();
    if (event.address != null && event.address!.isNotEmpty) {
      buf.writeln(event.address);
      buf.writeln();
    }
    if (event.description != null && event.description!.isNotEmpty) {
      buf.writeln(event.description);
      buf.writeln();
    }
    buf.writeln('Join The Gathering (beta):');
    buf.writeln('https://diviscorp.github.io/TheGathering/');
    buf.writeln();
    buf.writeln('Wholesome activities · genuine friendships');
    return buf.toString();
  }

  /// Get events hosted by current user.
  static Future<List<GatheringEvent>> fetchMyEvents({
    bool upcomingOnly = true,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    var query = _client
        .from('events')
        .select()
        .eq('host_id', user.id)
        .eq('status', 'active');

    if (upcomingOnly) {
      query = query.gte('start_time', DateTime.now().toIso8601String());
    }

    final response = await query.order('start_time', ascending: true);
    return response.map<GatheringEvent>((json) => _fromJson(json)).toList();
  }

  /// Past active hosted events (start_time in the past).
  static Future<List<GatheringEvent>> fetchMyPastHostedEvents({
    int limit = 20,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('events')
        .select()
        .eq('host_id', user.id)
        .eq('status', 'active')
        .lt('start_time', DateTime.now().toIso8601String())
        .order('start_time', ascending: false)
        .limit(limit);
    return response.map<GatheringEvent>((json) => _fromJson(json)).toList();
  }

  // ==================== Basic RSVPs ====================

  /// Fetch RSVPs for the current user (for My Activities).
  static Future<List<Map<String, dynamic>>> fetchMyRsvps() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('rsvps')
        .select('*, events(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create or update an RSVP for an event.
  static Future<void> rsvpToEvent({
    required String eventId,
    required String status, // 'going' | 'maybe' | 'no'
    String? note,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('rsvps').upsert(
      {
        'user_id': user.id,
        'event_id': eventId,
        'status': status,
        'note': note,
      },
      onConflict: 'user_id,event_id',
    );
  }

  /// Remove RSVP for an event.
  static Future<void> cancelRsvp(String eventId) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await _client
        .from('rsvps')
        .delete()
        .eq('user_id', user.id)
        .eq('event_id', eventId);
  }

  /// Fetch attendees (RSVPs with 'going' or 'maybe') for an event, including basic profile info.
  static Future<List<Map<String, dynamic>>> fetchEventAttendees(String eventId) async {
    final response = await _client
        .from('rsvps')
        .select('id, status, note, created_at, profiles (id, display_name, avatar_url)')
        .eq('event_id', eventId)
        .inFilter('status', ['going', 'maybe'])
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Counts of going / maybe per event (for host dashboard cards).
  static Future<Map<String, ({int going, int maybe})>> fetchRsvpCounts(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return {};
    final response = await _client
        .from('rsvps')
        .select('event_id, status')
        .inFilter('event_id', eventIds)
        .inFilter('status', ['going', 'maybe']);

    final counts = <String, ({int going, int maybe})>{};
    for (final id in eventIds) {
      counts[id] = (going: 0, maybe: 0);
    }
    for (final row in response as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final id = map['event_id'] as String?;
      final status = map['status'] as String?;
      if (id == null || !counts.containsKey(id)) continue;
      final cur = counts[id]!;
      if (status == 'going') {
        counts[id] = (going: cur.going + 1, maybe: cur.maybe);
      } else if (status == 'maybe') {
        counts[id] = (going: cur.going, maybe: cur.maybe + 1);
      }
    }
    return counts;
  }

  /// Cancel an event (host only). Soft-cancel so history/reports remain.
  static Future<void> deleteEvent(String eventId) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('events')
        .update({'status': 'cancelled'})
        .eq('id', eventId)
        .eq('host_id', user.id);
  }

  /// Update an existing event (only host).
  static Future<void> updateEvent({
    required String eventId,
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

    final fullText = '$title ${description ?? ''}';
    if (_hasBannedKeywords(fullText)) {
      throw Exception('Content violates standards. Please remove inappropriate terms.');
    }

    await _client.from('events').update({
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'address': address,
      'location': (lat != null && lon != null) 
          ? 'POINT($lon $lat)'
          : null,
      'location_type': locationType,
      'location_privacy': locationPrivacy,
      'tags': tags,
      'is_recurring': isRecurring,
      'recurrence_note': recurrenceNote,
      'max_attendees': maxAttendees,
      'cost': cost,
    }).eq('id', eventId).eq('host_id', user.id);
  }
}
