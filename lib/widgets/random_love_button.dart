import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RandomLoveButton extends StatefulWidget {
  final String message;
  final VoidCallback onPressed;

  const RandomLoveButton({
    super.key,
    required this.message,
    required this.onPressed,
  });

  @override
  State<RandomLoveButton> createState() => _RandomLoveButtonState();
}

class _RandomLoveButtonState extends State<RandomLoveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500 + _random.nextInt(1000)),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start entrance animation
    _animationController.forward();

    // Set up continuous pulse animation
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(Duration(milliseconds: 500 + _random.nextInt(2000)), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onButtonPressed() {
    // Trigger press animation
    _animationController.stop();
    _animationController.animateTo(0.8).then((_) {
      _animationController.forward();
    });

    widget.onPressed();
  }

  Color _getRandomButtonColor() {
    final colors = [
      AppConstants.primaryPink,
      AppConstants.secondaryPurple,
      AppConstants.accentRose,
      const Color(0xFFFFB6C1), // Light Pink
      const Color(0xFFF8BBD9), // Soft Pink
      const Color(0xFFE6E6FA), // Lavender
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: GestureDetector(
            onTap: _onButtonPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _getRandomButtonColor(),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
