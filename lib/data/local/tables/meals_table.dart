import 'package:drift/drift.dart';

/// Drift SQLite Table definition for logged meals.
@TableIndex(name: 'meals_timestamp_idx', columns: {#timestamp})
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
