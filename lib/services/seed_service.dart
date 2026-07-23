import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// Seeds wholesome sample activities near a point so beta discovery isn't empty.
class SeedService {
  /// Creates a set of upcoming sample events hosted by the current user.
  /// Returns how many events were created.
  static Future<int> seedSampleEventsNear({
    required double lat,
    required double lon,
    String cityLabel = 'the area',
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Sign in first, then load sample activities.');
    }

    final now = DateTime.now();
    final samples = <_SampleEvent>[
      _SampleEvent(
        title: 'Saturday Morning Hike',
        description:
            'Easy 3-mile trail walk. Families and singles welcome. Bring water and good shoes. Word of Wisdom friendly — pure mountain air!',
        daysFromNow: 2,
        hour: 8,
        tags: const ['Physical', 'Social', 'Fellowship'],
        address: 'Trailhead near $cityLabel',
        dLat: 0.02,
        dLon: -0.01,
      ),
      _SampleEvent(
        title: 'Game Night Potluck',
        description:
            'Board games, card games, and light potluck snacks. Come meet new friends. All ages 18+.',
        daysFromNow: 3,
        hour: 19,
        tags: const ['Social', 'Fellowship'],
        address: 'Community room / host home ($cityLabel)',
        dLat: -0.015,
        dLon: 0.012,
        isRecurring: true,
        recurrenceNote: 'Often weekly — check description',
      ),
      _SampleEvent(
        title: 'Scripture Study Circle',
        description:
            'Come discuss Come, Follow Me / Book of Mormon insights. Uplifting conversation, no preparation required.',
        daysFromNow: 4,
        hour: 19,
        tags: const ['Spiritual', 'Intellectual'],
        address: 'Near local meetinghouse ($cityLabel)',
        dLat: 0.008,
        dLon: 0.018,
        isRecurring: true,
        recurrenceNote: 'Weekly on weeknights',
      ),
      _SampleEvent(
        title: 'Service Project: Yard Help',
        description:
            'Help a neighbor with yard work and light service. Gloves recommended. Great for ministering-minded friends.',
        daysFromNow: 5,
        hour: 10,
        tags: const ['Service', 'Physical', 'Fellowship'],
        address: '$cityLabel neighborhood (details after RSVP)',
        dLat: -0.022,
        dLon: -0.008,
        locationPrivacy: 'post_rsvp',
      ),
      _SampleEvent(
        title: 'Family History Night',
        description:
            'Bring a laptop if you have one. We will work on FamilySearch, share tips, and celebrate discoveries.',
        daysFromNow: 6,
        hour: 18,
        tags: const ['Intellectual', 'Spiritual'],
        address: 'Public library or stake center ($cityLabel)',
        dLat: 0.012,
        dLon: -0.02,
      ),
      _SampleEvent(
        title: 'Pickup Basketball',
        description:
            'Friendly half-court games. All skill levels. Please keep language clean and competitive spirit kind.',
        daysFromNow: 7,
        hour: 20,
        tags: const ['Physical', 'Social'],
        address: 'Church gym or public court ($cityLabel)',
        dLat: -0.01,
        dLon: 0.025,
      ),
      _SampleEvent(
        title: 'FHE-Style Fellowship Night',
        description:
            'Short thought, treat, and social time. Ideal for new movers and anyone looking for midweek connection.',
        daysFromNow: 8,
        hour: 19,
        tags: const ['Spiritual', 'Social', 'Fellowship'],
        address: 'Host home near $cityLabel',
        dLat: 0.018,
        dLon: 0.006,
        isRecurring: true,
        recurrenceNote: 'Monday-style FHE energy — flexible day',
        locationPrivacy: 'post_rsvp',
      ),
      _SampleEvent(
        title: 'Temple Prep Discussion',
        description:
            'Respectful discussion for those preparing for the temple or wanting a refresher. Wholesome and supportive.',
        daysFromNow: 10,
        hour: 19,
        tags: const ['Spiritual'],
        address: 'Quiet study space ($cityLabel)',
        dLat: -0.005,
        dLon: -0.015,
      ),
      _SampleEvent(
        title: 'Sunday Evening Fireside Hangout',
        description:
            'Casual post-Sunday social: hymn sing optional, conversation required. Come as you are.',
        daysFromNow: 11,
        hour: 18,
        tags: const ['Spiritual', 'Social', 'Fellowship'],
        address: 'Park pavilion or backyard ($cityLabel)',
        dLat: 0.025,
        dLon: 0.01,
      ),
      _SampleEvent(
        title: 'Cooking Class: Simple Meals',
        description:
            'Learn 2–3 simple wholesome recipes. Bring an apron if you like. Food costs shared (~\$5–10).',
        daysFromNow: 12,
        hour: 17,
        tags: const ['Intellectual', 'Social'],
        address: 'Kitchen space ($cityLabel)',
        dLat: -0.018,
        dLon: 0.014,
        cost: 8,
      ),
    ];

    var created = 0;
    for (final s in samples) {
      final start = DateTime(now.year, now.month, now.day, s.hour)
          .add(Duration(days: s.daysFromNow));
      final end = start.add(const Duration(hours: 2));
      try {
        await EventsService.createEvent(
          title: s.title,
          description: s.description,
          startTime: start,
          endTime: end,
          address: s.address,
          lat: lat + s.dLat,
          lon: lon + s.dLon,
          locationType: 'public_venue',
          locationPrivacy: s.locationPrivacy,
          tags: s.tags,
          isRecurring: s.isRecurring,
          recurrenceNote: s.recurrenceNote,
          maxAttendees: 20,
          cost: s.cost,
        );
        created++;
      } catch (_) {
        // Continue seeding remaining samples
      }
    }
    return created;
  }
}

class _SampleEvent {
  final String title;
  final String description;
  final int daysFromNow;
  final int hour;
  final List<String> tags;
  final String address;
  final double dLat;
  final double dLon;
  final bool isRecurring;
  final String? recurrenceNote;
  final String locationPrivacy;
  final double? cost;

  const _SampleEvent({
    required this.title,
    required this.description,
    required this.daysFromNow,
    required this.hour,
    required this.tags,
    required this.address,
    required this.dLat,
    required this.dLon,
    this.isRecurring = false,
    this.recurrenceNote,
    this.locationPrivacy = 'public_venue',
    this.cost,
  });
}
