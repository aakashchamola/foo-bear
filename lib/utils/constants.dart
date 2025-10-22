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
  static const String connectionsCollection = 'connections';

  // Colors - Dark Blue/Black Theme
  static const Color primaryDark = Color(0xFF0D1117); // Dark background
  static const Color secondaryDark = Color(0xFF1C2128); // Slightly lighter dark
  static const Color accentBlue = Color(0xFF58A6FF); // Bright blue accent
  static const Color accentTeal = Color(0xFF39C5CF); // Teal accent
  static const Color backgroundDark = Color(0xFF161B22); // Dark grey background
  static const Color textLight = Color(0xFFC9D1D9); // Light grey text
  static const Color textMuted = Color(0xFF8B949E); // Muted grey text
  static const Color heartRed = Color(0xFFFF6B9D); // Softer red/pink
  static const Color shadowColor = Color(0x40000000);
  static const Color cardDark = Color(0xFF21262D); // Card background

  // Message bubble colors
  static const Color sentMessageBg = Color(0xFF0969DA); // Blue for sent
  static const Color receivedMessageBg =
      Color(0xFF21262D); // Dark grey for received
  static const Color borderGrey = Color(0xFF30363D); // Border color

  // Gradient Colors
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D1117),
      Color(0xFF161B22),
      Color(0xFF1C2128),
    ],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0969DA),
      Color(0xFF1F6FEB),
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
  static const String userRoleKey = 'user_role'; // 'male' or 'female'

  // File Paths
  static const String profileImagePath = 'profile_images/';
  static const String galleryImagePath = 'gallery_images/';
  static const String secretGalleryPath = 'secret_gallery/';

  // Encryption
  static const String encryptionKey = 'romantic_app_secret_key_2024';
}

class AppThemes {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.accentBlue,
        brightness: Brightness.dark,
        background: AppConstants.primaryDark,
        surface: AppConstants.secondaryDark,
      ),
      scaffoldBackgroundColor: AppConstants.primaryDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.secondaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppConstants.textLight,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.accentBlue,
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
        color: AppConstants.cardDark,
        elevation: 4,
        shadowColor: AppConstants.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
