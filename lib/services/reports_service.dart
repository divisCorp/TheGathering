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

  static const statuses = <String>[
    'pending',
    'reviewed',
    'resolved',
    'dismissed',
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

  /// Fetch reports (newest first). Requires beta select policy.
  static Future<List<Map<String, dynamic>>> fetchReports({
    String? status,
    int limit = 50,
  }) async {
    var query = _client.from('reports').select(
          'id, reason, details, status, created_at, event_id, reported_user_id, reporter_id, events(id, title, status, host_id)',
        );

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    if (!statuses.contains(status)) {
      throw Exception('Invalid status');
    }
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  /// Soft-hide an event (moderation).
  static Future<void> hideEvent(String eventId) async {
    await _client
        .from('events')
        .update({'status': 'cancelled'})
        .eq('id', eventId);
  }

  static Future<int> pendingCount() async {
    try {
      final rows = await fetchReports(status: 'pending', limit: 100);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}
