import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sleep/active_sleep_tracker_service.dart';

final activeSleepTrackerProvider = ChangeNotifierProvider<ActiveSleepTrackerService>((ref) {
  final service = ActiveSleepTrackerService();
  ref.onDispose(() => service.dispose());
  return service;
});
