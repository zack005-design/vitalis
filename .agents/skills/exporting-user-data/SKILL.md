---
name: exporting-user-data
description: Handles local data backup, JSON serialization/deserialization, database restore, and OS Share Sheet integration for data privacy in Flutter. Use when implementing data export/import, database backup, or data privacy features.
---

# Exporting User Data in Flutter

## When to use this skill
- Dumping local SQLite tables (`meals`, `water_logs`, `sleep_notes`, `user_profile`, `user_targets`) to a JSON backup file.
- Restoring local database records from a previously exported JSON backup file.
- Sharing backup files via the OS Share Sheet (`path_provider` + `share_plus` / system intent).

## Workflow Checklist
- [ ] Query all active local database DAOs for full historical dumps.
- [ ] Encode database model instances to a standardized JSON map with schema version metadata.
- [ ] Save JSON string to app document directory (`path_provider`).
- [ ] Invoke OS Share Sheet to allow user to save to local downloads, Google Drive, or transfer devices.
- [ ] Validate JSON schema version during import before wiping/overwriting existing tables.

## Code Pattern: JSON Backup Service

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JsonBackupService {
  Future<File> generateBackupJson({
    required List<Map<String, dynamic>> meals,
    required List<Map<String, dynamic>> waterLogs,
    required Map<String, dynamic>? profile,
  }) async {
    final payload = {
      "version": 1,
      "exported_at": DateTime.now().toIso8601String(),
      "data": {
        "meals": meals,
        "water_logs": waterLogs,
        "profile": profile,
      }
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/caltrack_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    return await file.writeAsString(jsonEncode(payload));
  }
}
```
