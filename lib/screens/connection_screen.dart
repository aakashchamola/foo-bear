import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/lock_button.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _textController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textOpacityAnimation;

  bool _isPressed = false;
  String? _partnerName;
  String? _partnerId;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale animation for press and hold
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      final userDoc = await FirestoreService.getUserProfile(currentUser.uid);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final partnerId = userData?['partnerId'] as String?;

        if (partnerId != null && partnerId.isNotEmpty) {
          // Get partner's profile
          final partnerDoc = await FirestoreService.getUserProfile(partnerId);
          if (partnerDoc.exists) {
            final partnerData = partnerDoc.data() as Map<String, dynamic>?;
            setState(() {
              _partnerId = partnerId;
              _partnerName =
                  partnerData?['displayName'] as String? ?? 'My Love';
              _isConnected = true;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onButtonPressStart() {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    _textController.forward();
  }

  void _onButtonPressEnd() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    _textController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppConstants.pinkGradient,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: _isConnected
                              ? _buildConnectionButton()
                              : _buildConnectPrompt(),
                        ),
                        const LockButton(),
                      ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Connection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instruction text
        const Text(
          'Press & Hold',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),

        // Big round button
        GestureDetector(
          onTapDown: (_) => _onButtonPressStart(),
          onTapUp: (_) => _onButtonPressEnd(),
          onTapCancel: _onButtonPressEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale:
                    _isPressed ? _scaleAnimation.value : _pulseAnimation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isPressed
                          ? [
                              AppConstants.heartRed,
                              AppConstants.accentRose,
                            ]
                          : [
                              AppConstants.primaryPink,
                              AppConstants.secondaryPurple,
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.heartRed.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isPressed
                        ? FadeTransition(
                            opacity: _textOpacityAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _partnerName ?? 'My Love',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '💕',
                                  style: TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: _partnerId != null
                                      ? FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_partnerId)
                                          .snapshots()
                                      : null,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final data = snapshot.data?.data()
                                          as Map<String, dynamic>?;
                                      final isOnline =
                                          data?['isOnline'] as bool? ?? false;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isOnline
                                                  ? Colors.greenAccent
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isOnline ? 'Online' : 'Offline',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          )
                        : const Icon(
                            Icons.favorite,
                            size: 80,
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 40),

        // Status text
        if (!_isPressed)
          const Text(
            'to see your connection',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildConnectPrompt() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.link_off,
                  size: 80,
                  color: AppConstants.primaryPink,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Not Connected Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connect with your partner to see the magic happen!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _showConnectPartnerDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Connect Partner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectPartnerDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Connect with Partner 💕'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your partner\'s email to connect:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Partner Email',
                hintText: 'love@example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                try {
                  final currentUser = AuthService.currentUser;
                  if (currentUser != null) {
                    await FirestoreService.connectPartner(
                      currentUser.uid,
                      emailController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      await _loadPartnerInfo(); // Reload partner info
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connected with partner! 💖'),
                          backgroundColor: AppConstants.primaryPink,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppConstants.heartRed,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryPink,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
