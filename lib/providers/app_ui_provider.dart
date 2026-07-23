import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to ask Discover to reload (e.g. after hosting or switching tabs).
final discoverRefreshTickProvider = StateProvider<int>((ref) => 0);
