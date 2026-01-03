import 'package:flutter/material.dart';
import 'dart:math' as math;

class SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onComplete;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onComplete,
  });

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation untuk dialog
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Check mark animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Mulai animasi
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.forward();
    });

    // Auto close setelah 2 detik
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Success Icon dengan confetti
              Stack(
                alignment: Alignment.center,
                children: [
                  // Confetti particles
                  ...List.generate(12, (index) {
                    return AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        final angle = (index * 30.0) * (math.pi / 180);
                        final distance = _confettiController.value * 60;
                        final x = math.cos(angle) * distance;
                        final y = math.sin(angle) * distance;
                        final opacity = 1.0 - _confettiController.value;

                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getConfettiColor(index),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Success circle background
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CheckMarkPainter(
                            progress: _checkAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Loading indicator
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfettiColor(int index) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.yellow,
    ];
    return colors[index % colors.length];
  }
}

// Custom painter untuk check mark
class CheckMarkPainter extends CustomPainter {
  final double progress;

  CheckMarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Check mark path
    final startX = size.width * 0.3;
    final startY = size.height * 0.5;
    final midX = size.width * 0.45;
    final midY = size.height * 0.65;
    final endX = size.width * 0.7;
    final endY = size.height * 0.35;

    if (progress < 0.5) {
      // First part of check mark
      final currentProgress = progress * 2;
      path.moveTo(startX, startY);
      path.lineTo(
        startX + (midX - startX) * currentProgress,
        startY + (midY - startY) * currentProgress,
      );
    } else {
      // Complete first part
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);

      // Second part of check mark
      final currentProgress = (progress - 0.5) * 2;
      path.lineTo(
        midX + (endX - midX) * currentProgress,
        midY + (endY - midY) * currentProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Alternative: Minimal success overlay
class SuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const SuccessOverlay({super.key, required this.onComplete});

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Login Berhasil!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selamat datang kembali',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
