import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:her/firebase_options.dart';
import 'utils/constants.dart';
import 'services/remote_config_service.dart';
import 'screens/camouflage/fake_todo_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Remote Config
  await RemoteConfigService().initialize();

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
    // Short delay for splash effect
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
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
