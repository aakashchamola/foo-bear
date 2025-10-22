import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/floating_hearts.dart';
import '../widgets/random_love_button.dart';
import '../widgets/lock_button.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import 'enhanced_chat_screen.dart';
import 'gallery_screen.dart';
import 'diary_screen.dart';
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
  bool _isConnected = false;
  bool _isLoadingConnection = true;

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

    _checkConnectionStatus();
    _listenToConnectionChanges();
  }

  void _listenToConnectionChanges() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      // Listen to user profile changes to detect when partnerId is set
      FirestoreService.getUserProfile(currentUser.uid).then((userDoc) {
        if (userDoc.exists && mounted) {
          // Set up a real-time listener
          FirestoreService.getUserProfileStream(currentUser.uid)
              .listen((snapshot) {
            if (snapshot.exists && mounted) {
              final userData = snapshot.data() as Map<String, dynamic>?;
              final partnerId = userData?['partnerId'] as String?;
              final isConnected = partnerId != null && partnerId.isNotEmpty;

              if (isConnected != _isConnected) {
                setState(() {
                  _isConnected = isConnected;
                });

                // Regenerate buttons with new opacity
                _generateRandomButtons();

                // Show a celebration message when newly connected
                if (isConnected && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          '🎉 You are now connected! All features unlocked!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            }
          });
        }
      });
    }
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

  Future<void> _checkConnectionStatus() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      // Get the user's actual Firestore document ID
      final userDocId = await UserService.getUserDocId();
      if (userDocId != null) {
        final isConnected = await FirestoreService.isUserConnected(userDocId);
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
            _isLoadingConnection = false;
          });
        }
      } else {
        setState(() {
          _isLoadingConnection = false;
        });
      }
    } else {
      setState(() {
        _isLoadingConnection = false;
      });
    }
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
          child: Opacity(
            opacity: _isConnected ? 1.0 : 0.3,
            child: RandomLoveButton(
              message: message,
              onPressed: () => _isConnected
                  ? _onLoveButtonPressed(message)
                  : _showLockedFeatureMessage(),
            ),
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
        // Get the user's actual Firestore document ID
        final userDocId = await UserService.getUserDocId();
        if (userDocId != null) {
          // Get user profile to find partner
          final userDoc = await FirestoreService.getUserProfile(userDocId);
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            final partnerId = userData?['partnerId'] as String?;

            if (partnerId != null && partnerId.isNotEmpty) {
              // Send love notification to partner
              await FirestoreService.sendLoveNotification(
                senderId: userDocId,
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
          // Connection/Love button
          GestureDetector(
            onTap: () async {
              if (_isConnected) {
                // Already connected - show who they're connected to or do nothing
                final currentUser = AuthService.currentUser;
                if (currentUser != null) {
                  final userDocId = await UserService.getUserDocId();
                  if (userDocId != null) {
                    final userDoc =
                        await FirestoreService.getUserProfile(userDocId);
                    if (userDoc.exists) {
                      final userData = userDoc.data() as Map<String, dynamic>?;
                      final partnerId = userData?['partnerId'] as String?;

                      if (partnerId != null && mounted) {
                        final partnerDoc =
                            await FirestoreService.getUserProfile(partnerId);
                        final partnerData =
                            partnerDoc.data() as Map<String, dynamic>?;
                        final partnerName = partnerData?['name'] ??
                            partnerData?['nickname'] ??
                            'your love';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('💕 Connected with $partnerName'),
                            backgroundColor: AppConstants.heartRed,
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
              } else {
                // Not connected - navigate to connection screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ConnectionScreen(),
                  ),
                );

                // Refresh connection status when returning
                if (result == true) {
                  _checkConnectionStatus();
                }
              }
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
              child: _isLoadingConnection
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryPink),
                      ),
                    )
                  : Icon(
                      _isConnected ? Icons.favorite : Icons.link,
                      color: _isConnected
                          ? AppConstants.heartRed
                          : AppConstants.primaryPink,
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
          _buildNavButton(Icons.chat, 'Chat', _isConnected, () async {
            if (_isConnected) {
              final userDocId = await UserService.getUserDocId();
              if (userDocId != null) {
                final userDoc =
                    await FirestoreService.getUserProfile(userDocId);
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  final partnerId = userData?['partnerId'] as String?;
                  if (partnerId != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EnhancedChatScreen(partnerId: partnerId),
                      ),
                    );
                  }
                }
              }
            } else {
              _showLockedFeatureMessage();
            }
          }),
          _buildNavButton(Icons.photo_library, 'Gallery', _isConnected,
              () async {
            if (_isConnected) {
              final userDocId = await UserService.getUserDocId();
              if (userDocId != null) {
                final userDoc =
                    await FirestoreService.getUserProfile(userDocId);
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  final partnerId = userData?['partnerId'] as String?;
                  if (partnerId != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            GalleryScreen(partnerId: partnerId),
                      ),
                    );
                  }
                }
              }
            } else {
              _showLockedFeatureMessage();
            }
          }),
          _buildNavButton(Icons.lock, 'Secret', _isConnected, () {
            if (!_isConnected) {
              _showLockedFeatureMessage();
            }
          }),
          _buildNavButton(Icons.book, 'Diary', _isConnected, () async {
            if (_isConnected) {
              final userDocId = await UserService.getUserDocId();
              if (userDocId != null) {
                final userDoc =
                    await FirestoreService.getUserProfile(userDocId);
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  final partnerId = userData?['partnerId'] as String?;
                  if (partnerId != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DiaryScreen(partnerId: partnerId),
                      ),
                    );
                  }
                }
              }
            } else {
              _showLockedFeatureMessage();
            }
          }),
        ],
      ),
    );
  }

  void _showLockedFeatureMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            '🔒 Connect with your partner first to unlock this feature!'),
        backgroundColor: AppConstants.accentRose,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Connect',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConnectionScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavButton(
      IconData icon, String label, bool isUnlocked, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
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
              if (!isUnlocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.lock,
                    size: 14,
                    color: AppConstants.textDark.withOpacity(0.6),
                  ),
                ),
            ],
          ),
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
