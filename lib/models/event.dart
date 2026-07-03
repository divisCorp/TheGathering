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

  // TODO: fromSupabase, toJson for full backend integration
}
