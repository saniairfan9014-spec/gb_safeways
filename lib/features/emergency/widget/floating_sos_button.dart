import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/route_names.dart';
import '../../auth/controller/auth_controller.dart';

class FloatingSosButton extends StatefulWidget {
  const FloatingSosButton({super.key});

  @override
  State<FloatingSosButton> createState() => _FloatingSosButtonState();
}

class _FloatingSosButtonState extends State<FloatingSosButton> with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSos();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _triggerSos() {
    // Provide a heavy haptic vibration feedback on successful trigger
    HapticFeedback.heavyImpact();
    
    _holdController.reset();
    setState(() {
      _isHolding = false;
    });

    final authController = context.read<AuthController>();
    if (!authController.isAuthenticated) {
      NotificationService.instance.showErrorSnackbar("Please log in to broadcast Emergency SOS signals.");
      Navigator.pushNamed(context, RouteNames.login);
      return;
    }

    // Open Emergency Details screen
    Navigator.pushNamed(context, RouteNames.sosDetails);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, child) {
        final progress = _holdController.value;
        final scale = 1.0 + (progress * 0.15); // Grow slightly when holding

        return Positioned(
          bottom: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isHolding)
                Container(
                  margin: const EdgeInsets.only(bottom: 8, right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.statusDanger, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Hold: ${(3 - (progress * 3)).toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTapDown: (_) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isHolding = true;
                  });
                  _holdController.forward();
                },
                onTapUp: (_) {
                  if (_holdController.status != AnimationStatus.completed) {
                    _holdController.reverse();
                  }
                  setState(() {
                    _isHolding = false;
                  });
                },
                onTapCancel: () {
                  if (_holdController.status != AnimationStatus.completed) {
                    _holdController.reverse();
                  }
                  setState(() {
                    _isHolding = false;
                  });
                },
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusDanger.withOpacity(_isHolding ? 0.5 : 0.3),
                          blurRadius: _isHolding ? 20 : 12,
                          spreadRadius: _isHolding ? 6 : 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring background track
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 4,
                            ),
                          ),
                        ),
                        // Animated progress ring overlay
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: progress,
                              color: AppColors.statusDanger,
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                        // Inner button
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.statusDanger, Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(height: 2),
                              Text(
                                "SOS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at 12 o'clock
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
