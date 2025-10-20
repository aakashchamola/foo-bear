import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FloatingHearts extends StatefulWidget {
  final AnimationController controller;
  final GlobalKey targetKey;

  const FloatingHearts({
    super.key,
    required this.controller,
    required this.targetKey,
  });

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with TickerProviderStateMixin {
  final List<HeartParticle> hearts = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateHearts);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHearts);
    super.dispose();
  }

  void _updateHearts() {
    if (widget.controller.status == AnimationStatus.forward) {
      _generateHearts();
    }
    setState(() {});
  }

  void _generateHearts() {
    hearts.clear();
    final RenderBox? targetBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (targetBox != null) {
      final targetPosition = targetBox.localToGlobal(Offset.zero);
      final targetCenter = Offset(
        targetPosition.dx + targetBox.size.width / 2,
        targetPosition.dy + targetBox.size.height / 2,
      );

      // Create hearts from random positions
      for (int i = 0; i < 8; i++) {
        final startX = random.nextDouble() * MediaQuery.of(context).size.width;
        final startY = MediaQuery.of(context).size.height * 0.5 +
            random.nextDouble() * 200;

        hearts.add(HeartParticle(
          startPosition: Offset(startX, startY),
          endPosition: targetCenter,
          emoji: AppConstants
              .heartEmojis[random.nextInt(AppConstants.heartEmojis.length)],
          delay: random.nextDouble() * 0.5,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Stack(
          children: hearts.map((heart) => _buildHeart(heart)).toList(),
        );
      },
    );
  }

  Widget _buildHeart(HeartParticle heart) {
    final progress = (widget.controller.value - heart.delay).clamp(0.0, 1.0);

    if (progress <= 0) return const SizedBox.shrink();

    // Curved path animation
    final curveValue = Curves.easeInOut.transform(progress);
    final currentPosition = _calculateCurvedPosition(
      heart.startPosition,
      heart.endPosition,
      curveValue,
    );

    // Scale animation (start small, grow, then shrink)
    double scale;
    if (progress < 0.3) {
      scale = progress / 0.3;
    } else if (progress < 0.7) {
      scale = 1.0;
    } else {
      scale = 1.0 - ((progress - 0.7) / 0.3);
    }

    // Opacity animation
    final opacity = progress < 0.8 ? 1.0 : 1.0 - ((progress - 0.8) / 0.2);

    return Positioned(
      left: currentPosition.dx - 15,
      top: currentPosition.dy - 15,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            heart.emoji,
            style: const TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }

  Offset _calculateCurvedPosition(Offset start, Offset end, double t) {
    // Create a curved path using quadratic bezier curve
    final controlPoint = Offset(
      start.dx + (end.dx - start.dx) * 0.5 + random.nextDouble() * 100 - 50,
      start.dy - 100 - random.nextDouble() * 50,
    );

    final x = pow(1 - t, 2) * start.dx +
        2 * (1 - t) * t * controlPoint.dx +
        pow(t, 2) * end.dx;

    final y = pow(1 - t, 2) * start.dy +
        2 * (1 - t) * t * controlPoint.dy +
        pow(t, 2) * end.dy;

    return Offset(x.toDouble(), y.toDouble());
  }
}

class HeartParticle {
  final Offset startPosition;
  final Offset endPosition;
  final String emoji;
  final double delay;

  HeartParticle({
    required this.startPosition,
    required this.endPosition,
    required this.emoji,
    required this.delay,
  });
}
