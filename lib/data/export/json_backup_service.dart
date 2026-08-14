import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../local/app_database.dart';

class JsonBackupService {
  final AppDatabase db;

  JsonBackupService({required this.db});

  /// Export database records into a serialized JSON backup file
  Future<File> exportToJson() async {
    final meals = await db.getAllMeals();
    final customFoods = await db.searchCustomFoods('');

    final backupData = {
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
              })
          .toList(),
    };

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final file = File('${tempDir.path}/caltrack_backup_$dateStr.json');

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backupData));
    return file;
  }
}
