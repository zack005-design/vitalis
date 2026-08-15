import 'package:drift/drift.dart';

/// Drift SQLite Table definition for persistent daily water intake logs.
@TableIndex(name: 'water_timestamp_idx', columns: {#timestamp})
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get amountMl => integer()();
}
