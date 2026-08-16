
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart'; // contains appDatabaseProvider
import '../../domain/sleep/active_sleep_provider.dart';
import '../../data/sleep/active_sleep_tracker_service.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_container.dart';

class ActiveSleepTrackerScreen extends ConsumerStatefulWidget {
  const ActiveSleepTrackerScreen({super.key});

  @override
  ConsumerState<ActiveSleepTrackerScreen> createState() => _ActiveSleepTrackerScreenState();
}

class _ActiveSleepTrackerScreenState extends ConsumerState<ActiveSleepTrackerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Enable Wakelock to prevent screen from sleeping
    WakelockPlus.enable();

    // Setup pulsing animation for the sleep indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Start tracking when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeSleepTrackerProvider).start();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  Future<void> _endSleepSession() async {
    final tracker = ref.read(activeSleepTrackerProvider);
    final totalMinutes = tracker.elapsed.inMinutes;

    setState(() => _isSaving = true);
    tracker.stop();
    WakelockPlus.disable();

    try {
      final db = ref.read(appDatabaseProvider);
      final bed = tracker.startTime ?? DateTime.now();
      final wake = DateTime.now();

      if (totalMinutes > 0) {
        await db.insertSleepNote(
          SleepNotesCompanion(
            date: drift.Value(wake),
            bedtime: drift.Value(bed),
            wakeTime: drift.Value(wake),
            durationMinutes: drift.Value(totalMinutes),
            noteText: drift.Value(
                "Active Sensor Tracking\nDeep: ${tracker.deepSleepMinutes}m\nLight: ${tracker.lightSleepMinutes}m\nAwake: ${tracker.awakeMinutes}m"),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to save active sleep: $e");
    }

    tracker.reset();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracker = ref.watch(activeSleepTrackerProvider);

    String phaseText;
    Color phaseColor;
    switch (tracker.currentPhase) {
      case SleepPhase.deep:
        phaseText = "Deep Sleep";
        phaseColor = const Color(0xFF6C63FF);
        break;
      case SleepPhase.light:
        phaseText = "Light Sleep";
        phaseColor = const Color(0xFF42A5F5);
        break;
      case SleepPhase.awake:
        phaseText = "Awake / Restless";
        phaseColor = const Color(0xFFFFB74D);
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: "Sleep Tracker",
      body: Column(
        children: [
          const SizedBox(height: 40),
          
          // Pulsing Sleep Indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: isDark ? 0.3 : 0.2),
                        blurRadius: 40,
                        spreadRadius: 20 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.bedtime_rounded, size: 60, color: phaseColor.withValues(alpha: 0.8)),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Tracker Stats Card
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                Text(
                  "Tracking Active",
                  style: AppTypography.subhead(isDark).copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(tracker.elapsed),
                  style: AppTypography.headline(isDark).copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phaseText,
                    style: AppTypography.bodyMd(isDark).copyWith(
                      color: phaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Leave your phone on the mattress next to you.\nTracking relies on the device's sensors.",
              textAlign: TextAlign.center,
              style: AppTypography.footnote(isDark),
            ),
          ),
          const SizedBox(height: 32),

          // Wake Up Button
          _isSaving 
            ? const Center(child: CircularProgressIndicator())
            : AppButton(
                label: "Hold to Wake Up",
                icon: Icons.sunny,
                onPressed: _endSleepSession,
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
