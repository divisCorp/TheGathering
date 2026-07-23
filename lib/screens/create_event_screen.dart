import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/app_ui_provider.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/interests_service.dart';

/// Event Creation Wizard.
/// Supports templates, tags, tiers, standards, recurring notes, location (now with current GPS capture).
class CreateEventScreen extends ConsumerStatefulWidget {
  /// If provided, we are editing an existing event.
  final GatheringEvent? event;

  /// If provided (and [event] is null), prefill a new event as a duplicate.
  final GatheringEvent? duplicateFrom;

  const CreateEventScreen({super.key, this.event, this.duplicateFrom});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _recurrenceController = TextEditingController();

  String _selectedTemplate = 'Custom';
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  List<String> _selectedTags = [];
  String _locationType = 'public_venue';
  String _locationPrivacy = 'post_rsvp';
  bool _isRecurring = false;
  int? _maxAttendees;

  double? _eventLat;
  double? _eventLon;

  bool _isPublishing = false;
  bool _justPublished = false;
  String? _lastPublishedTitle;

  bool get _isEditing => widget.event != null;

  void _prefillFrom(GatheringEvent e, {required bool shiftWeek}) {
    _titleController.text = e.title;
    _descController.text = e.description ?? '';
    _startTime = shiftWeek
        ? e.startTime.add(const Duration(days: 7))
        : e.startTime;
    if (_startTime.isBefore(DateTime.now())) {
      _startTime = DateTime.now().add(const Duration(days: 1));
    }
    _addressController.text = e.address ?? '';
    _eventLat = e.lat;
    _eventLon = e.lon;
    _locationType = e.locationType;
    _locationPrivacy = e.locationPrivacy;
    _isRecurring = e.isRecurring;
    _recurrenceController.text = e.recurrenceNote ?? '';
    _maxAttendees = e.maxAttendees;
    _selectedTags = List.from(e.tags);
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _prefillFrom(widget.event!, shiftWeek: false);
    } else if (widget.duplicateFrom != null) {
      _prefillFrom(widget.duplicateFrom!, shiftWeek: true);
      if (widget.duplicateFrom!.lat == null) {
        _useCurrentLocation(silent: true);
      }
    } else {
      // Auto-pin map location so new events show up in Discover nearby.
      _useCurrentLocation(silent: true);
    }
  }

  final List<String> _templates = [
    'Custom',
    'Game Night',
    'Hike',
    'Service Project',
    'Scripture Study',
    'Potluck / FHE-style',
    'Sports',
  ];

  final List<String> _locationTypes = [
    'public_venue',
    'approx_neighborhood',
    'meetinghouse_vicinity',
    'private',
  ];

  final List<String> _privacyOptions = ['public', 'approx', 'post_rsvp', 'invite_only'];

  // Basic keyword filter from design
  final List<String> _bannedKeywords = [
    'alcohol', 'beer', 'wine', 'bar', 'drinks', 'tobacco', 'vape', 'dating', 'hookah', 'cannabis'
  ];

  bool _hasStandardsViolation(String text) {
    final lower = text.toLowerCase();
    return _bannedKeywords.any((k) => lower.contains(k));
  }

  void _applyTemplate(String template) {
    setState(() {
      _selectedTemplate = template;
      switch (template) {
        case 'Game Night':
          _titleController.text = 'Game Night';
          _descController.text = 'Come play board games and hang out!';
          _selectedTags = ['Social'];
          break;
        case 'Hike':
          _titleController.text = 'Saturday Hike';
          _descController.text = 'Uplifting hike in the mountains.';
          _selectedTags = ['Physical', 'Social'];
          break;
        case 'Service Project':
          _titleController.text = 'Service Project';
          _descController.text = 'Give back to the community.';
          _selectedTags = ['Social', 'Spiritual'];
          break;
        case 'Scripture Study':
          _titleController.text = 'Scripture Study';
          _descController.text = 'Come study and discuss.';
          _selectedTags = ['Spiritual'];
          break;
        case 'Potluck / FHE-style':
          _titleController.text = 'FHE-style Potluck';
          _descController.text = 'Food, fun, and fellowship.';
          _selectedTags = ['Social', 'Spiritual'];
          _isRecurring = true;
          _recurrenceController.text = 'Weekly on Tuesdays';
          break;
        case 'Sports':
          _titleController.text = 'Basketball';
          _descController.text = 'Pickup game.';
          _selectedTags = ['Physical', 'Social'];
          break;
        default:
          _titleController.clear();
          _descController.clear();
          _selectedTags.clear();
      }
    });
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() {
          _eventLat = pos.latitude;
          _eventLon = pos.longitude;
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Using current location for event')),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isPublishing) return;

    final fullText = '${_titleController.text} ${_descController.text}';
    if (_hasStandardsViolation(fullText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please remove content that violates wholesome standards (no alcohol, dating language, etc.).')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one tag (e.g. Social, Spiritual, Physical).'),
        ),
      );
      return;
    }
    if (_eventLat == null || _eventLon == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No map pin'),
          content: const Text(
            'Without a location pin, this activity may not show on the Discover map. '
            'You can still publish with an address only.\n\n'
            'Tip: tap “Use current location” first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isPublishing = true);

    try {
      final title = _titleController.text.trim();
      final description = _descController.text.trim().isEmpty ? null : _descController.text.trim();

      if (_isEditing) {
        await EventsService.updateEvent(
          eventId: widget.event!.id,
          title: title,
          description: description,
          startTime: _startTime,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          lat: _eventLat,
          lon: _eventLon,
          locationType: _locationType,
          locationPrivacy: _locationPrivacy,
          tags: _selectedTags,
          isRecurring: _isRecurring,
          recurrenceNote: _isRecurring ? _recurrenceController.text.trim() : null,
          maxAttendees: _maxAttendees,
        );
      } else {
        await EventsService.createEvent(
          title: title,
          description: description,
          startTime: _startTime,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          lat: _eventLat,
          lon: _eventLon,
          locationType: _locationType,
          locationPrivacy: _locationPrivacy,
          tags: _selectedTags,
          isRecurring: _isRecurring,
          recurrenceNote: _isRecurring ? _recurrenceController.text.trim() : null,
          maxAttendees: _maxAttendees,
        );
      }

      if (mounted) {
        final action = _isEditing ? 'updated' : 'published';
        final publishedTitle = title;
        _resetForm(keepPublishedFlag: true);
        setState(() {
          _justPublished = true;
          _lastPublishedTitle = publishedTitle;
        });
        // Nudge Discover to reload when user returns to that tab.
        ref.read(discoverRefreshTickProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event $action successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${_isEditing ? 'updating' : 'creating'} event: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _resetForm({bool keepPublishedFlag = false}) {
    _titleController.clear();
    _descController.clear();
    _addressController.clear();
    _recurrenceController.clear();
    _selectedTemplate = 'Custom';
    _startTime = DateTime.now().add(const Duration(days: 1));
    _selectedTags = [];
    _locationType = 'public_venue';
    _locationPrivacy = 'post_rsvp';
    _isRecurring = false;
    _maxAttendees = null;
    _eventLat = null;
    _eventLon = null;
    if (!keepPublishedFlag) {
      _justPublished = false;
      _lastPublishedTitle = null;
    }
  }

  void _createAnother() {
    setState(() {
      _justPublished = false;
      _lastPublishedTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Activity'
              : widget.duplicateFrom != null
                  ? 'Duplicate Activity'
                  : 'Host an Activity',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Standards banner (required per design)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All activities must be uplifting and comply with Church standards (Word of Wisdom, modesty).',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_justPublished) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_isEditing ? 'Updated' : 'Published'}: ${_lastPublishedTitle ?? "Your event"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_isEditing
                        ? 'Changes saved.'
                        : 'Your event is live. Share an invite so friends know — map discovery works best when location is pinned.'),
                    if (_eventLat != null && _eventLon != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Map pin saved ✓',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Tip: next time tap “Use current location” so it appears on the Discover map.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Done'),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: _createAnother,
                            child: const Text('Create another'),
                          ),
                          ElevatedButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Open Discover'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Templates
              const Text('Start with a template', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _templates.map((t) => ChoiceChip(
                label: Text(t),
                selected: _selectedTemplate == t,
                onSelected: (_) => _applyTemplate(t),
              )).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Tags (4 areas)
            const Text('Tags (4 areas + Fellowship/Service)', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: InterestsService.allInterests.map((tag) {
                final sel = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date/time picker (polished)
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(DateFormat('MMM d, y  •  h:mm a').format(_startTime)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final ctx = context; // capture to avoid async gap lint
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: _startTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) return;

                final time = await showTimePicker(
                  // ignore: use_build_context_synchronously
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(_startTime),
                );
                if (time == null || !mounted) return;

                setState(() {
                  _startTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
            ),

            // Location tiers
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _locationType,
              decoration: const InputDecoration(labelText: 'Location Type'),
              items: _locationTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _locationType = v!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _locationPrivacy,
              decoration: const InputDecoration(labelText: 'Privacy Level'),
              items: _privacyOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _locationPrivacy = v!),
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address or description'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use my current location'),
                ),
                const SizedBox(width: 12),
                if (_eventLat != null)
                  Expanded(
                    child: Text(
                      '📍 ${_eventLat!.toStringAsFixed(3)}, ${_eventLon!.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Recurring (minimal for MVP)
            CheckboxListTile(
              value: _isRecurring,
              title: const Text('This is a recurring event (e.g. weekly FHE-style)'),
              onChanged: (v) => setState(() => _isRecurring = v ?? false),
            ),
            if (_isRecurring)
              TextFormField(
                controller: _recurrenceController,
                decoration: const InputDecoration(labelText: 'Recurrence note (e.g. "Weekly on Tuesdays")'),
              ),

            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Max Attendees (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => _maxAttendees = int.tryParse(v),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isPublishing ? null : _submit,
              child: _isPublishing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Publish Event'),
            ),

            const SizedBox(height: 16),
            Text(
              'Location lat/lon captured. Full geocoding + map picker in later iteration.',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
