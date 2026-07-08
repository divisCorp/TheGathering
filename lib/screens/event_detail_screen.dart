import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final GatheringEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  List<Map<String, dynamic>> _attendees = [];
  bool _isLoadingAttendees = true;
  String? _currentRsvpStatus;
  bool _isUpdatingRsvp = false;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
    _loadCurrentRsvp();
  }

  Future<void> _loadAttendees() async {
    setState(() => _isLoadingAttendees = true);
    try {
      final attendees = await EventsService.fetchEventAttendees(widget.event.id);
      if (mounted) {
        setState(() {
          _attendees = attendees;
          _isLoadingAttendees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAttendees = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendees: $e')),
        );
      }
    }
  }

  Future<void> _loadCurrentRsvp() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final response = await SupabaseService.client
          .from('rsvps')
          .select('status')
          .eq('event_id', widget.event.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentRsvpStatus = response['status'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateRsvp(String status) async {
    setState(() => _isUpdatingRsvp = true);
    try {
      await EventsService.rsvpToEvent(
        eventId: widget.event.id,
        status: status,
      );
      setState(() => _currentRsvpStatus = status);
      await _loadAttendees(); // refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RSVP updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update RSVP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingRsvp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final currentUserId = ref.read(currentProfileProvider).value?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEE, MMM d • h:mm a').format(event.startTime) +
                        (event.endTime != null ? ' – ${DateFormat('h:mm a').format(event.endTime!)}' : ''),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (event.address != null) ...[
                    const SizedBox(height: 4),
                    Text(event.address!),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: event.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 12),
                    Text(event.description!),
                  ],
                  if (event.cost != null) ...[
                    const SizedBox(height: 8),
                    Text('Cost: \$${event.cost}'),
                  ],
                  if (event.maxAttendees != null) ...[
                    const SizedBox(height: 4),
                    Text('Max attendees: ${event.maxAttendees}'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // RSVP section
          Text('Your Response', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (SupabaseService.currentUser != null)
            Wrap(
              spacing: 8,
              children: ['going', 'maybe', 'no'].map((status) {
                final isSelected = _currentRsvpStatus == status;
                final label = {
                  'going': 'Going',
                  'maybe': 'Maybe',
                  'no': 'Not going',
                }[status] ?? status;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: _isUpdatingRsvp
                      ? null
                      : (selected) {
                          if (selected) _updateRsvp(status);
                        },
                );
              }).toList(),
            )
          else
            const Text('Sign in to RSVP'),

          const SizedBox(height: 32),

          // Attendees
          Text(
            'Attendees (${_attendees.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_isLoadingAttendees)
            const Center(child: CircularProgressIndicator())
          else if (_attendees.isEmpty)
            const Text('No one has RSVPed yet.')
          else
            ..._attendees.map((rsvp) {
              final profile = rsvp['profiles'] as Map<String, dynamic>? ?? {};
              final isCurrentUser = profile['id'] == currentUserId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  (profile['display_name'] as String? ?? 'Anonymous') +
                      (isCurrentUser ? ' (You)' : ''),
                ),
                subtitle: Text(rsvp['status'] ?? ''),
              );
            }),
        ],
      ),
    );
  }
}
