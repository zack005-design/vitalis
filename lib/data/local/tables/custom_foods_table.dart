import 'package:drift/drift.dart';

/// Drift SQLite Table definition for user-created custom foods.
class CustomFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get caloriesPerServing => integer()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  TextColumn get servingDescription => text().withDefault(const Constant('1 serving'))();
  DateTimeColumn get createdAt => dateTime()();
}
