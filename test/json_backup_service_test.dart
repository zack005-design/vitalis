import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/data/export/json_backup_service.dart';

void main() {
  late AppDatabase db;
  late JsonBackupService backupService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backupService = JsonBackupService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('JsonBackupService - Export', () {
    test('generateBackupData outputs empty lists for all 4 tables when database is empty', () async {
      final data = await backupService.generateBackupData();

      expect(data['app'], equals('Personal Calorie Water Sleep Tracker'));
      expect(data['version'], equals(1));
      expect(data['exported_at'], isNotNull);
      expect(data['meals'], isEmpty);
      expect(data['custom_foods'], isEmpty);
      expect(data['sleep_notes'], isEmpty);
      expect(data['water_logs'], isEmpty);
    });

    test('generateBackupData correctly serializes all 4 tables with all fields', () async {
      final now = DateTime(2026, 8, 15, 12, 30);

      // Insert test meal
      await db.insertMeal(
        MealsCompanion.insert(
          timestamp: now,
          name: 'Grilled Chicken & Rice',
          calories: 550,
          proteinG: const Value(45.0),
          carbsG: const Value(50.0),
          fatG: const Value(12.0),
          source: const Value('manual'),
          healthConnectSynced: const Value(true),
          notes: const Value('Post-workout lunch'),
        ),
      );

      // Insert test custom food
      await db.insertCustomFood(
        CustomFoodsCompanion.insert(
          name: 'Homemade Protein Shake',
          caloriesPerServing: 280,
          servingDescription: const Value('1 shaker bottle'),
          proteinG: const Value(32.0),
          carbsG: const Value(15.0),
          fatG: const Value(4.0),
          createdAt: now,
        ),
      );

      // Insert test sleep note
      final bedtime = DateTime(2026, 8, 14, 23, 0);
      final wakeTime = DateTime(2026, 8, 15, 7, 0);
      await db.insertSleepNote(
        SleepNotesCompanion.insert(
          date: DateTime(2026, 8, 14),
          bedtime: Value(bedtime),
          wakeTime: Value(wakeTime),
          durationMinutes: const Value(480),
          ratingStars: const Value(5),
          noteText: const Value('Felt great and well-rested'),
          createdAt: now,
        ),
      );

      // Insert test water log
      await db.insertWaterLog(
        WaterLogsCompanion.insert(
          timestamp: now,
          amountMl: 500,
        ),
      );

      final data = await backupService.generateBackupData();

      // Check meals
      final meals = data['meals'] as List;
      expect(meals.length, equals(1));
      expect(meals[0]['name'], equals('Grilled Chicken & Rice'));
      expect(meals[0]['calories'], equals(550));
      expect(meals[0]['proteinG'], equals(45.0));
      expect(meals[0]['carbsG'], equals(50.0));
      expect(meals[0]['fatG'], equals(12.0));
      expect(meals[0]['source'], equals('manual'));
      expect(meals[0]['healthConnectSynced'], isTrue);
      expect(meals[0]['notes'], equals('Post-workout lunch'));

      // Check custom foods
      final customFoods = data['custom_foods'] as List;
      expect(customFoods.length, equals(1));
      expect(customFoods[0]['name'], equals('Homemade Protein Shake'));
      expect(customFoods[0]['caloriesPerServing'], equals(280));
      expect(customFoods[0]['servingDescription'], equals('1 shaker bottle'));
      expect(customFoods[0]['proteinG'], equals(32.0));
      expect(customFoods[0]['createdAt'], equals(now.toIso8601String()));

      // Check sleep notes
      final sleepNotes = data['sleep_notes'] as List;
      expect(sleepNotes.length, equals(1));
      expect(sleepNotes[0]['durationMinutes'], equals(480));
      expect(sleepNotes[0]['ratingStars'], equals(5));
      expect(sleepNotes[0]['noteText'], equals('Felt great and well-rested'));
      expect(sleepNotes[0]['bedtime'], equals(bedtime.toIso8601String()));
      expect(sleepNotes[0]['wakeTime'], equals(wakeTime.toIso8601String()));

      // Check water logs
      final waterLogs = data['water_logs'] as List;
      expect(waterLogs.length, equals(1));
      expect(waterLogs[0]['amountMl'], equals(500));
      expect(waterLogs[0]['timestamp'], equals(now.toIso8601String()));

      // Verify exportJsonString produces valid parseable JSON
      final jsonStr = await backupService.exportJsonString();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['meals'], isNotEmpty);
      expect(decoded['custom_foods'], isNotEmpty);
      expect(decoded['sleep_notes'], isNotEmpty);
      expect(decoded['water_logs'], isNotEmpty);
    });
  });

  group('JsonBackupService - Import', () {
    test('importFromJson restores all 4 tables accurately', () async {
      final backupJson = jsonEncode({
        "app": "Personal Calorie Water Sleep Tracker",
        "version": 1,
        "exported_at": "2026-08-15T12:00:00.000",
        "meals": [
          {
            "id": 10,
            "timestamp": "2026-08-15T08:30:00.000",
            "name": "Oatmeal with Berries",
            "calories": 350,
            "proteinG": 12.5,
            "carbsG": 60.0,
            "fatG": 5.5,
            "source": "manual",
            "healthConnectSynced": false,
            "notes": "Healthy breakfast"
          }
        ],
        "custom_foods": [
          {
            "id": 20,
            "name": "Greek Yogurt Bowl",
            "caloriesPerServing": 220,
            "servingDescription": "1 bowl",
            "proteinG": 20.0,
            "carbsG": 15.0,
            "fatG": 3.0,
            "createdAt": "2026-08-15T07:00:00.000"
          }
        ],
        "sleep_notes": [
          {
            "id": 30,
            "date": "2026-08-14T00:00:00.000",
            "bedtime": "2026-08-14T22:30:00.000",
            "wakeTime": "2026-08-15T06:30:00.000",
            "durationMinutes": 480,
            "ratingStars": 4,
            "noteText": "Deep sleep",
            "createdAt": "2026-08-15T06:35:00.000"
          }
        ],
        "water_logs": [
          {
            "id": 40,
            "timestamp": "2026-08-15T09:00:00.000",
            "amountMl": 350
          }
        ]
      });

      final count = await backupService.importFromJson(backupJson);
      expect(count, equals(4));

      // Verify database contents
      final meals = await db.getAllMeals();
      expect(meals.length, equals(1));
      expect(meals[0].id, equals(10));
      expect(meals[0].name, equals('Oatmeal with Berries'));
      expect(meals[0].calories, equals(350));
      expect(meals[0].proteinG, equals(12.5));

      final foods = await db.getAllCustomFoods();
      expect(foods.length, equals(1));
      expect(foods[0].id, equals(20));
      expect(foods[0].name, equals('Greek Yogurt Bowl'));

      final sleep = await db.getAllSleepNotes();
      expect(sleep.length, equals(1));
      expect(sleep[0].id, equals(30));
      expect(sleep[0].durationMinutes, equals(480));
      expect(sleep[0].ratingStars, equals(4));

      final water = await db.getAllWaterLogs();
      expect(water.length, equals(1));
      expect(water[0].id, equals(40));
      expect(water[0].amountMl, equals(350));
    });

    test('importFromJson safely upserts/replaces duplicate IDs without crashing', () async {
      // First insert an existing meal with ID 1
      await db.into(db.meals).insert(
            MealsCompanion.insert(
              id: const Value(1),
              timestamp: DateTime(2026, 8, 15, 8, 0),
              name: 'Old Meal Name',
              calories: 100,
            ),
          );

      // Also insert a water log with ID 1
      await db.into(db.waterLogs).insert(
            WaterLogsCompanion.insert(
              id: const Value(1),
              timestamp: DateTime(2026, 8, 15, 8, 0),
              amountMl: 250,
            ),
          );

      // Now import a backup containing updated records for ID 1
      final backupJson = jsonEncode({
        "meals": [
          {
            "id": 1,
            "timestamp": "2026-08-15T08:00:00.000",
            "name": "Updated Meal Name",
            "calories": 450,
            "proteinG": 30.0,
          }
        ],
        "water_logs": [
          {
            "id": 1,
            "timestamp": "2026-08-15T08:00:00.000",
            "amountMl": 750,
          }
        ]
      });

      await backupService.importFromJson(backupJson);

      final meals = await db.getAllMeals();
      expect(meals.length, equals(1));
      expect(meals[0].id, equals(1));
      expect(meals[0].name, equals('Updated Meal Name'));
      expect(meals[0].calories, equals(450));

      final water = await db.getAllWaterLogs();
      expect(water.length, equals(1));
      expect(water[0].id, equals(1));
      expect(water[0].amountMl, equals(750));
    });

    test('importFromJson supports nested "data" wrapper and alternate key naming conventions', () async {
      final nestedJson = jsonEncode({
        "version": 1,
        "data": {
          "meals": [
            {
              "name": "Salmon Salad",
              "timestamp": "2026-08-15T12:00:00.000",
              "calories": 420,
              "protein_g": 35.0,
              "carbs_g": 10.0,
              "fat_g": 22.0,
            }
          ],
          "customFoods": [
            {
              "name": "Almond Milk",
              "calories_per_serving": 40,
              "serving_description": "1 cup",
            }
          ],
          "sleepNotes": [
            {
              "date": "2026-08-15T00:00:00.000",
              "duration_minutes": 450,
              "rating_stars": 5,
              "note_text": "Good recovery"
            }
          ],
          "waterLogs": [
            {
              "timestamp": "2026-08-15T10:00:00.000",
              "amount_ml": 500
            }
          ]
        }
      });

      final count = await backupService.importFromJson(nestedJson);
      expect(count, equals(4));

      final meals = await db.getAllMeals();
      expect(meals.first.name, equals('Salmon Salad'));
      expect(meals.first.proteinG, equals(35.0));

      final foods = await db.getAllCustomFoods();
      expect(foods.first.name, equals('Almond Milk'));
      expect(foods.first.caloriesPerServing, equals(40));

      final sleep = await db.getAllSleepNotes();
      expect(sleep.first.durationMinutes, equals(450));

      final water = await db.getAllWaterLogs();
      expect(water.first.amountMl, equals(500));
    });

    test('importFromJson throws FormatException for invalid JSON or unparseable dates', () async {
      expect(
        () => backupService.importFromJson(''),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => backupService.importFromJson('not valid json {['),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => backupService.importFromJson('["array", "not", "object"]'),
        throwsA(isA<FormatException>()),
      );

      // Unparseable meal timestamp
      expect(
        () => backupService.importFromJson(jsonEncode({
          "meals": [
            {"name": "Invalid Date Meal", "timestamp": "not-a-date", "calories": 200}
          ]
        })),
        throwsA(isA<FormatException>()),
      );

      // Missing meal timestamp
      expect(
        () => backupService.importFromJson(jsonEncode({
          "meals": [
            {"name": "No Date Meal", "calories": 200}
          ]
        })),
        throwsA(isA<FormatException>()),
      );

      // Unparseable sleep date
      expect(
        () => backupService.importFromJson(jsonEncode({
          "sleep_notes": [
            {"date": "invalid-sleep-date", "duration_minutes": 400}
          ]
        })),
        throwsA(isA<FormatException>()),
      );

      // Unparseable water log timestamp
      expect(
        () => backupService.importFromJson(jsonEncode({
          "water_logs": [
            {"timestamp": "invalid-water-date", "amount_ml": 250}
          ]
        })),
        throwsA(isA<FormatException>()),
      );
    });

    test('Full export and import roundtrip preserves database integrity', () async {
      // 1. Seed database with multiple records across all tables
      final t1 = DateTime(2026, 8, 15, 9, 0);
      final t2 = DateTime(2026, 8, 15, 13, 0);

      await db.insertMeal(MealsCompanion.insert(timestamp: t1, name: 'Breakfast', calories: 400));
      await db.insertMeal(MealsCompanion.insert(timestamp: t2, name: 'Lunch', calories: 650));
      await db.insertCustomFood(CustomFoodsCompanion.insert(name: 'Protein Bar', caloriesPerServing: 200, createdAt: t1));
      await db.insertSleepNote(SleepNotesCompanion.insert(date: t1, durationMinutes: const Value(420), createdAt: t1));
      await db.insertWaterLog(WaterLogsCompanion.insert(timestamp: t1, amountMl: 250));
      await db.insertWaterLog(WaterLogsCompanion.insert(timestamp: t2, amountMl: 500));

      // 2. Export to JSON string
      final exportedJson = await backupService.exportJsonString();

      // 3. Clear database
      await db.delete(db.meals).go();
      await db.delete(db.customFoods).go();
      await db.delete(db.sleepNotes).go();
      await db.delete(db.waterLogs).go();

      expect(await db.getAllMeals(), isEmpty);
      expect(await db.getAllCustomFoods(), isEmpty);
      expect(await db.getAllSleepNotes(), isEmpty);
      expect(await db.getAllWaterLogs(), isEmpty);

      // 4. Import the exported backup
      final importedCount = await backupService.importFromJson(exportedJson);
      expect(importedCount, equals(6));

      // 5. Assert all records restored correctly
      final restoredMeals = await db.getAllMeals();
      expect(restoredMeals.length, equals(2));
      expect(restoredMeals.map((m) => m.name), containsAll(['Breakfast', 'Lunch']));

      final restoredFoods = await db.getAllCustomFoods();
      expect(restoredFoods.length, equals(1));
      expect(restoredFoods.first.name, equals('Protein Bar'));

      final restoredSleep = await db.getAllSleepNotes();
      expect(restoredSleep.length, equals(1));
      expect(restoredSleep.first.durationMinutes, equals(420));

      final restoredWater = await db.getAllWaterLogs();
      expect(restoredWater.length, equals(2));
      expect(restoredWater.map((w) => w.amountMl), containsAll([250, 500]));
    });
  });
}
