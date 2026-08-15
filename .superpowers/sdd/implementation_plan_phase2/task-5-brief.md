# Task 5: Insights & AI Analytics

**Goal:** Fix broken UI charts (overflow at 30d/90d) and correct the unfair AI balance scoring formula so it is time-of-day aware.

**Specific Requirements:**
1. **Charts Unusable at 30d/90d:** In lib/ui/insights/insights_screen.dart, the charts try to squeeze 90 bars into a fixed width container (~350dp), causing the bars and X-axis labels to smash together or overflow the screen. 
   - Wrap the charts (or just the 30d/90d charts) in a SingleChildScrollView (horizontal) so the user can scroll back through time, OR dynamically resize the bars/labels so they fit. Horizontal scrolling is usually best for large datasets.
   - Also, fix the silent SizedBox.shrink() on errors. Display a small error icon or text instead of an empty box if chart data fails to load.
2. **Balance Scorer Time-of-Day Awareness:** In lib/domain/insights/tier_b_balance_scorer.dart, the formula penalizes the user for having low calories early in the day (e.g., logging 400kcal at 9 AM out of a 2000kcal target results in a low score).
   - Adjust the scorer so that it calculates an expected "progress" based on the current time of day (e.g., if it's noon, they should be roughly 50% through their target). Score based on how closely they match the expected progress, rather than the raw absolute target. Or simply scale the target by hour / 24.

**Testing:**
- Update 	ier_b_balance_scorer.dart tests to pass in mock times (or verify it handles time of day correctly).
- Verify widget tests pass.
