import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;

  bool _isWaiting = false;
  bool _isConnected = false;
  String _statusMessage = 'Press the magic button to connect with your love';

  @override
  void initState() {
    super.initState();

    // Pulse animation for the magic button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Rotation animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _onMagicButtonPressed() async {
    if (_isWaiting || _isConnected) return;

    setState(() {
      _isWaiting = true;
      _statusMessage = 'Waiting for your partner to press their button...';
    });

    try {
      // Ensure user is authenticated (should already be, but just in case)
      await AuthService.ensureAuthenticated();

      // Get the user's actual Firestore document ID (may differ from auth UID)
      final userDocId = await UserService.getUserDocId();
      if (userDocId == null) {
        throw 'User document ID not found. Please restart the app and select your role.';
      }

      // Create connection request
      await FirestoreService.createConnectionRequest(userDocId);

      // Try to find and connect with a waiting partner
      final partner = await FirestoreService.findAndConnectPartner(userDocId);

      if (partner != null) {
        // Connection successful!
        setState(() {
          _isConnected = true;
          _statusMessage = '💕 Connected! Your love story begins now...';
        });

        // Wait a moment to show success, then go back
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Still waiting - listen for partner
        _listenForPartner(userDocId);
      }
    } catch (e) {
      setState(() {
        _isWaiting = false;
        _statusMessage = 'Press the magic button to connect with your love';
      });
      _showError('Connection failed: $e');
    }
  }

  void _listenForPartner(String userId) {
    FirestoreService.watchConnectionRequest(userId).listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>?;
        final status = data?['status'] as String?;

        if (status == 'connected') {
          setState(() {
            _isConnected = true;
            _statusMessage = '💕 Connected! Your love story begins now...';
          });

          // Wait a moment to show success, then go back
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cancelConnection() async {
    try {
      final userDocId = await UserService.getUserDocId();
      if (userDocId != null) {
        await FirestoreService.cancelConnectionRequest(userDocId);
      }
      setState(() {
        _isWaiting = false;
        _statusMessage = 'Press the magic button to connect with your love';
      });
    } catch (e) {
      debugPrint('Error canceling connection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.purpleGradient,
        ),
        child: Stack(
          children: [
            // Animated particles background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MagicParticlesPainter(_particleController.value),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          if (_isWaiting) {
                            await _cancelConnection();
                          }
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    'Connect With Love',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Magic button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isWaiting ? _scaleAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: _onMagicButtonPressed,
                          child: AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _isWaiting
                                    ? _rotateController.value * 2 * pi
                                    : 0,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isConnected
                                          ? [
                                              Colors.green.shade300,
                                              Colors.green.shade500,
                                            ]
                                          : _isWaiting
                                              ? [
                                                  AppConstants.accentRose,
                                                  AppConstants.heartRed,
                                                ]
                                              : [
                                                  Colors.white,
                                                  AppConstants.primaryPink,
                                                ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isWaiting
                                            ? AppConstants.heartRed
                                                .withOpacity(0.6)
                                            : Colors.white.withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isConnected
                                          ? Icons.check
                                          : _isWaiting
                                              ? Icons.favorite
                                              : Icons.touch_app,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Status message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isWaiting && !_isConnected) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () async {
                        await _cancelConnection();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Instructions
                  Container(
                    margin: const EdgeInsets.all(AppConstants.largePadding),
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: const Text(
                      'Both of you need to press the magic button at the same time (or one after another) to create your connection! ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MagicParticlesPainter extends CustomPainter {
  final double animationValue;
  final Random random = Random(123);

  MagicParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create floating hearts and stars
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + (animationValue * 150 + i * 10)) % size.height;
      final opacity = (sin(animationValue * 2 * pi + i) + 1) / 2;

      paint.color = Colors.white.withOpacity(opacity * 0.4);

      if (i % 2 == 0) {
        // Draw heart
        _drawHeart(canvas, paint, Offset(x, y), 8);
      } else {
        // Draw star
        _drawStar(canvas, paint, Offset(x, y), 10);
      }
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size / 4);
    path.cubicTo(
      center.dx - size / 2,
      center.dy - size / 4,
      center.dx - size,
      center.dy + size / 4,
      center.dx,
      center.dy + size,
    );
    path.cubicTo(
      center.dx + size,
      center.dy + size / 4,
      center.dx + size / 2,
      center.dy - size / 4,
      center.dx,
      center.dy + size / 4,
    );
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
