import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared_preferences_provider.dart';

class UserProfile {
  final String name;
  final int age;
  final double height;
  final double weight;
  final String activityLevel;
  final String sex;
  final bool useAiNarration;
  final bool enableReminders;

  UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.sex,
    required this.useAiNarration,
    required this.enableReminders,
  });
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final SharedPreferences prefs;

  UserProfileNotifier(this.prefs) : super(_loadFromPrefs(prefs));

  static UserProfile _loadFromPrefs(SharedPreferences prefs) {
    return UserProfile(
      name: prefs.getString('profile_name') ?? "Alex Johnson",
      age: prefs.getInt('profile_age') ?? 28,
      height: prefs.getDouble('profile_height') ?? 175.0,
      weight: prefs.getDouble('profile_weight') ?? 72.0,
      activityLevel: prefs.getString('profile_activity') ?? "Moderate",
      sex: prefs.getString('profile_sex') ?? prefs.getString('profile_gender') ?? "Male",
      useAiNarration: prefs.getBool('pref_ai_narration') ?? true,
      enableReminders: prefs.getBool('pref_reminders') ?? true,
    );
  }

  void reload() {
    state = _loadFromPrefs(prefs);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserProfileNotifier(prefs);
});
