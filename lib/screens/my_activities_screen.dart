import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/app_ui_provider.dart';
import 'package:the_gathering/screens/create_event_screen.dart';
import 'package:the_gathering/services/events_service.dart';

/// My Activities: hosted events with RSVP counts + personal RSVPs.
class MyActivitiesScreen extends ConsumerStatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  ConsumerState<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends ConsumerState<MyActivitiesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myRsvps = [];
  List<GatheringEvent> _myHostedEvents = [];
  List<GatheringEvent> _myPastHosted = [];
  Map<String, ({int going, int maybe})> _rsvpCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rsvps = await EventsService.fetchMyRsvps();
      final hosted = await EventsService.fetchMyEvents(upcomingOnly: true);
      final past = await EventsService.fetchMyPastHostedEvents();
      final counts = await EventsService.fetchRsvpCounts(
        hosted.map((e) => e.id).toList(),
      );

      // Hide RSVPs to cancelled/missing events
      final activeRsvps = rsvps.where((r) {
        final event = r['events'];
        if (event is! Map) return false;
        final status = event['status'] as String? ?? 'active';
        return status == 'active';
      }).toList();

      if (mounted) {
        setState(() {
          _myRsvps = activeRsvps;
          _myHostedEvents = hosted;
          _myPastHosted = past;
          _rsvpCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
    }
  }

  Future<void> _updateRsvp(String eventId, String newStatus) async {
    try {
      await EventsService.rsvpToEvent(eventId: eventId, status: newStatus);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _editHostedEvent(GatheringEvent event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(event: event),
      ),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(activitiesRefreshTickProvider, (prev, next) {
      if (prev != next) _loadData();
    });

    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        actions: [
          IconButton(
            tooltip: 'Host new activity',
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hosting',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Swipe right to edit · swipe left to cancel · tap to open',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_myHostedEvents.isEmpty)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('You are not hosting yet'),
                  subtitle: const Text('Create a wholesome activity for your area'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/create'),
                ),
              )
            else
              ..._myHostedEvents.map((e) {
                final timeStr = DateFormat('MMM d · h:mm a').format(e.startTime);
                final counts = _rsvpCounts[e.id] ?? (going: 0, maybe: 0);
                return Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.horizontal,
                  dismissThresholds: const {
                    DismissDirection.startToEnd: 0.25,
                    DismissDirection.endToStart: 0.25,
                  },
                  background: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _editHostedEvent(e);
                      return false;
                    }
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel activity?'),
                            content: Text('Remove "${e.title}" from Discover?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Cancel activity'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (direction) async {
                    if (direction != DismissDirection.endToStart) return;
                    try {
                      await EventsService.deleteEvent(e.id);
                      await _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity cancelled')),
                      );
                    } catch (err) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to cancel: $err')),
                      );
                      await _loadData();
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.event,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '$timeStr\n'
                        '${counts.going} going · ${counts.maybe} maybe',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'open') {
                            context.push('/event', extra: e);
                          } else if (v == 'edit') {
                            await _editHostedEvent(e);
                          } else if (v == 'duplicate') {
                            context.push('/create', extra: e);
                          } else if (v == 'invite') {
                            await Clipboard.setData(
                              ClipboardData(text: EventsService.inviteText(e)),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invite copied to clipboard'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'open', child: Text('Open')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate next week'),
                          ),
                          PopupMenuItem(
                            value: 'invite',
                            child: Text('Copy invite'),
                          ),
                        ],
                      ),
                      onTap: () => context.push('/event', extra: e),
                    ),
                  ),
                );
              }),

            if (_myPastHosted.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Past hosted',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._myPastHosted.map((e) {
                final timeStr =
                    DateFormat('MMM d · h:mm a').format(e.startTime);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(e.title),
                    subtitle: Text(timeStr),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'duplicate') {
                          context.push('/create', extra: e);
                        } else if (v == 'open') {
                          context.push('/event', extra: e);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('Open')),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate next week'),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/event', extra: e),
                  ),
                );
              }),
            ],

            const SizedBox(height: 28),
            Text(
              'My RSVPs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_myRsvps.isEmpty)
              Text(
                'No active RSVPs. Browse Discover and say Going or Maybe.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              ..._myRsvps.map((r) {
                final eventMap =
                    (r['events'] as Map<String, dynamic>?) ?? {};
                final status = r['status'] as String? ?? 'going';
                final title =
                    eventMap['title'] as String? ?? 'Unknown event';
                String timeStr = '';
                final startStr = eventMap['start_time'];
                if (startStr is String) {
                  try {
                    timeStr = DateFormat('MMM d · h:mm a')
                        .format(DateTime.parse(startStr));
                  } catch (_) {}
                }
                GatheringEvent? parsed;
                try {
                  if (eventMap['id'] != null) {
                    parsed = GatheringEvent.fromSupabase(eventMap);
                  }
                } catch (_) {}

                final statusLabel = {
                      'going': 'Going',
                      'maybe': 'Maybe',
                      'no': 'Not going',
                    }[status] ??
                    status;

                return Dismissible(
                  key: ValueKey('rsvp_${eventMap['id'] ?? title}'),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.25,
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove RSVP?'),
                            content: Text('Stop attending "$title"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    try {
                      await EventsService.cancelRsvp(eventMap['id'] as String);
                      await _loadData();
                    } catch (err) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to remove: $err')),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(title),
                      subtitle: Text(
                        timeStr.isNotEmpty
                            ? '$timeStr · $statusLabel'
                            : statusLabel,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newStatus) => _updateRsvp(
                          eventMap['id'] as String,
                          newStatus,
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'going', child: Text('Going')),
                          PopupMenuItem(value: 'maybe', child: Text('Maybe')),
                          PopupMenuItem(
                            value: 'no',
                            child: Text('Not going'),
                          ),
                        ],
                        child: Chip(label: Text(statusLabel)),
                      ),
                      onTap: parsed == null
                          ? null
                          : () => context.push('/event', extra: parsed),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
