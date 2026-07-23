import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/interests_service.dart';
import 'package:the_gathering/services/seed_service.dart';

/// Discover / Home screen (PR4).
/// Real location (geolocator) + PostGIS nearby_events RPC, search, filters, pagination.
/// FlutterMap with user circle + tappable event markers. Distance in miles.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<GatheringEvent> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _selectedFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _currentOffset = 0;
  static const int _pageSize = 20;

  double _currentLat = 40.76;
  double _currentLon = -111.89;
  bool _locationLoaded = false;
  double _radiusMiles = 25.0;
  // Default wider timeframe so beta seed events are visible without hunting.
  String _dateFilter = 'all_future';
  bool _freeOnly = false;
  bool _recurringOnly = false;
  bool _isSeeding = false;
  /// True when list is filled from non-geo upcoming fallback.
  bool _showingAllUpcoming = false;
  Timer? _searchDebounce;
  late final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _restoreDiscoverPrefs().then((_) {
      _getCurrentLocation().then((_) => _loadEvents(reset: true));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  Future<void> _restoreDiscoverPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final radius = prefs.getDouble('tg_radius_mi');
      final timeframe = prefs.getString('tg_timeframe');
      final free = prefs.getBool('tg_free_only');
      final recurring = prefs.getBool('tg_recurring_only');
      if (!mounted) return;
      setState(() {
        if (radius != null && radius >= 1 && radius <= 50) {
          _radiusMiles = radius;
        }
        if (timeframe != null &&
            [
              'today',
              'this_week',
              'this_month',
              'next_3_months',
              'all_future',
            ].contains(timeframe)) {
          _dateFilter = timeframe;
        }
        if (free != null) _freeOnly = free;
        if (recurring != null) _recurringOnly = recurring;
      });
    } catch (_) {}
  }

  Future<void> _saveDiscoverPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tg_radius_mi', _radiusMiles);
      await prefs.setString('tg_timeframe', _dateFilter);
      await prefs.setBool('tg_free_only', _freeOnly);
      await prefs.setBool('tg_recurring_only', _recurringOnly);
    } catch (_) {}
  }

  Future<void> _maybeShowWelcome() async {
    // Lightweight first-run tip; ignore failures (prefs optional).
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('tg_welcome_v1') == true) return;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Welcome to beta'),
          content: const Text(
            'Discover activities near you, RSVP, or host your own.\n\n'
            'If the map looks empty, tap “Load sample activities” or create one with your location pinned.\n\n'
            'Friends need their own accounts (Sign out first on shared devices).',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Let\'s go'),
            ),
          ],
        ),
      );
      await prefs.setBool('tg_welcome_v1', true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permissionStatus = await Permission.locationWhenInUse.request();
      if (permissionStatus.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLon = position.longitude;
            _locationLoaded = true;
          });
          _mapController.move(LatLng(_currentLat, _currentLon), 13.0);
        }
      } else {
        // keep default SLC coords (LDS area)
        if (mounted) setState(() => _locationLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoaded = true);
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final next = _searchController.text;
      if (next != _searchQuery) {
        _searchQuery = next;
        _loadEvents(reset: true);
      }
    });
  }

  Future<void> _loadEvents({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      _currentOffset = 0;
      _hasMore = true;
      setState(() => _isLoading = true);
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      var newEvents = await EventsService.fetchNearbyEvents(
        lat: _currentLat,
        lon: _currentLon,
        radiusMiles: _radiusMiles,
        limit: _pageSize,
        offset: _currentOffset,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      );

      var usedFallback = false;
      // If nothing in radius (or RLS/geo not ready), show all upcoming activities.
      if (reset && newEvents.isEmpty) {
        final upcoming = await EventsService.fetchUpcomingEvents(
          limit: _pageSize,
          offset: 0,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          startDate: _getStartDate(),
          endDate: _getEndDate(),
        );
        if (upcoming.isNotEmpty) {
          newEvents = upcoming;
          usedFallback = true;
        }
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _events = newEvents;
          _showingAllUpcoming = usedFallback;
        } else {
          _events.addAll(newEvents);
        }
        _currentOffset += newEvents.length;
        _hasMore = !usedFallback && newEvents.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  List<GatheringEvent> get _filteredEvents {
    var list = _events;
    if (_selectedFilter != null) {
      list = list.where((e) => e.tags.contains(_selectedFilter)).toList();
    }
    if (_freeOnly) {
      list = list.where((e) => e.cost == null || e.cost == 0).toList();
    }
    if (_recurringOnly) {
      list = list.where((e) => e.isRecurring).toList();
    }
    return list;
  }

  String _distanceText(GatheringEvent e) {
    if (e.lat == null || e.lon == null) return '';
    final distance = const Distance().as(LengthUnit.Meter, LatLng(_currentLat, _currentLon), LatLng(e.lat!, e.lon!));
    final miles = distance / 1609.34;
    if (miles < 0.1) return '${distance.toInt()} m';
    return '${miles.toStringAsFixed(1)} mi';
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'this_week':
        // Start of this week (Monday), but not before today
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return now.isAfter(startOfWeek) ? now : startOfWeek;
      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return now.isAfter(startOfMonth) ? now : startOfMonth;
      case 'next_3_months':
        return now;
      case 'all_future':
        return now;
      default:
        return now;
    }
  }

  DateTime? _getEndDate() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'this_week':
        // End of this week (Sunday)
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case 'this_month':
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case 'next_3_months':
        return DateTime(now.year, now.month + 3, now.day, 23, 59, 59);
      case 'all_future':
        return null;
      default:
        return null;
    }
  }

  String _getFilterLabel() {
    switch (_dateFilter) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This week';
      case 'this_month':
        return 'This month';
      case 'next_3_months':
        return 'Next 3 months';
      case 'all_future':
        return 'All upcoming';
      default:
        return 'Upcoming';
    }
  }

  Widget? _profileNudge(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (profile == null) return null;
    final missing = <String>[];
    if (profile.displayName.isEmpty || profile.displayName == 'Member') {
      missing.add('display name');
    }
    if (profile.city == null || profile.city!.trim().isEmpty) {
      missing.add('city');
    }
    if (profile.interests.isEmpty) missing.add('interests');
    if (missing.isEmpty) return null;

    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.person_outline),
        title: Text('Finish your profile (${missing.join(', ')})'),
        subtitle: const Text('Helps others trust hosts and find good matches.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/profile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Gathering'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/reports'),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Reports'),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh events',
            onPressed: () => _loadEvents(reset: true),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final nudge = _profileNudge(context);
                if (nudge == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: nudge,
                );
              },
            ),
            Text(
              _showingAllUpcoming
                  ? 'Upcoming activities — ${_getFilterLabel()}'
                  : 'Near you (${_radiusMiles.toStringAsFixed(0)} mi) — ${_getFilterLabel()}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_showingAllUpcoming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No map pins in your radius yet — showing all upcoming you can access. Host with “use current location” so they appear on the map.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (_locationLoaded)
              Text(
                '${_currentLat.toStringAsFixed(2)}, ${_currentLon.toStringAsFixed(2)} (app location)',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Radius presets + slider
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Radius: '),
                  ...[5.0, 15.0, 25.0, 50.0].map((mi) {
                    final selected = (_radiusMiles - mi).abs() < 0.5;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('${mi.toInt()} mi'),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _radiusMiles = mi);
                          _saveDiscoverPrefs();
                          _loadEvents(reset: true);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _radiusMiles,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_radiusMiles.toStringAsFixed(0)} mi',
                    onChanged: (v) {
                      setState(() => _radiusMiles = v);
                    },
                    onChangeEnd: (v) {
                      _saveDiscoverPrefs();
                      _loadEvents(reset: true);
                    },
                  ),
                ),
                Text('${_radiusMiles.toStringAsFixed(0)} mi'),
              ],
            ),

            // Date range filter (future activities)
            DropdownButtonFormField<String>(
              initialValue: _dateFilter,
              decoration: const InputDecoration(
                labelText: 'Timeframe',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'this_week', child: Text('This week')),
                DropdownMenuItem(value: 'this_month', child: Text('This month')),
                DropdownMenuItem(value: 'next_3_months', child: Text('Next 3 months')),
                DropdownMenuItem(value: 'all_future', child: Text('All upcoming')),
              ],
              onChanged: (v) {
                if (v != null && v != _dateFilter) {
                  setState(() => _dateFilter = v);
                  _saveDiscoverPrefs();
                  _loadEvents(reset: true);
                }
              },
            ),
            const SizedBox(height: 8),

            // Basic filter chips (PR4 direction)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All tags'),
                    selected: _selectedFilter == null,
                    onSelected: (_) => setState(() => _selectedFilter = null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Free only'),
                    selected: _freeOnly,
                    onSelected: (v) {
                      setState(() => _freeOnly = v);
                      _saveDiscoverPrefs();
                    },
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Recurring'),
                    selected: _recurringOnly,
                    onSelected: (v) {
                      setState(() => _recurringOnly = v);
                      _saveDiscoverPrefs();
                    },
                  ),
                  const SizedBox(width: 6),
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
            const SizedBox(height: 4),

            if (_searchQuery.isNotEmpty ||
                _selectedFilter != null ||
                _freeOnly ||
                _recurringOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedFilter = null;
                      _freeOnly = false;
                      _recurringOnly = false;
                    });
                    _saveDiscoverPrefs();
                    _loadEvents(reset: true);
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear search & filters'),
                ),
              ),

            if (!_isLoading && _filteredEvents.isNotEmpty)
              Text(
                '${_filteredEvents.length} event${_filteredEvents.length == 1 ? '' : 's'} within ${_radiusMiles.toStringAsFixed(0)} mi',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),

            const SizedBox(height: 12),

            // Real map (PR4) + recenter button (polish)
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_currentLat, _currentLon),
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.the_gathering',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(_currentLat, _currentLon),
                            radius: _radiusMiles * 1609.34, // meters
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // User location marker
                          Marker(
                            point: LatLng(_currentLat, _currentLon),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                          ),
                          // Event markers (only those with coords) - tappable for details
                          ..._filteredEvents
                              .where((e) => e.lat != null && e.lon != null)
                              .map((e) => Marker(
                                    point: LatLng(e.lat!, e.lon!),
                                    width: 36,
                                    height: 36,
                                    child: GestureDetector(
                                      onTap: () => context.push('/event', extra: e),
                                      child: const Icon(Icons.location_on, color: Colors.red, size: 28),
                                    ),
                                  )),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: () {
                        _mapController.move(LatLng(_currentLat, _currentLon), 13.0);
                      },
                      child: const Icon(Icons.center_focus_strong, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Events list area with pull-to-refresh (polish)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEvents.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 32),
                              Icon(
                                Icons.explore_outlined,
                                size: 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  _searchQuery.isNotEmpty ||
                                          _selectedFilter != null ||
                                          _freeOnly ||
                                          _recurringOnly
                                      ? 'No events match your filters. Clear filters or widen the radius/timeframe.'
                                      : 'No activities nearby yet for ${_getFilterLabel().toLowerCase()}.\n\n'
                                          'Load sample gatherings to explore, or host the first real one.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_searchQuery.isEmpty &&
                                  _selectedFilter == null &&
                                  !_freeOnly &&
                                  !_recurringOnly) ...[
                                Center(
                                  child: FilledButton.icon(
                                    onPressed: _isSeeding ? null : _seedSamples,
                                    icon: _isSeeding
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.auto_awesome),
                                    label: Text(
                                      _isSeeding
                                          ? 'Loading samples…'
                                          : 'Load sample activities near me',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/create'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Host an activity'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Samples create ~10 demo events around your map pin (you are the host).',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent - 200 &&
                                  !_isLoadingMore &&
                                  _hasMore) {
                                _loadEvents();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              itemCount: _filteredEvents.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredEvents.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final event = _filteredEvents[index];
                                final dist = _distanceText(event);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => context.push('/event', extra: event),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                            child: Icon(
                                              event.tags.contains('Physical') ? Icons.hiking : Icons.groups,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        event.title,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    if (event.cost == null || event.cost == 0)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 4),
                                                        child: Text(
                                                          'FREE',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    if (event.isRecurring)
                                                      const Padding(
                                                        padding: EdgeInsets.only(left: 4),
                                                        child: Icon(Icons.repeat, size: 14),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${event.tags.join(' • ')}  •  ${_formatTime(event.startTime)}'
                                                  '  ·  ${_relativeWhen(event.startTime)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                if (event.isRecurring && event.recurrenceNote != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      event.recurrenceNote!,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              if (dist.isNotEmpty)
                                                Chip(
                                                  label: Text(dist, style: const TextStyle(fontSize: 11)),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              const SizedBox(height: 4),
                                              PopupMenuButton<String>(
                                                child: const Chip(
                                                  label: Text('RSVP', style: TextStyle(fontSize: 11)),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                onSelected: (status) async {
                                                  final messenger = ScaffoldMessenger.of(context);
                                                  try {
                                                    await EventsService.rsvpToEvent(
                                                      eventId: event.id,
                                                      status: status,
                                                    );
                                                    if (mounted) {
                                                      messenger.showSnackBar(
                                                        SnackBar(content: Text('RSVP set to $status')),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      messenger.showSnackBar(
                                                        SnackBar(content: Text('RSVP failed: $e')),
                                                      );
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => const [
                                                  PopupMenuItem(value: 'going', child: Text('Going')),
                                                  PopupMenuItem(value: 'maybe', child: Text('Maybe')),
                                                  PopupMenuItem(value: 'no', child: Text('Not going')),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedSamples() async {
    setState(() => _isSeeding = true);
    try {
      final count = await SeedService.seedSampleEventsNear(
        lat: _currentLat,
        lon: _currentLon,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Added $count sample activities near you. Explore the map!'
                : 'Could not add samples. Confirm you are signed in and beta SQL is applied.',
          ),
        ),
      );
      // Show a wide timeframe so seeds are visible.
      setState(() => _dateFilter = 'all_future');
      await _loadEvents(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample load failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _refresh() async {
    // Pull-to-refresh: re-fetch location and events
    await _getCurrentLocation();
    await _loadEvents(reset: true);
  }

  String _formatTime(DateTime dt) {
    // Polished date/time display
    final date = DateFormat.MMMd().format(dt); // e.g. Jul 7
    final time = DateFormat.jm().format(dt);    // e.g. 3:30 PM
    return '$date · $time';
  }

  String _relativeWhen(DateTime start) {
    final now = DateTime.now();
    final local = start.toLocal();
    final diff = local.difference(now);
    if (diff.isNegative) return 'Started';
    if (diff.inDays >= 14) return 'In ${diff.inDays}d';
    if (diff.inDays >= 2) return 'In ${diff.inDays}d';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inHours >= 1) return 'In ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'In ${diff.inMinutes}m';
    return 'Soon';
  }
}

