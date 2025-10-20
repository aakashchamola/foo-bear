import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // Remote Config Keys
  static const String _secretPasswordKey = 'secretPassShriya';

  // Default values
  static const Map<String, dynamic> _defaults = {
    _secretPasswordKey: 'kaku',
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
