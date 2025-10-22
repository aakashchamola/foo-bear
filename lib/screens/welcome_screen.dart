import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _gradientController;

  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonSlideAnimation;
  late Animation<double> _gradientAnimation;

  final List<AnimatedHeart> _hearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _heartController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // Animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _buttonSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    // Generate floating hearts
    _generateHearts();

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _buttonController.forward();
    });
  }

  void _generateHearts() {
    for (int i = 0; i < 15; i++) {
      _hearts.add(AnimatedHeart(
        random: _random,
        controller: _heartController,
      ));
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Widget _buildRoleButton({
    required String role,
    required String emoji,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _selectRole(role),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(String role) async {
    try {
      // Get current authenticated user
      final user = await AuthService.ensureAuthenticated();

      // Find or create user document based on role (links to existing docs with 'gender' field)
      final userDocId =
          await FirestoreService.findOrCreateUserByRole(user.uid, role);

      // Save the actual document ID using UserService and SharedPreferences
      await UserService.setUserDocId(userDocId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userRoleKey, role);
      await prefs.setBool('welcome_completed', true);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            role == 'male' ? '💙 Welcome, King!' : '💖 Welcome, Queen!',
          ),
          backgroundColor:
              role == 'male' ? Colors.blue : AppConstants.accentRose,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate to home screen with animation
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (mounted) {
        // Check if it's a Firestore permission error
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('firestore') ||
            errorMessage.contains('permission') ||
            errorMessage.contains('not been used') ||
            errorMessage.contains('disabled')) {
          _showFirestoreErrorDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppConstants.heartRed,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _showFirestoreErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: AppConstants.heartRed),
            SizedBox(width: 8),
            Expanded(child: Text('Firestore Not Enabled')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cloud Firestore is not enabled in your Firebase project.\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Quick Fix:\n',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text(
                '1. Go to Firebase Console\n'
                '2. Select your project\n'
                '3. Click "Firestore Database"\n'
                '4. Click "Create database"\n'
                '5. Choose "Start in test mode"\n'
                '6. Select a location\n'
                '7. Click "Enable"\n'
                '8. Restart this app\n',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Or click the link in the error message above to enable Firestore directly.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK, I\'ll Enable It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    AppConstants.primaryPink,
                    AppConstants.secondaryPurple,
                    _gradientAnimation.value * 0.3,
                  )!,
                  Color.lerp(
                    AppConstants.accentRose,
                    AppConstants.primaryPink,
                    _gradientAnimation.value * 0.5,
                  )!,
                  Color.lerp(
                    AppConstants.backgroundCream,
                    AppConstants.accentRose,
                    _gradientAnimation.value * 0.2,
                  )!,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating Hearts Background
                  ..._hearts.map((heart) => heart.build(context)),

                  // Main Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Icon/Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppConstants.accentRose.withOpacity(0.8),
                                  AppConstants.secondaryPurple.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.secondaryPurple
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Welcome Text
                          AnimatedBuilder(
                            animation: _textFadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textFadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(
                                      0, 30 * (1 - _textFadeAnimation.value)),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Welcome to',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: AppConstants.textDark,
                                          fontWeight: FontWeight.w300,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Our Private World',
                                        style: const TextStyle(
                                          color: AppConstants.textDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 42,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: AppConstants.accentRose,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '💖',
                                            style:
                                                const TextStyle(fontSize: 28),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.favorite,
                                            color: AppConstants.accentRose,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 60),

                          // Role Selection Text
                          AnimatedBuilder(
                            animation: _buttonSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _buttonSlideAnimation.value),
                                child: const Text(
                                  'I am...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppConstants.textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Role Selection Buttons
                          AnimatedBuilder(
                            animation: _buttonSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _buttonSlideAnimation.value),
                                child: Row(
                                  children: [
                                    // Male Button
                                    Expanded(
                                      child: _buildRoleButton(
                                        role: 'male',
                                        emoji: '👨',
                                        label: 'Him',
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade300,
                                            Colors.blue.shade500,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Female Button
                                    Expanded(
                                      child: _buildRoleButton(
                                        role: 'female',
                                        emoji: '👩',
                                        label: 'Her',
                                        gradient: LinearGradient(
                                          colors: [
                                            AppConstants.primaryPink,
                                            AppConstants.accentRose,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedHeart {
  final Random random;
  final AnimationController controller;
  late final Animation<double> animation;
  late final double startX;
  late final double startY;
  late final double endX;
  late final double endY;
  late final double size;
  late final Color color;
  late final double rotationSpeed;

  AnimatedHeart({
    required this.random,
    required this.controller,
  }) {
    final delay = random.nextDouble() * 2.0;
    animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay / 3.0,
        (delay + 1.0) / 3.0,
        curve: Curves.easeInOut,
      ),
    ));

    startX = random.nextDouble();
    startY = 1.2;
    endX = startX + (random.nextDouble() - 0.5) * 0.3;
    endY = -0.2;
    size = 15 + random.nextDouble() * 25;
    rotationSpeed = (random.nextDouble() - 0.5) * 4;

    final colors = [
      AppConstants.accentRose,
      AppConstants.primaryPink,
      AppConstants.secondaryPurple,
      Colors.pink.shade200,
      Colors.red.shade200,
    ];
    color = colors[random.nextInt(colors.length)]
        .withOpacity(0.6 + random.nextDouble() * 0.4);
  }

  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final currentX = startX + (endX - startX) * animation.value;
        final currentY = startY + (endY - startY) * animation.value;

        return Positioned(
          left: currentX * screenWidth - size / 2,
          top: currentY * screenHeight,
          child: Transform.rotate(
            angle: animation.value * rotationSpeed,
            child: Opacity(
              opacity: (1 - animation.value) * 0.8,
              child: Icon(
                Icons.favorite,
                size: size,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
