import 'package:the_gathering/services/supabase_service.dart';

/// User-submitted reports for moderation (standards / safety).
class ReportsService {
  static final _client = SupabaseService.client;

  static const reasons = <String>[
    'Not wholesome / Word of Wisdom issue',
    'Dating or romantic focus',
    'Spam or misleading',
    'Harassment or unsafe',
    'Inaccurate location or details',
    'Other',
  ];

  /// Submit a report about an event and/or user.
  static Future<void> submitReport({
    required String reason,
    String? details,
    String? eventId,
    String? reportedUserId,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('Sign in to submit a report.');
    if (eventId == null && reportedUserId == null) {
      throw Exception('Nothing to report.');
    }
    final trimmed = reason.trim();
    if (trimmed.isEmpty) throw Exception('Please choose a reason.');

    await _client.from('reports').insert({
      'reporter_id': user.id,
      'event_id': eventId,
      'reported_user_id': reportedUserId,
      'reason': trimmed,
      'details': details?.trim().isEmpty == true ? null : details?.trim(),
      'status': 'pending',
    });
  }
}
