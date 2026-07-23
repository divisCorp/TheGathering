import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/screens/create_event_screen.dart';
import 'package:the_gathering/services/calendar_service.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/reports_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final GatheringEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late GatheringEvent _event;
  List<Map<String, dynamic>> _attendees = [];
  bool _isLoadingAttendees = true;
  String? _currentRsvpStatus;
  bool _isUpdatingRsvp = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadAttendees();
    _loadCurrentRsvp();
  }

  bool get _isHost {
    final uid = SupabaseService.currentUser?.id;
    return uid != null && uid == _event.hostId;
  }

  int _goingCount() {
    return _attendees.where((a) => a['status'] == 'going').length;
  }

  String _relativeWhen(DateTime start) {
    final now = DateTime.now();
    final local = start.toLocal();
    final diff = local.difference(now);
    if (diff.isNegative) {
      final ago = now.difference(local);
      if (ago.inDays >= 1) return 'Started ${ago.inDays}d ago';
      if (ago.inHours >= 1) return 'Started ${ago.inHours}h ago';
      return 'Started recently';
    }
    if (diff.inDays >= 14) return 'In ${diff.inDays} days';
    if (diff.inDays >= 2) return 'In ${diff.inDays} days';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inHours >= 1) return 'In ${diff.inHours} hours';
    if (diff.inMinutes >= 1) return 'In ${diff.inMinutes} minutes';
    return 'Starting soon';
  }

  Future<void> _loadAttendees() async {
    setState(() => _isLoadingAttendees = true);
    try {
      final attendees = await EventsService.fetchEventAttendees(_event.id);
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
          .eq('event_id', _event.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentRsvpStatus = response['status'] as String?;
        });
      }
    } catch (_) {}
  }

  bool get _isFull {
    final max = _event.maxAttendees;
    if (max == null || max <= 0) return false;
    // Allow host / already-going to keep or change status.
    if (_currentRsvpStatus == 'going') return false;
    return _goingCount() >= max;
  }

  Future<void> _updateRsvp(String status) async {
    if (status == 'going' && _isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This activity is full. Try Maybe or pick another gathering.'),
        ),
      );
      return;
    }

    setState(() => _isUpdatingRsvp = true);
    try {
      await EventsService.rsvpToEvent(
        eventId: _event.id,
        status: status,
      );
      setState(() => _currentRsvpStatus = status);
      await _loadAttendees();
      if (mounted) {
        final label = {
          'going': "You're going — see you there!",
          'maybe': "Marked as maybe.",
          'no': "RSVP cleared (not going).",
        }[status]!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(label)),
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

  Future<void> _shareInvite() async {
    final text = EventsService.inviteText(_event);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite copied — paste into texts, email, or group chats.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _copyAttendeeList() async {
    if (_attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendees yet.')),
      );
      return;
    }
    final buf = StringBuffer()
      ..writeln('Attendees for ${_event.title}')
      ..writeln();
    for (final rsvp in _attendees) {
      final profile = rsvp['profiles'] as Map<String, dynamic>? ?? {};
      final name = profile['display_name'] as String? ?? 'Member';
      final status = rsvp['status'] as String? ?? '';
      buf.writeln('• $name ($status)');
    }
    buf.writeln();
    buf.writeln('Going: ${_goingCount()} · Total listed: ${_attendees.length}');
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendee list copied.')),
    );
  }

  Future<void> _addToCalendar() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Google Calendar'),
              onTap: () => Navigator.pop(ctx, 'google'),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Outlook Calendar'),
              onTap: () => Navigator.pop(ctx, 'outlook'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Open ICS file'),
              subtitle: const Text('Works in many browsers / Apple Calendar'),
              onTap: () => Navigator.pop(ctx, 'ics_open'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: const Text('Copy ICS text'),
              onTap: () => Navigator.pop(ctx, 'ics'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'google') {
      final ok = await CalendarService.openGoogleCalendar(_event);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Calendar.')),
        );
      }
    } else if (action == 'outlook') {
      final ok = await CalendarService.openOutlookCalendar(_event);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Outlook Calendar.')),
        );
      }
    } else if (action == 'ics_open') {
      final ok = await CalendarService.openIcsDataUri(_event);
      if (!mounted) return;
      if (!ok) {
        final ics = CalendarService.toIcs(_event);
        await Clipboard.setData(ClipboardData(text: ics));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open ICS — copied text instead.')),
        );
      }
    } else if (action == 'ics') {
      final ics = CalendarService.toIcs(_event);
      await Clipboard.setData(ClipboardData(text: ics));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ICS copied. Import into your calendar app.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _reportEvent() async {
    if (SupabaseService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to report.')),
      );
      return;
    }

    String reason = ReportsService.reasons.first;
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Report activity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Reports help keep The Gathering wholesome and safe. '
                      'False reports may affect your account.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(reason),
                      initialValue: reason,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      items: ReportsService.reasons
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setLocal(() => reason = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Details (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true || !mounted) {
      detailsController.dispose();
      return;
    }

    try {
      await ReportsService.submitReport(
        reason: reason,
        details: detailsController.text,
        eventId: _event.id,
        reportedUserId: _event.hostId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    } finally {
      detailsController.dispose();
    }
  }

  Future<void> _editEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(event: _event),
      ),
    );
    // Reload from hosted list isn't trivial; user can re-open from Discover.
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this activity?'),
        content: const Text(
          'This removes the activity for everyone. RSVPs will no longer see it as active.',
        ),
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
    );
    if (confirm != true || !mounted) return;

    try {
      await EventsService.deleteEvent(_event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity cancelled.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final currentUserId = ref.read(currentProfileProvider).value?.id ??
        SupabaseService.currentUser?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            tooltip: 'Copy invite',
            icon: const Icon(Icons.ios_share),
            onPressed: _shareInvite,
          ),
          IconButton(
            tooltip: 'Add to calendar',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _addToCalendar,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'share') _shareInvite();
              if (v == 'attendees') _copyAttendeeList();
              if (v == 'report') _reportEvent();
              if (v == 'edit') _editEvent();
              if (v == 'duplicate') {
                context.push('/create', extra: _event);
              }
              if (v == 'delete') _deleteEvent();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'share', child: Text('Copy invite text')),
              if (_isHost) ...[
                const PopupMenuItem(
                  value: 'attendees',
                  child: Text('Copy attendee list'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Edit activity')),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate next week'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Cancel activity'),
                ),
              ],
              const PopupMenuItem(
                value: 'report',
                child: Text('Report activity'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (_isFull)
                        Chip(
                          label: const Text('FULL'),
                          backgroundColor: theme.colorScheme.errorContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEE, MMM d • h:mm a').format(event.startTime) +
                                  (event.endTime != null
                                      ? ' – ${DateFormat('h:mm a').format(event.endTime!)}'
                                      : ''),
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              _relativeWhen(event.startTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event.address != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.place_outlined,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(event.address!)),
                      ],
                    ),
                  ],
                  if (event.isRecurring) ...[
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(Icons.repeat, size: 16),
                      label: Text(
                        event.recurrenceNote?.isNotEmpty == true
                            ? event.recurrenceNote!
                            : 'Recurring',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: event.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 12),
                    Text(event.description!),
                  ],
                  if (event.cost != null) ...[
                    const SizedBox(height: 8),
                    Text('Cost note: \$${event.cost}'),
                  ],
                  if (event.maxAttendees != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Capacity: ${_goingCount()}/${event.maxAttendees}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (event.maxAttendees! <= 0)
                            ? 0
                            : (_goingCount() / event.maxAttendees!).clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Material(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Community standards: wholesome, Word of Wisdom friendly, '
                'friendship-focused (not dating). Report anything that does not fit.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _shareInvite,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Copy invite'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _addToCalendar,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Calendar'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text('Your response', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (SupabaseService.currentUser != null) ...[
            if (_isFull && _currentRsvpStatus != 'going')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'This activity is at capacity. You can still mark Maybe.',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              children: ['going', 'maybe', 'no'].map((status) {
                final isSelected = _currentRsvpStatus == status;
                final label = {
                  'going': _isFull && !isSelected ? 'Going (full)' : 'Going',
                  'maybe': 'Maybe',
                  'no': 'Not going',
                }[status]!;
                final disableGoing = status == 'going' && _isFull && !isSelected;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_isUpdatingRsvp || disableGoing)
                      ? null
                      : (selected) {
                          if (selected) _updateRsvp(status);
                        },
                );
              }).toList(),
            ),
          ] else
            const Text('Sign in to RSVP'),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attendees (${_attendees.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (_isHost && _attendees.isNotEmpty)
                TextButton.icon(
                  onPressed: _copyAttendeeList,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy list'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingAttendees)
            const Center(child: CircularProgressIndicator())
          else if (_attendees.isEmpty)
            Text(
              'No RSVPs yet — be the first to say Going.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            ..._attendees.map((rsvp) {
              final profile = rsvp['profiles'] as Map<String, dynamic>? ?? {};
              final isCurrentUser = profile['id'] == currentUserId;
              final avatar = profile['avatar_url'] as String?;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage:
                      avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  (profile['display_name'] as String? ?? 'Member') +
                      (isCurrentUser ? ' (You)' : ''),
                ),
                subtitle: Text(
                  {
                        'going': 'Going',
                        'maybe': 'Maybe',
                        'no': 'Not going',
                      }[rsvp['status']] ??
                      '${rsvp['status']}',
                ),
              );
            }),
        ],
      ),
    );
  }
}
