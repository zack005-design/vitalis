import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'tables/meals_table.dart';
import 'tables/custom_foods_table.dart';
import 'tables/sleep_notes_table.dart';
import 'tables/water_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Meals, CustomFoods, SleepNotes, WaterLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 3) {
          try {
            await m.addColumn(waterLogs, waterLogs.amountMl);
          } catch (e) {
            debugPrint('Migration error (waterLogs.amountMl): $e');
          }
        }
        if (from < 4) {
          // Add new columns to sleep_notes
          try {
            await m.addColumn(sleepNotes, sleepNotes.bedtime);
          } catch (e) {
            debugPrint('Migration error (sleepNotes.bedtime): $e');
          }
          try {
            await m.addColumn(sleepNotes, sleepNotes.wakeTime);
          } catch (e) {
            debugPrint('Migration error (sleepNotes.wakeTime): $e');
          }
          try {
            await m.addColumn(sleepNotes, sleepNotes.durationMinutes);
          } catch (e) {
            debugPrint('Migration error (sleepNotes.durationMinutes): $e');
          }
          // Make noteText optional migration — recreate table safely
        }
      },
    );
  }

  // Meal DAOs
  Stream<List<Meal>> watchTodayMeals(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(meals)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<List<Meal>> getAllMeals() => select(meals).get();
  Future<int> insertMeal(MealsCompanion meal) => into(meals).insert(meal);
  Future<bool> updateMeal(Meal meal) => update(meals).replace(meal);
  Future<int> deleteMeal(int id) => (delete(meals)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<Meal>> getMealsForDateRange(DateTime start, DateTime end) {
    return (select(meals)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Map<String, dynamic>>> getDailyCaloriesForDateRange(DateTime start, DateTime end) async {
    final query = '''
      SELECT strftime('%Y-%m-%d', timestamp, 'unixepoch', 'localtime') AS date, SUM(calories) AS total 
      FROM meals 
      WHERE timestamp >= ? AND timestamp < ? 
      GROUP BY date
    ''';
    final result = await customSelect(query, variables: [
      Variable.withDateTime(start),
      Variable.withDateTime(end)
    ]).get();
    return result.map((row) => row.data).toList();
  }

  // Water Log DAOs
  Stream<List<WaterLog>> watchTodayWaterLogs(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterLogs)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<int> insertWaterLog(WaterLogsCompanion log) => into(waterLogs).insert(log);
  Future<int> deleteWaterLog(int id) => (delete(waterLogs)..where((tbl) => tbl.id.equals(id))).go();
  Future<List<WaterLog>> getAllWaterLogs() => select(waterLogs).get();

  Future<List<WaterLog>> getWaterLogsForDateRange(DateTime start, DateTime end) {
    return (select(waterLogs)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Map<String, dynamic>>> getDailyWaterForDateRange(DateTime start, DateTime end) async {
    final query = '''
      SELECT strftime('%Y-%m-%d', timestamp, 'unixepoch', 'localtime') AS date, SUM(amount_ml) AS total 
      FROM water_logs 
      WHERE timestamp >= ? AND timestamp < ? 
      GROUP BY date
    ''';
    final result = await customSelect(query, variables: [
      Variable.withDateTime(start),
      Variable.withDateTime(end)
    ]).get();
    return result.map((row) => row.data).toList();
  }

  // Sleep Notes DAOs
  Stream<List<SleepNote>> watchSleepNotes() {
    return (select(sleepNotes)..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])).watch();
  }

  Stream<List<SleepNote>> watchLastNSleepNotes(int n) {
    return (select(sleepNotes)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
          ..limit(n))
        .watch();
  }

  Future<List<SleepNote>> getAllSleepNotes() => select(sleepNotes).get();

  Future<List<SleepNote>> getSleepNotesForDateRange(DateTime start, DateTime end) {
    return (select(sleepNotes)
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.date.isSmallerThanValue(end)))
        .get();
  }

  Future<int> insertSleepNote(SleepNotesCompanion note) => into(sleepNotes).insert(note);

  // Custom Foods DAOs
  Stream<List<CustomFood>> watchCustomFoods() {
    return (select(customFoods)..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).watch();
  }

  Future<List<CustomFood>> getAllCustomFoods() => select(customFoods).get();

  Future<int> insertCustomFood(CustomFoodsCompanion food) => into(customFoods).insert(food);

  Future<List<CustomFood>> searchCustomFoods(String query) {
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    return (select(customFoods)..where((tbl) => tbl.name.like(cleanQuery))).get();
  }

  Future<void> restoreMeal(Meal meal) => into(meals).insert(meal, mode: InsertMode.insertOrReplace);
  Future<void> restoreWaterLog(WaterLog log) => into(waterLogs).insert(log, mode: InsertMode.insertOrReplace);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vitality_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
