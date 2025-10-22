import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // Remote Config Keys
  static const String _secretPasswordKey = 'secretPassShriya';
  static const String _maleUserDataKey = 'male_user_data';
  static const String _femaleUserDataKey = 'female_user_data';

  // Default values
  static final Map<String, dynamic> _defaults = {
    _secretPasswordKey: 'kaku',
    _maleUserDataKey: jsonEncode({
      'name': 'Him',
      'nickname': 'King',
      'email': 'him@ustime.app',
      'displayName': 'My King',
      'photoUrl': '',
      'gender': 'male',
    }),
    _femaleUserDataKey: jsonEncode({
      'name': 'Her',
      'nickname': 'Queen',
      'email': 'her@ustime.app',
      'displayName': 'My Queen',
      'photoUrl': '',
      'gender': 'female',
    }),
  };

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1), // Cache for 1 hour
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(_defaults);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      print('🔧 Remote Config initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Remote Config: $e');
      // Set defaults manually if fetch fails
      await _remoteConfig.setDefaults(_defaults);
      _initialized = true;
    }
  }

  /// Get the secret password
  String getSecretPassword() {
    try {
      return _remoteConfig.getString(_secretPasswordKey);
    } catch (e) {
      print('❌ Failed to get secret password: $e');
      return _defaults[_secretPasswordKey] as String;
    }
  }

  /// Get male user data from Remote Config
  Map<String, dynamic> getMaleUserData() {
    try {
      final jsonString = _remoteConfig.getString(_maleUserDataKey);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Failed to get male user data: $e - using defaults');
      return jsonDecode(_defaults[_maleUserDataKey] as String)
          as Map<String, dynamic>;
    }
  }

  /// Get female user data from Remote Config
  Map<String, dynamic> getFemaleUserData() {
    try {
      final jsonString = _remoteConfig.getString(_femaleUserDataKey);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Failed to get female user data: $e - using defaults');
      return jsonDecode(_defaults[_femaleUserDataKey] as String)
          as Map<String, dynamic>;
    }
  }

  /// Get user data by role ('male' or 'female')
  Map<String, dynamic> getUserDataByRole(String role) {
    return role == 'male' ? getMaleUserData() : getFemaleUserData();
  }

  /// Force fetch latest config (call when you want to refresh)
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('🔄 Remote Config refreshed');
    } catch (e) {
      print('❌ Failed to refresh Remote Config: $e');
    }
  }

  /// Check if password matches the secret
  bool verifyPassword(String input) {
    final secretPassword = getSecretPassword();
    return input.toLowerCase().trim() == secretPassword.toLowerCase().trim();
  }
}
