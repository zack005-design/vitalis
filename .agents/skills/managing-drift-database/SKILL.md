---
name: managing-drift-database
description: Guides schema design, reactive DAOs, SQLite table migrations, and code generation using Drift in Flutter. Use when creating database tables, adding DAOs, writing reactive streams, or running build_runner for database migrations.
---

# Managing Drift Database in Flutter

## When to use this skill
- Defining new database tables or columns using `drift`.
- Creating DAOs for reactive data access (Riverpod integration).
- Running `build_runner` code generation for database schema updates.
- Writing schema migration logic when modifying existing SQLite structures.

## Workflow Checklist
- [ ] Define table schema in `lib/data/local/tables/`.
- [ ] Annotate primary keys, auto-increments, and nullability explicitly.
- [ ] Include `@DriftDatabase` annotations on the main database class in `lib/data/local/app_database.dart`.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart` code.
- [ ] Expose reactive streams (`watch()`) for UI Riverpod providers rather than one-time `get()` futures.

## Code Pattern: Drift Table & DAO Template

```dart
import 'package:drift/drift.dart';

// Table Definition
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get name => text()();
  IntColumn get calories => integer()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // manual | local_db | open_food_facts
  BoolColumn get healthConnectSynced => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

// Reactive DAO Pattern
@DriftAccessor(tables: [Meals])
class MealsDao extends DatabaseAccessor<AppDatabase> with _$MealsDaoMixin {
  MealsDao(super.db);

  Stream<List<Meal>> watchTodayMeals(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(meals)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(start))
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<int> insertMeal(MealsCompanion meal) => into(meals).insert(meal);
  Future<bool> updateMeal(Meal meal) => update(meals).replace(meal);
  Future<int> deleteMeal(int id) => (delete(meals)..where((tbl) => tbl.id.equals(id))).go();
}
```

## Build & Code Generation Command
When table schemas are modified, run:
```bash
C:/Users/aniru/Videos/NEW/flutter/bin/flutter.bat pub run build_runner build --delete-conflicting-outputs
```
