import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/services/reports_service.dart';

/// Lightweight beta moderation inbox for community reports.
class ReportsInboxScreen extends StatefulWidget {
  const ReportsInboxScreen({super.key});

  @override
  State<ReportsInboxScreen> createState() => _ReportsInboxScreenState();
}

class _ReportsInboxScreenState extends State<ReportsInboxScreen> {
  bool _loading = true;
  String _filter = 'pending';
  List<Map<String, dynamic>> _reports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ReportsService.fetchReports(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _reports = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not load reports. Run supabase/moderation_beta.sql if you have not. ($e)';
      });
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ReportsService.updateReportStatus(reportId: id, status: status);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _hideEvent(String? eventId) async {
    if (eventId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hide this activity?'),
        content: const Text(
          'Sets the event status to cancelled so it leaves Discover. '
          'Use for clear standards violations.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hide')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ReportsService.hideEvent(eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity hidden (cancelled).')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hide failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports inbox'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Beta moderation — review community reports. '
                  'Run moderation_beta.sql once if this list fails to load.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'resolved', label: Text('Resolved')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) {
                    setState(() => _filter = s.first);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : _reports.isEmpty
                        ? const Center(child: Text('No reports in this filter.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reports.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final r = _reports[i];
                                final event =
                                    r['events'] as Map<String, dynamic>?;
                                final title = event?['title'] as String? ??
                                    '(no event title)';
                                final eventStatus =
                                    event?['status'] as String? ?? '';
                                final created = r['created_at'] as String?;
                                String when = '';
                                if (created != null) {
                                  try {
                                    when = DateFormat.MMMd()
                                        .add_jm()
                                        .format(DateTime.parse(created).toLocal());
                                  } catch (_) {}
                                }

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                '${r['status']}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (eventStatus.isNotEmpty)
                                          Text(
                                            'Event status: $eventStatus',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Reason: ${r['reason']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if ((r['details'] as String?)
                                                ?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 4),
                                          Text('${r['details']}'),
                                        ],
                                        if (when.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            when,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (r['status'] == 'pending') ...[
                                              OutlinedButton(
                                                onPressed: () => _setStatus(
                                                  r['id'] as String,
                                                  'reviewed',
                                                ),
                                                child: const Text('Reviewed'),
                                              ),
                                              OutlinedButton(
                                                onPressed: () => _setStatus(
                                                  r['id'] as String,
                                                  'dismissed',
                                                ),
                                                child: const Text('Dismiss'),
                                              ),
                                              FilledButton(
                                                onPressed: () => _setStatus(
                                                  r['id'] as String,
                                                  'resolved',
                                                ),
                                                child: const Text('Resolve'),
                                              ),
                                            ],
                                            if (r['event_id'] != null &&
                                                eventStatus != 'cancelled')
                                              TextButton.icon(
                                                onPressed: () => _hideEvent(
                                                  r['event_id'] as String?,
                                                ),
                                                icon: const Icon(
                                                  Icons.visibility_off,
                                                  size: 18,
                                                ),
                                                label: const Text('Hide activity'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
