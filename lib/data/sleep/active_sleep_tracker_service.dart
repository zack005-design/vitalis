import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum SleepPhase { awake, light, deep }

class ActiveSleepTrackerService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _minuteTimer;
  Timer? _durationTimer;

  DateTime? _startTime;
  Duration _elapsed = Duration.zero;

  // Analysis
  final List<double> _minuteMagnitudes = [];
  int _deepSleepMinutes = 0;
  int _lightSleepMinutes = 0;
  int _awakeMinutes = 0;

  SleepPhase _currentPhase = SleepPhase.awake;

  bool get isTracking => _startTime != null;
  Duration get elapsed => _elapsed;
  SleepPhase get currentPhase => _currentPhase;
  int get deepSleepMinutes => _deepSleepMinutes;
  int get lightSleepMinutes => _lightSleepMinutes;
  int get awakeMinutes => _awakeMinutes;
  DateTime? get startTime => _startTime;

  // Thresholds for movement intensity
  static const double _lightSleepThreshold = 0.5;
  static const double _awakeThreshold = 2.0;

  void start() {
    if (isTracking) return;

    _startTime = DateTime.now();
    _elapsed = Duration.zero;
    _deepSleepMinutes = 0;
    _lightSleepMinutes = 0;
    _awakeMinutes = 0;
    _minuteMagnitudes.clear();
    _currentPhase = SleepPhase.awake; // Usually awake when you start
    notifyListeners();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200), // 5Hz is enough for sleep
    ).listen((event) {
      // Calculate magnitude of acceleration minus approximate gravity (9.8 or 9.81)
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final relativeMagnitude = (magnitude - 9.8).abs();
      _minuteMagnitudes.add(relativeMagnitude);
    });

    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _analyzeMinute();
    });
  }

  void _analyzeMinute() {
    if (_minuteMagnitudes.isEmpty) {
      _deepSleepMinutes++;
      _currentPhase = SleepPhase.deep;
      notifyListeners();
      return;
    }

    // Average magnitude over the last minute
    final sum = _minuteMagnitudes.reduce((a, b) => a + b);
    final avg = sum / _minuteMagnitudes.length;
    _minuteMagnitudes.clear();

    if (avg >= _awakeThreshold) {
      _awakeMinutes++;
      _currentPhase = SleepPhase.awake;
    } else if (avg >= _lightSleepThreshold) {
      _lightSleepMinutes++;
      _currentPhase = SleepPhase.light;
    } else {
      _deepSleepMinutes++;
      _currentPhase = SleepPhase.deep;
    }
    
    notifyListeners();
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _minuteTimer?.cancel();
    _minuteTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void reset() {
    stop();
    _startTime = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
