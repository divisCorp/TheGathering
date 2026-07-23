import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/screens/create_event_screen.dart';
import 'package:the_gathering/services/events_service.dart';

/// My Activities screen: shows events the user is hosting + their RSVPs.
/// Basic RSVPs wired here.
class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myRsvps = [];
  List<GatheringEvent> _myHostedEvents = [];

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Realtime subscriptions disabled for now (causes channelError if Realtime replication
    // is not enabled in Supabase Dashboard > Database > Replication for the tables).
    // Use pull-to-refresh instead. To re-enable later:
    // 1. Enable Realtime on the tables in Supabase.
    // 2. Uncomment the _subscribeToChanges() call and implementation below.
    // _subscribeToChanges();
  }

  // void _subscribeToChanges() {
  //   // Listen for RSVP or event changes (cancelled on dispose)
  //   _subscriptions.add(
  //     SupabaseService.client
  //         .from('rsvps')
  //         .stream(primaryKey: ['id'])
  //         .listen((_) => _loadData()),
  //   );
  //
  //   _subscriptions.add(
  //     SupabaseService.client
  //         .from('events')
  //         .stream(primaryKey: ['id'])
  //         .listen((_) => _loadData()),
  //   );
  // }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rsvps = await EventsService.fetchMyRsvps();
      final hosted = await EventsService.fetchMyEvents();
      if (mounted) {
        setState(() {
          _myRsvps = rsvps;
          _myHostedEvents = hosted;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Activities')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_myHostedEvents.isNotEmpty) ...[
              const Text('Hosting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._myHostedEvents.map((e) {
                final timeStr = DateFormat('MMM d, h:mm a').format(e.startTime);
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
                      // Swipe right -> edit
                      _editHostedEvent(e);
                      return false; // do not dismiss
                    } else {
                      // Swipe left -> delete
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Event?'),
                          content: Text('Permanently delete "${e.title}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                    }
                  },
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      try {
                        await EventsService.deleteEvent(e.id);
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event deleted')),
                          );
                        }
                      } catch (err) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $err')),
                          );
                        }
                      }
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(e.title),
                      subtitle: Text('$timeStr · swipe to edit or cancel'),
                      trailing: const Chip(label: Text('Hosting')),
                      onTap: () => context.push('/event', extra: e),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ] else ...[
              const Text('Hosting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'You are not hosting any events yet. Use Create or load samples on Discover.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],
            const Text('My RSVPs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_myRsvps.isEmpty)
              Text(
                'No RSVPs yet. Browse Discover and respond!',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ..._myRsvps.map((r) {
                final eventMap = (r['events'] as Map<String, dynamic>?) ?? {};
                final status = r['status'] as String? ?? 'going';
                final title = eventMap['title'] as String? ?? 'Unknown event';
                String timeStr = '';
                final startStr = eventMap['start_time'];
                if (startStr is String) {
                  try {
                    timeStr = DateFormat('MMM d, h:mm a').format(DateTime.parse(startStr));
                  } catch (_) {}
                }
                GatheringEvent? parsed;
                try {
                  if (eventMap['id'] != null) {
                    parsed = GatheringEvent.fromSupabase(eventMap);
                  }
                } catch (_) {}

                return Dismissible(
                  key: ValueKey('rsvp_${eventMap['id'] ?? title}'),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {DismissDirection.endToStart: 0.25},
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove RSVP?'),
                        content: Text('Stop attending "$title"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await EventsService.cancelRsvp(eventMap['id'] as String);
                      await _loadData();
                    } catch (err) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove: $err')),
                        );
                      }
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(title),
                      subtitle: Text(
                        timeStr.isNotEmpty ? '$timeStr · $status' : 'Status: $status',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newStatus) =>
                            _updateRsvp(eventMap['id'] as String, newStatus),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'going', child: Text('Going')),
                          PopupMenuItem(value: 'maybe', child: Text('Maybe')),
                          PopupMenuItem(value: 'no', child: Text('Not going')),
                        ],
                        child: Chip(label: Text(status)),
                      ),
                      onTap: parsed == null
                          ? null
                          : () => context.push('/event', extra: parsed),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
