import 'package:drift/drift.dart';

/// Drift SQLite Table definition for subjective sleep notes.
class SleepNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get ratingStars => integer().withDefault(const Constant(4))();
  TextColumn get noteText => text()();
  DateTimeColumn get createdAt => dateTime()();
}
