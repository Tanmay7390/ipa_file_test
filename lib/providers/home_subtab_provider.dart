import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the current home sub-tab index
// 0 = Recents, 1 = Shared, 2 = Browse
final homeSubTabProvider = StateProvider<int>((ref) => 0);
