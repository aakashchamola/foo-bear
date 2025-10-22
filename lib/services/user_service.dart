import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class UserService {
  // Cache for quick access
  static String? _cachedRole;
  static String? _cachedDocId;

  // Get user's Firestore document ID (might be different from auth UID)
  static Future<String?> getUserDocId() async {
    if (_cachedDocId != null) {
      return _cachedDocId;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedDocId = prefs.getString('user_doc_id');
    return _cachedDocId;
  }

  // Set user document ID
  static Future<void> setUserDocId(String docId) async {
    _cachedDocId = docId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_doc_id', docId);
  }

  // Get user role from cache or SharedPreferences
  static Future<String?> getUserRole() async {
    if (_cachedRole != null) {
      return _cachedRole;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedRole = prefs.getString(AppConstants.userRoleKey);
    return _cachedRole;
  }

  // Check if user is male
  static Future<bool> isMale() async {
    final role = await getUserRole();
    return role == 'male';
  }

  // Check if user is female
  static Future<bool> isFemale() async {
    final role = await getUserRole();
    return role == 'female';
  }

  // Set user role (also updates cache)
  static Future<void> setUserRole(String role) async {
    _cachedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userRoleKey, role);
  }

  // Clear role (for logout/reset)
  static Future<void> clearRole() async {
    _cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userRoleKey);
  }

  // Get role emoji
  static Future<String> getRoleEmoji() async {
    final role = await getUserRole();
    return role == 'male' ? '👨' : '👩';
  }

  // Get role display name
  static Future<String> getRoleDisplayName() async {
    final role = await getUserRole();
    return role == 'male' ? 'Him' : 'Her';
  }

  // Get role color
  static Future<String> getRoleColorType() async {
    final role = await getUserRole();
    return role == 'male' ? 'blue' : 'pink';
  }
}
