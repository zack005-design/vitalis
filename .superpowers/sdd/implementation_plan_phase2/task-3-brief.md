# Task 3: Data Safety & Resilience

**Goal:** Harden local database operations and Health Connect integrations with robust error handling.

**Specific Requirements:**
1. **Drift Schema Migrations:** In lib/data/local/app_database.dart, the onUpgrade migrations are fragile because they use a series of if (from < N) statements that might crash if they attempt to add a column that already exists on a corrupted db. Modify the migrations to use table-existence checks or wrap the ddColumn operations in try-catch so they don't break the entire upgrade path if they fail. Also, move SQLite initialization to use NativeDatabase.createInBackground(file) instead of NativeDatabase(file) to offload disk I/O from the UI thread.
2. **Health Connect Client:** In lib/data/health/health_connect_client.dart, remove the silent swallows (catch (_) { return false; }). Instead, log the actual exception (using debugPrint or a logging framework) and expose a structured failure or rethrow it so the caller can handle it or show a UI notification.
3. **Pervasive Missing try-catch on SQLite Writes:**
   - Go through the UI screens that write to the database (e.g. 	oday_screen.dart for _quickAddWater and _deleteMeal, dd_custom_food_sheet.dart for custom food saves, log_sleep_sheet.dart, ood_screen.dart).
   - Wrap the db.insert... or db.delete... calls in 	ry-catch blocks.
   - If an exception is caught, display a ScaffoldMessenger SnackBar with an error message so the user knows the save/delete failed.
   - Also fix dd_custom_food_sheet.dart where _isSaving might be permanently stuck on true if an exception is thrown before inally block (or if inally is missing).

**Testing:**
- Verify tests pass.
- Write a quick unit test to verify that the Health Connect Client exposes errors instead of swallowing them.
