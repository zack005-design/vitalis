import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';
import '../design_system/swipe_to_delete_row.dart';

class WaterHistorySheet extends ConsumerWidget {
  const WaterHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Water Intake & History",
      child: const WaterHistorySheet(),
    );
  }

  Future<void> _addWater(WidgetRef ref, int amountMl) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertWaterLog(
      WaterLogsCompanion(
        amountMl: drift.Value(amountMl),
        timestamp: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> _deleteWater(WidgetRef ref, int id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteWaterLog(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterLogsAsync = ref.watch(todayWaterLogsProvider);
    final totalWaterMl = ref.watch(totalWaterMlTodayProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Hydration Summary Header
        GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Hydration", style: AppTypography.subhead(isDark)),
                  const SizedBox(height: 4),
                  Text(
                    "${(totalWaterMl / 1000).toStringAsFixed(1)}L / 2.0L",
                    style: AppTypography.headlineMd(isDark).copyWith(
                      color: AppColors.waterAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                        ),
                      ),
                    ),
                    onPressed: () => _addWater(ref, 250),
                    child: const Text("+250ml", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.waterAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _addWater(ref, 500),
                    child: const Text("+500ml", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          "Today's Water Logs",
          style: AppTypography.headline(isDark),
        ),
        const SizedBox(height: 8),

        // Reactive Water Logs List
        waterLogsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("Error loading water logs", style: AppTypography.footnote(isDark))),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text("No water logged today yet.", style: AppTypography.bodyMd(isDark)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                final timeStr = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}";

                return SwipeToDeleteRow(
                  itemKey: ValueKey(log.id),
                  title: "${log.amountMl}ml water",
                  onDelete: () => _deleteWater(ref, log.id),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_rounded, color: AppColors.waterAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              "${log.amountMl} ml",
                              style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          timeStr,
                          style: AppTypography.labelSm(isDark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
