# Task 4: Search & Database Optimization

**Goal:** Prevent API thrashing during search and slow database reads by optimizing queries and requests.

**Specific Requirements:**
1. **Search Debounce:** In lib/ui/food/food_search_sheet.dart, the user typing immediately triggers the local database and Open Food Facts HTTP calls. Implement a 300ms debounce on keystrokes so typing "Chicken" doesn't fire 7 parallel network requests. Use Timer or a package if already available.
2. **Open Food Facts User-Agent:** In lib/data/remote/open_food_facts_client.dart, add a mandatory User-Agent header to all HTTP requests (e.g., VitalityTracker/1.0 (contact@example.com) or similar) to prevent 403 blocks from the API. Also, ensure the http.Client is properly closed if it's being instantiated per request, or reuse a singleton client.
3. **Database Indices:** In the local database tables (lib/data/local/tables/), add indices on columns heavily used for querying. Specifically:
   - meals_table.dart: Index on 	imestamp.
   - water_logs_table.dart: Index on 	imestamp.
   - sleep_notes_table.dart: Index on date or edtime (whichever is heavily queried).
   - *Note:* In Drift, you can add an @TableIndex annotation or override the customConstraints / indices property depending on the Drift version used.

**Testing:**
- Run all tests.
- Add/update tests for the OpenFoodFactsClient to verify the User-Agent header if applicable.
