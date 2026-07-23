import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to ask Discover to reload (e.g. after hosting or switching tabs).
final discoverRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Increment to reload My Activities when returning to that tab.
final activitiesRefreshTickProvider = StateProvider<int>((ref) => 0);
