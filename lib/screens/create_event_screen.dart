import 'package:flutter/material.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/interests_service.dart';

/// Event Creation Wizard (PR3 start).
/// Supports:
/// - Templates from real ward activities (FHE-style, hike, service, scripture, potluck, sports)
/// - 4-area + Fellowship/Service tag picker
/// - Date/time
/// - Location with privacy tiers
/// - Minimal recurring support
/// - Standards banner + basic keyword filter (alcohol, etc.)
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fullText = '${_titleController.text} ${_descController.text}';
    if (_hasStandardsViolation(fullText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please remove content that violates wholesome standards (no alcohol, dating language, etc.).')),
      );
      return;
    }

    setState(() {}); // Could add loading state

    try {
      await EventsService.createEvent(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        startTime: _startTime,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        // TODO(PR4): Add real lat/lon from map picker or geocoding
        lat: null,
        lon: null,
        locationType: _locationType,
        locationPrivacy: _locationPrivacy,
        tags: _selectedTags,
        isRecurring: _isRecurring,
        recurrenceNote: _isRecurring ? _recurrenceController.text.trim() : null,
        maxAttendees: _maxAttendees,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host an Activity')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Standards banner (required per design)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
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

            // Date/time (simplified)
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_startTime.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _startTime = date);
                }
              },
            ),

            // Location tiers
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _locationType,
              decoration: const InputDecoration(labelText: 'Location Type'),
              items: _locationTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _locationType = v!),
            ),
            DropdownButtonFormField<String>(
              value: _locationPrivacy,
              decoration: const InputDecoration(labelText: 'Privacy Level'),
              items: _privacyOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _locationPrivacy = v!),
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address or description'),
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
              onPressed: _submit,
              child: const Text('Publish Event'),
            ),

            const SizedBox(height: 16),
            Text(
              'Full geocoding, draft saving, keyword enforcement at backend, and attendee limits in full PR3.',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
