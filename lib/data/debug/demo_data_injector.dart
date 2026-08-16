import 'dart:math';
import 'package:drift/drift.dart' as drift;
import '../local/app_database.dart';

class DemoDataInjector {
  final AppDatabase db;
  final Random _random = Random();

  DemoDataInjector(this.db);

  Future<void> injectData(int days) async {
    final now = DateTime.now();
    final mealCompanions = <MealsCompanion>[];
    final waterCompanions = <WaterLogsCompanion>[];
    final sleepCompanions = <SleepNotesCompanion>[];

    final customFoodsCompanions = <CustomFoodsCompanion>[];
    final favoriteFoodsCompanions = <FavoriteFoodsCompanion>[];

    final mealNames = [
      'Oatmeal & Berries', 'Grilled Chicken Salad', 'Salmon & Quinoa', 
      'Protein Shake', 'Greek Yogurt', 'Scrambled Eggs', 'Turkey Sandwich', 
      'Beef Stir-fry', 'Avocado Toast', 'Lentil Soup'
    ];

    for (int i = 0; i < days; i++) {
      final currentDay = now.subtract(Duration(days: i));

      // 1. Generate Meals (3 to 5 meals per day)
      final numMeals = _random.nextInt(3) + 3; // 3, 4, or 5
      for (int m = 0; m < numMeals; m++) {
        // Distribute meals across the day (8 AM to 8 PM)
        final hour = 8 + (m * (12 / numMeals)).floor() + _random.nextInt(2);
        final minute = _random.nextInt(60);
        final mealTime = DateTime(currentDay.year, currentDay.month, currentDay.day, hour, minute);

        final name = mealNames[_random.nextInt(mealNames.length)];
        final calories = 300 + _random.nextInt(500); // 300 to 800
        final protein = 15.0 + _random.nextInt(40); // 15g to 55g
        final carbs = 20.0 + _random.nextInt(60); // 20g to 80g
        final fat = 10.0 + _random.nextInt(25); // 10g to 35g

        mealCompanions.add(
          MealsCompanion.insert(
            name: name,
            calories: calories,
            proteinG: drift.Value(protein),
            carbsG: drift.Value(carbs),
            fatG: drift.Value(fat),
            timestamp: mealTime,
          ),
        );
      }

      // 2. Generate Water Logs (4 to 8 logs per day)
      final numWaterLogs = _random.nextInt(5) + 4; // 4 to 8
      for (int w = 0; w < numWaterLogs; w++) {
        final hour = 7 + (w * (14 / numWaterLogs)).floor() + _random.nextInt(2);
        final minute = _random.nextInt(60);
        final waterTime = DateTime(currentDay.year, currentDay.month, currentDay.day, hour, minute);
        
        final amount = 200 + (_random.nextInt(4) * 100); // 200, 300, 400, 500 ml

        waterCompanions.add(
          WaterLogsCompanion.insert(
            amountMl: amount,
            timestamp: waterTime,
          ),
        );
      }

      // 3. Generate Sleep Notes (1 session per night)
      // Usually waking up around 6-9 AM, duration 5 to 9 hours
      final wakeHour = 6 + _random.nextInt(4);
      final wakeMinute = _random.nextInt(60);
      final sleepDate = DateTime(currentDay.year, currentDay.month, currentDay.day, wakeHour, wakeMinute);
      
      final durationMinutes = 300 + _random.nextInt(240); // 5 to 9 hours (300 to 540 minutes)

      sleepCompanions.add(
        SleepNotesCompanion.insert(
          date: sleepDate,
          durationMinutes: drift.Value(durationMinutes),
          noteText: const drift.Value('Demo generated sleep data'),
          createdAt: now,
        ),
      );
    }

    // 4. Generate Custom Foods
    final customFoodNames = ['Aunt Mary\'s Pie', 'Mom\'s Spaghetti', 'Special Protein Shake', 'Secret Sauce', 'Homemade Granola'];
    for (var name in customFoodNames) {
       customFoodsCompanions.add(
         CustomFoodsCompanion.insert(
           name: name,
           caloriesPerServing: 150 + _random.nextInt(300),
           proteinG: drift.Value(5.0 + _random.nextInt(20)),
           carbsG: drift.Value(10.0 + _random.nextInt(40)),
           fatG: drift.Value(5.0 + _random.nextInt(20)),
           createdAt: now,
         ),
       );
    }

    // 5. Generate Favorite Foods
    final favFoodNames = ['Banana', 'Apple', 'Chicken Breast', 'Rice', 'Broccoli'];
    for (var name in favFoodNames) {
       favoriteFoodsCompanions.add(
         FavoriteFoodsCompanion.insert(
           name: name,
           calories: 50 + _random.nextInt(200),
           proteinG: drift.Value(1.0 + _random.nextInt(30)),
           carbsG: drift.Value(5.0 + _random.nextInt(30)),
           fatG: drift.Value(0.0 + _random.nextInt(10)),
           servingDescription: '1 serving',
           source: 'mock',
         ),
       );
    }

    // Bulk insert all generated data using drift batch
    await db.batch((batch) {
      batch.insertAll(db.meals, mealCompanions);
      batch.insertAll(db.waterLogs, waterCompanions);
      batch.insertAll(db.sleepNotes, sleepCompanions);
      batch.insertAll(db.customFoods, customFoodsCompanions);
      batch.insertAll(db.favoriteFoods, favoriteFoodsCompanions);
    });
  }
}
