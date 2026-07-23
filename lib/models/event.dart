/// Event model aligned with design doc (PR3+).
/// Supports 4-area tags, minimal recurring, location tiers.
class GatheringEvent {
  final String id;
  final String hostId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? address;
  final double? lat;
  final double? lon;
  final String locationType; // public_venue | approx_neighborhood | meetinghouse_vicinity | private
  final String locationPrivacy; // post_rsvp etc.
  final List<String> tags; // 4 areas + others
  final bool isRecurring;
  final String? recurrenceNote;
  final int? maxAttendees;
  final double? cost;
  final String visibility;
  final String status;
  final DateTime createdAt;

  const GatheringEvent({
    required this.id,
    required this.hostId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.address,
    this.lat,
    this.lon,
    this.locationType = 'public_venue',
    this.locationPrivacy = 'post_rsvp',
    required this.tags,
    this.isRecurring = false,
    this.recurrenceNote,
    this.maxAttendees,
    this.cost,
    this.visibility = 'verified_members',
    this.status = 'active',
    required this.createdAt,
  });

  factory GatheringEvent.fromSupabase(Map<String, dynamic> json) {
    // Parse location from several PostGIS/PostgREST shapes.
    double? lat = (json['lat'] as num?)?.toDouble();
    double? lon = (json['lon'] as num?)?.toDouble();
    final loc = json['location'];
    if (lat == null || lon == null) {
      if (loc is String) {
        // "POINT(lon lat)" or "SRID=4326;POINT(lon lat)"
        final pointIdx = loc.indexOf('POINT(');
        if (pointIdx >= 0) {
          final inner = loc.substring(pointIdx + 6, loc.indexOf(')', pointIdx));
          final coords = inner.trim().split(RegExp(r'\s+'));
          if (coords.length >= 2) {
            lon = double.tryParse(coords[0]);
            lat = double.tryParse(coords[1]);
          }
        }
      } else if (loc is Map) {
        // GeoJSON: { type: Point, coordinates: [lon, lat] }
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lon = (coords[0] as num?)?.toDouble();
          lat = (coords[1] as num?)?.toDouble();
        }
      }
    }

    return GatheringEvent(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      address: json['address'] as String?,
      lat: lat,
      lon: lon,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'host_id': hostId,
    'title': title,
    'description': description,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'address': address,
    'location': (lat != null && lon != null) ? 'POINT($lon $lat)' : null,
    'location_type': locationType,
    'location_privacy': locationPrivacy,
    'tags': tags,
    'is_recurring': isRecurring,
    'recurrence_note': recurrenceNote,
    'max_attendees': maxAttendees,
    'cost': cost,
    'visibility': visibility,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}
