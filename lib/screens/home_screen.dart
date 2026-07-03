import 'package:flutter/material.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/interests_service.dart';
import 'package:the_gathering/screens/profile_screen.dart';

/// Discover / Home screen (PR2+).
/// Loads events from service. Full map, advanced filters, 4-area matching in PR4.
/// Bottom nav handled by MainShell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GatheringEvent> _events = [];
  bool _isLoading = true;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // Use current location stub (PR4 will use real GPS)
      final events = await EventsService.fetchNearbyEvents(lat: 40.76, lon: -111.89);
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Fallback to mock if no backend
      setState(() {
        _events = _getMockEvents();
      });
    }
  }

  List<GatheringEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      GatheringEvent(
        id: 'mock1',
        hostId: 'host1',
        title: 'Saturday Hike - Millcreek Canyon',
        description: 'Uplifting hike with great views.',
        startTime: now.add(const Duration(days: 1)),
        address: 'Millcreek Canyon',
        tags: ['Physical', 'Social'],
        createdAt: now,
      ),
      GatheringEvent(
        id: 'mock2',
        hostId: 'host2',
        title: 'FHE-style Game Night',
        description: 'Board games and fellowship.',
        startTime: now.add(const Duration(days: 2)),
        address: 'Local Church Building',
        tags: ['Social'],
        isRecurring: true,
        recurrenceNote: 'Weekly on Tuesdays',
        createdAt: now,
      ),
    ];
  }

  List<GatheringEvent> get _filteredEvents {
    if (_selectedFilter == null) return _events;
    return _events.where((e) => e.tags.contains(_selectedFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Gathering'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week near you',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Events from Supabase (or mock). PR4: map + real geo filters.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Basic filter chips (PR4 direction)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (_) => setState(() => _selectedFilter = null),
                  ),
                  ...InterestsService.grouped.keys.take(4).map((area) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(area),
                      selected: _selectedFilter == area,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? area : null);
                      },
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map placeholder (PR4)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Text('Map View (Google/Mapbox) - PR4', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('Events shown within 15mi radius', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredEvents.isEmpty)
              const Center(child: Text('No events yet. Be the first to host one!'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          event.tags.contains('Physical') ? Icons.hiking : Icons.groups,
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          '${event.tags.join(', ')} • ${_formatTime(event.startTime)}'
                          '${event.isRecurring ? ' • ${event.recurrenceNote ?? "Recurring"}' : ''}',
                        ),
                        trailing: const Chip(label: Text('Open')),
                        onTap: () {
                          // TODO: Event detail view + RSVP (PR5)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event details + RSVP in PR5')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Temporary wrapper (for nav from inside home)
class ProfileScreenWrapper extends StatelessWidget {
  const ProfileScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

