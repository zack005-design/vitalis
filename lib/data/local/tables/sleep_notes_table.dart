import 'package:drift/drift.dart';

/// Drift SQLite Table definition for sleep session logs.
class SleepNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Date of the sleep session (night started)
  DateTimeColumn get date => dateTime()();
  /// Bedtime (when user went to sleep)
  DateTimeColumn get bedtime => dateTime().nullable()();
  /// Wake time
  DateTimeColumn get wakeTime => dateTime().nullable()();
  /// Total sleep duration in minutes
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  /// Quality rating 1-5 stars
  IntColumn get ratingStars => integer().withDefault(const Constant(4))();
  /// Optional free-text note
  TextColumn get noteText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}
