import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import '../local/app_database.dart';

class JsonBackupService {
  final AppDatabase db;

  JsonBackupService({required this.db});

  /// Serializes database records into a raw Map structure containing all 4 tables
  Future<Map<String, dynamic>> generateBackupData() async {
    final meals = await db.getAllMeals();
    final customFoods = await db.getAllCustomFoods();
    final sleepNotes = await db.getAllSleepNotes();
    final waterLogs = await db.getAllWaterLogs();

    return {
      "app": "Personal Calorie Water Sleep Tracker",
      "version": 1,
      "exported_at": DateTime.now().toIso8601String(),
      "meals": meals
          .map((m) => {
                "id": m.id,
                "timestamp": m.timestamp.toIso8601String(),
                "name": m.name,
                "calories": m.calories,
                "proteinG": m.proteinG,
                "carbsG": m.carbsG,
                "fatG": m.fatG,
                "source": m.source,
                "healthConnectSynced": m.healthConnectSynced,
                "notes": m.notes,
              })
          .toList(),
      "custom_foods": customFoods
          .map((cf) => {
                "id": cf.id,
                "name": cf.name,
                "caloriesPerServing": cf.caloriesPerServing,
                "servingDescription": cf.servingDescription,
                "proteinG": cf.proteinG,
                "carbsG": cf.carbsG,
                "fatG": cf.fatG,
                "createdAt": cf.createdAt.toIso8601String(),
              })
          .toList(),
      "sleep_notes": sleepNotes
          .map((s) => {
                "id": s.id,
                "date": s.date.toIso8601String(),
                "bedtime": s.bedtime?.toIso8601String(),
                "wakeTime": s.wakeTime?.toIso8601String(),
                "durationMinutes": s.durationMinutes,
                "ratingStars": s.ratingStars,
                "noteText": s.noteText,
                "createdAt": s.createdAt.toIso8601String(),
              })
          .toList(),
      "water_logs": waterLogs
          .map((w) => {
                "id": w.id,
                "timestamp": w.timestamp.toIso8601String(),
                "amountMl": w.amountMl,
              })
          .toList(),
    };
  }

  /// Exports database records into a formatted JSON string
  Future<String> exportJsonString() async {
    final data = await generateBackupData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export database records into a serialized JSON backup file
  Future<File> exportToJson() async {
    final backupData = await generateBackupData();

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final file = File('${tempDir.path}/caltrack_backup_$dateStr.json');

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backupData));
    return file;
  }

  /// Deserializes a JSON backup string and performs bulk upserts into all 4 database tables
  Future<int> importFromJson(String jsonString) async {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('Empty backup JSON string');
    }

    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Invalid JSON payload: expected a JSON object');
    }

    final Map<String, dynamic> data = (decoded.containsKey('data') && decoded['data'] is Map)
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : Map<String, dynamic>.from(decoded);

    final mealCompanions = <MealsCompanion>[];
    final customFoodCompanions = <CustomFoodsCompanion>[];
    final sleepNoteCompanions = <SleepNotesCompanion>[];
    final waterLogCompanions = <WaterLogsCompanion>[];

    // 1. Parse Meals
    final rawMeals = data['meals'] ?? data['Meals'];
    if (rawMeals is List) {
      for (final item in rawMeals) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final id = m['id'] as int?;
          final timestampStr = m['timestamp'] as String?;
          if (timestampStr == null) {
            throw const FormatException('Missing timestamp in meal backup record');
          }
          final timestamp = DateTime.tryParse(timestampStr);
          if (timestamp == null) {
            throw FormatException('Invalid timestamp format in meal record: "$timestampStr"');
          }
          final name = (m['name'] as String?) ?? 'Meal';
          final calories = (m['calories'] as num?)?.toInt() ?? 0;
          final proteinG = (m['proteinG'] ?? m['protein_g'] as num?)?.toDouble();
          final carbsG = (m['carbsG'] ?? m['carbs_g'] as num?)?.toDouble();
          final fatG = (m['fatG'] ?? m['fat_g'] as num?)?.toDouble();
          final source = (m['source'] as String?) ?? 'manual';
          final healthConnectSynced =
              (m['healthConnectSynced'] ?? m['health_connect_synced'] as bool?) ?? false;
          final notes = m['notes'] as String?;

          mealCompanions.add(
            MealsCompanion(
              id: id != null ? Value(id) : const Value.absent(),
              timestamp: Value(timestamp),
              name: Value(name),
              calories: Value(calories),
              proteinG: Value(proteinG),
              carbsG: Value(carbsG),
              fatG: Value(fatG),
              source: Value(source),
              healthConnectSynced: Value(healthConnectSynced),
              notes: Value(notes),
            ),
          );
        }
      }
    }

    // 2. Parse Custom Foods
    final rawFoods = data['custom_foods'] ?? data['customFoods'] ?? data['CustomFoods'];
    if (rawFoods is List) {
      for (final item in rawFoods) {
        if (item is Map) {
          final cf = Map<String, dynamic>.from(item);
          final id = cf['id'] as int?;
          final name = (cf['name'] as String?) ?? 'Custom Food';
          final caloriesPerServing =
              (cf['caloriesPerServing'] ?? cf['calories_per_serving'] as num?)?.toInt() ?? 0;
          final servingDescription =
              (cf['servingDescription'] ?? cf['serving_description'] as String?) ?? '1 serving';
          final proteinG = (cf['proteinG'] ?? cf['protein_g'] as num?)?.toDouble();
          final carbsG = (cf['carbsG'] ?? cf['carbs_g'] as num?)?.toDouble();
          final fatG = (cf['fatG'] ?? cf['fat_g'] as num?)?.toDouble();
          final createdAtStr = (cf['createdAt'] ?? cf['created_at']) as String?;
          final DateTime createdAt;
          if (createdAtStr != null) {
            final parsed = DateTime.tryParse(createdAtStr);
            if (parsed == null) {
              throw FormatException('Invalid createdAt format in custom food record: "$createdAtStr"');
            }
            createdAt = parsed;
          } else {
            createdAt = DateTime.now();
          }

          customFoodCompanions.add(
            CustomFoodsCompanion(
              id: id != null ? Value(id) : const Value.absent(),
              name: Value(name),
              caloriesPerServing: Value(caloriesPerServing),
              servingDescription: Value(servingDescription),
              proteinG: Value(proteinG),
              carbsG: Value(carbsG),
              fatG: Value(fatG),
              createdAt: Value(createdAt),
            ),
          );
        }
      }
    }

    // 3. Parse Sleep Notes
    final rawSleep = data['sleep_notes'] ?? data['sleepNotes'] ?? data['SleepNotes'];
    if (rawSleep is List) {
      for (final item in rawSleep) {
        if (item is Map) {
          final s = Map<String, dynamic>.from(item);
          final id = s['id'] as int?;
          final dateStr = s['date'] as String?;
          if (dateStr == null) {
            throw const FormatException('Missing date in sleep note backup record');
          }
          final date = DateTime.tryParse(dateStr);
          if (date == null) {
            throw FormatException('Invalid date format in sleep note record: "$dateStr"');
          }
          final bedtimeStr = (s['bedtime'] ?? s['bed_time']) as String?;
          final bedtime = bedtimeStr != null ? DateTime.tryParse(bedtimeStr) : null;
          final wakeTimeStr = (s['wakeTime'] ?? s['wake_time']) as String?;
          final wakeTime = wakeTimeStr != null ? DateTime.tryParse(wakeTimeStr) : null;
          final durationMinutes =
              (s['durationMinutes'] ?? s['duration_minutes'] as num?)?.toInt() ?? 0;
          final ratingStars = (s['ratingStars'] ?? s['rating_stars'] as num?)?.toInt() ?? 4;
          final noteText = (s['noteText'] ?? s['note_text'] as String?) ?? '';
          final createdAtStr = (s['createdAt'] ?? s['created_at']) as String?;
          final createdAt = createdAtStr != null
              ? (DateTime.tryParse(createdAtStr) ?? date)
              : date;

          sleepNoteCompanions.add(
            SleepNotesCompanion(
              id: id != null ? Value(id) : const Value.absent(),
              date: Value(date),
              bedtime: Value(bedtime),
              wakeTime: Value(wakeTime),
              durationMinutes: Value(durationMinutes),
              ratingStars: Value(ratingStars),
              noteText: Value(noteText),
              createdAt: Value(createdAt),
            ),
          );
        }
      }
    }

    // 4. Parse Water Logs
    final rawWater = data['water_logs'] ?? data['waterLogs'] ?? data['WaterLogs'];
    if (rawWater is List) {
      for (final item in rawWater) {
        if (item is Map) {
          final w = Map<String, dynamic>.from(item);
          final id = w['id'] as int?;
          final timestampStr = w['timestamp'] as String?;
          if (timestampStr == null) {
            throw const FormatException('Missing timestamp in water log backup record');
          }
          final timestamp = DateTime.tryParse(timestampStr);
          if (timestamp == null) {
            throw FormatException('Invalid timestamp format in water log record: "$timestampStr"');
          }
          final amountMl = (w['amountMl'] ?? w['amount_ml'] as num?)?.toInt() ?? 0;

          waterLogCompanions.add(
            WaterLogsCompanion(
              id: id != null ? Value(id) : const Value.absent(),
              timestamp: Value(timestamp),
              amountMl: Value(amountMl),
            ),
          );
        }
      }
    }

    // Execute bulk inserts / upserts with insertOrReplace
    await db.batch((batch) {
      if (mealCompanions.isNotEmpty) {
        batch.insertAll(db.meals, mealCompanions, mode: InsertMode.insertOrReplace);
      }
      if (customFoodCompanions.isNotEmpty) {
        batch.insertAll(db.customFoods, customFoodCompanions, mode: InsertMode.insertOrReplace);
      }
      if (sleepNoteCompanions.isNotEmpty) {
        batch.insertAll(db.sleepNotes, sleepNoteCompanions, mode: InsertMode.insertOrReplace);
      }
      if (waterLogCompanions.isNotEmpty) {
        batch.insertAll(db.waterLogs, waterLogCompanions, mode: InsertMode.insertOrReplace);
      }
    });

    return mealCompanions.length +
        customFoodCompanions.length +
        sleepNoteCompanions.length +
        waterLogCompanions.length;
  }
}
