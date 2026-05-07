import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RosaryState {
  static const _key = 'rosary_saved_state';

  /// Save current rosary progress
  static Future<void> save({
    required String mysteryType,
    required bool includeLuminous,
    required bool isForDead,
    required String language,
    required int currentStep,
    required List<String> mysteryTypes,
    String? deceasedName,
    String deceasedPronoun = 'them',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'mysteryType': mysteryType,
      'includeLuminous': includeLuminous,
      'isForDead': isForDead,
      'language': language,
      'currentStep': currentStep,
      'mysteryTypes': mysteryTypes,
      'deceasedName': deceasedName,
      'deceasedPronoun': deceasedPronoun,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Load saved rosary progress, returns null if none
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear saved rosary progress
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Check if there's a saved rosary in progress
  static Future<bool> hasSavedState() async {
    final data = await load();
    if (data == null) return false;
    // Auto-expire after 24 hours
    final savedAt = data['savedAt'] as int? ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - savedAt;
    if (age > const Duration(hours: 24).inMilliseconds) {
      await clear();
      return false;
    }
    return true;
  }
}