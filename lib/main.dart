import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:her/firebase_options.dart';
import 'utils/constants.dart';
import 'services/remote_config_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/camouflage/fake_todo_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Remote Config
    await RemoteConfigService().initialize();

    // Auto-authenticate user anonymously
    // Note: Anonymous Authentication must be enabled in Firebase Console
    await AuthService.ensureAuthenticated();
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
    // Continue anyway - we'll handle it in the app
  }

  runApp(const UsTimeApp());
}

class UsTimeApp extends StatelessWidget {
  const UsTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: const AppWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Ensure user is authenticated (with retry)
      User? user;
      try {
        user = await AuthService.ensureAuthenticated();
      } catch (authError) {
        debugPrint('❌ Auth error: $authError');
        // Show error to user
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showAuthErrorDialog();
            }
          });
        }
        // Still set loading to false to show the error screen
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Try to find user profile by auth UID (handles manual documents)
      final userDoc = await FirestoreService.getUserProfileByAuthUid(user.uid);

      if (userDoc == null || !userDoc.exists) {
        // No profile found - user will select role in welcome screen
        debugPrint('No user profile found, will create on role selection');
      } else {
        debugPrint('Found existing user profile: ${userDoc.id}');
      }

      // Short delay for splash effect
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppConstants.heartRed),
            SizedBox(width: 8),
            Text('Setup Required'),
          ],
        ),
        content: const Text(
          'Firebase Anonymous Authentication is not enabled.\n\n'
          'Please enable it in Firebase Console:\n'
          '1. Go to Firebase Console\n'
          '2. Select your project\n'
          '3. Go to Authentication > Sign-in method\n'
          '4. Enable "Anonymous" provider\n'
          '5. Restart the app',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE4E6),
                Color(0xFFFFB6C1),
                Color(0xFFFFC0CB),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '💖',
                  style: TextStyle(fontSize: 60),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Always show fake todo screen first - it's the camouflage!
    // The fake todo screen will unlock to WelcomeScreen when correct password is entered
    return const FakeTodoScreen();
  }
}
