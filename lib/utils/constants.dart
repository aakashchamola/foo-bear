import 'package:flutter/material.dart';

class AppConstants {
  // App Configuration
  static const String appName = 'UsTime';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String messagesCollection = 'messages';
  static const String photosCollection = 'photos';
  static const String diaryCollection = 'diary';
  static const String notificationsCollection = 'notifications';

  // Colors - Romantic Theme
  static const Color primaryPink = Color(0xFFFFB6C1); // Light Pink
  static const Color secondaryPurple = Color(0xFFDDA0DD); // Plum
  static const Color accentRose = Color(0xFFFF69B4); // Hot Pink
  static const Color backgroundCream = Color(0xFFFFFAF0); // Floral White
  static const Color textDark = Color(0xFF4A4A4A);
  static const Color heartRed = Color(0xFFFF1744);
  static const Color shadowColor = Color(0x1A000000);

  // Gradient Colors
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE4E6),
      Color(0xFFFFB6C1),
      Color(0xFFFFC0CB),
    ],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE6E6FA),
      Color(0xFFDDA0DD),
      Color(0xFFDA70D6),
    ],
  );

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 600);
  static const Duration longAnimation = Duration(milliseconds: 1000);
  static const Duration heartAnimation = Duration(milliseconds: 1500);

  // Sizes
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double borderRadius = 16.0;
  static const double heartSize = 24.0;
  static const double buttonSize = 80.0;

  // Love Button Messages
  static const List<String> loveMessages = [
    'I Miss You 💕',
    'Thinking of You 💭',
    'Love You ❤️',
    'Missing Your Smile 😊',
    'Wish You Were Here 🥰',
    'You Make Me Happy 💖',
    'Sweet Dreams 🌙',
    'Good Morning Beautiful ☀️',
    'Sending Hugs 🤗',
    'You\'re My Everything 💝',
  ];

  // Notification Messages
  static const Map<String, String> notificationMessages = {
    'I Miss You 💕': 'is missing you right now 💕',
    'Thinking of You 💭': 'is thinking of you 💭',
    'Love You ❤️': 'just sent you love ❤️',
    'Missing Your Smile 😊': 'misses your beautiful smile 😊',
    'Wish You Were Here 🥰': 'wishes you were there 🥰',
    'You Make Me Happy 💖': 'wants you to know you make them happy 💖',
    'Sweet Dreams 🌙': 'wishes you sweet dreams 🌙',
    'Good Morning Beautiful ☀️': 'says good morning beautiful ☀️',
    'Sending Hugs 🤗': 'is sending you virtual hugs 🤗',
    'You\'re My Everything 💝': 'wants you to know you\'re their everything 💝',
  };

  // Heart Emojis for animations
  static const List<String> heartEmojis = [
    '💕',
    '💖',
    '💗',
    '💘',
    '💝',
    '💞',
    '💟',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🤍',
    '🖤',
    '❣️',
    '💋'
  ];

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String partnerIdKey = 'partner_id';
  static const String isAuthenticatedKey = 'is_authenticated';
  static const String secretPasscodeKey = 'secret_passcode';
  static const String themeKey = 'current_theme';
  static const String soundEnabledKey = 'sound_enabled';

  // File Paths
  static const String profileImagePath = 'profile_images/';
  static const String galleryImagePath = 'gallery_images/';
  static const String secretGalleryPath = 'secret_gallery/';

  // Encryption
  static const String encryptionKey = 'romantic_app_secret_key_2024';
}

class AppThemes {
  static ThemeData get romanticTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryPink,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppConstants.textDark,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryPink,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppConstants.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.9),
        elevation: 8,
        shadowColor: AppConstants.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
