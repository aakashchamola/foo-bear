import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/floating_hearts.dart';
import '../widgets/random_love_button.dart';
import '../widgets/lock_button.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';
import 'connection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey _profileKey = GlobalKey();
  late AnimationController _particleController;
  late AnimationController _backgroundController;
  final List<Widget> _loveButtons = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: AppConstants.heartAnimation,
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateRandomButtons();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _generateRandomButtons() {
    _loveButtons.clear();
    final screenSize = MediaQuery.of(context).size;

    for (int i = 0; i < 6; i++) {
      final message = AppConstants
          .loveMessages[_random.nextInt(AppConstants.loveMessages.length)];
      final position = Positioned(
        left: _random.nextDouble() * (screenSize.width - 120),
        top: 200 + _random.nextDouble() * (screenSize.height - 400),
        child: Transform.rotate(
          angle: (_random.nextDouble() - 0.5) * 0.4,
          child: RandomLoveButton(
            message: message,
            onPressed: () => _onLoveButtonPressed(message),
          ),
        ),
      );
      _loveButtons.add(position);
    }
  }

  void _onLoveButtonPressed(String message) async {
    // Trigger heart animation
    _particleController.forward().then((_) {
      _particleController.reset();
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Get user profile to find partner
        final userDoc = await FirestoreService.getUserProfile(currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final partnerId = userData?['partnerId'] as String?;

          if (partnerId != null && partnerId.isNotEmpty) {
            // Send love notification to partner
            await FirestoreService.sendLoveNotification(
              senderId: currentUser.uid,
              receiverId: partnerId,
              message: message,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💕 Sent "$message" to your love!'),
                  backgroundColor: AppConstants.heartRed,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Connect with your partner first! 💑'),
                  backgroundColor: AppConstants.accentRose,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppConstants.heartRed,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.pinkGradient,
        ),
        child: Stack(
          children: [
            // Animated background particles
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter:
                      BackgroundParticlesPainter(_backgroundController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Safe area content
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Stack(
                      children: [
                        // Random love buttons
                        ..._loveButtons,

                        // Floating hearts animation
                        FloatingHearts(
                          controller: _particleController,
                          targetKey: _profileKey,
                        ),

                        // Lock button
                        // const LockButton(),
                      ],
                    ),
                  ),
                  _buildBottomNavigation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Connection button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppConstants.shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: AppConstants.primaryPink,
                size: 28,
              ),
            ),
          ),
          // lock button
          const LockButton(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(Icons.chat, 'Chat', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          }),
          _buildNavButton(Icons.photo_library, 'Gallery', () {}),
          _buildNavButton(Icons.lock, 'Secret', () {}),
          _buildNavButton(Icons.book, 'Diary', () {}),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.smallPadding,
          horizontal: AppConstants.defaultPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: AppConstants.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppConstants.primaryPink, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundParticlesPainter extends CustomPainter {
  final double animationValue;
  final Random random = Random(42); // Fixed seed for consistent particles

  BackgroundParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Create floating particles
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = baseY + (animationValue * 100) % size.height;
      final radius = 2 + random.nextDouble() * 3;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
