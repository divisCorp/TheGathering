import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:the_gathering/models/event.dart';
import 'package:the_gathering/services/events_service.dart';
import 'package:the_gathering/services/interests_service.dart';

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
  double _radiusMiles = 15.0;
  late final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation().then((_) => _loadEvents(reset: true));
  }

  @override
  void dispose() {
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
    if (_searchController.text != _searchQuery) {
      _searchQuery = _searchController.text;
      _loadEvents(reset: true);
    }
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
      final newEvents = await EventsService.fetchNearbyEvents(
        lat: _currentLat,
        lon: _currentLon,
        radiusMiles: _radiusMiles,
        limit: _pageSize,
        offset: _currentOffset,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _events = newEvents;
        } else {
          _events.addAll(newEvents);
        }
        _currentOffset += newEvents.length;
        _hasMore = newEvents.length == _pageSize;
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  List<GatheringEvent> get _filteredEvents {
    if (_selectedFilter == null) return _events;
    return _events.where((e) => e.tags.contains(_selectedFilter)).toList();
  }

  String _distanceText(GatheringEvent e) {
    if (e.lat == null || e.lon == null) return '';
    final distance = const Distance().as(LengthUnit.Meter, LatLng(_currentLat, _currentLon), LatLng(e.lat!, e.lon!));
    final miles = distance / 1609.34;
    if (miles < 0.1) return '${distance.toInt()} m';
    return '${miles.toStringAsFixed(1)} mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Gathering'),
        actions: [
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
            Text(
              'Near you (${_radiusMiles.toStringAsFixed(0)} mi)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_locationLoaded)
              Text(
                '${_currentLat.toStringAsFixed(2)}, ${_currentLon.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

            // Radius slider (PR4)
            Row(
              children: [
                const Text('Radius: '),
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
                      _loadEvents(reset: true);
                    },
                  ),
                ),
                Text('${_radiusMiles.toStringAsFixed(0)} mi'),
              ],
            ),

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
            const SizedBox(height: 4),

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
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty || _selectedFilter != null
                                  ? 'No events match your search or filter.'
                                  : 'No events yet. Be the first to host one!',
                              textAlign: TextAlign.center,
                            ),
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
                                                Text(
                                                  event.title,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${event.tags.join(' • ')}  •  ${_formatTime(event.startTime)}',
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
}

