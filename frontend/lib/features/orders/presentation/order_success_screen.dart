import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;

  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _textFade;
  late Animation<double> _orderInfoFade;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(vsync: this, duration: successStampCircle);
    _checkController = AnimationController(vsync: this, duration: successStampCheck);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: easeOutCubic),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: easeOutCubic),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _orderInfoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );

    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _checkController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              
              // Animated Checkmark
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_circleController, _checkController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _CheckmarkPainter(
                          circleProgress: _circleAnimation.value,
                          checkProgress: _checkAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Animated Texts
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Column(
                    children: [
                      Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          'order confirmed.',
                          style: AppTypography.displayLG.copyWith(
                            color: AppColors.ink,
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Opacity(
                        opacity: _orderInfoFade.value,
                        child: Column(
                          children: [
                            Text(
                              '#${widget.orderId}',
                              style: AppTypography.monoMD.copyWith(color: AppColors.stone),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'estimated delivery — 5 to 7 business days',
                              style: AppTypography.bodySM.copyWith(color: AppColors.pebble),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(flex: 3),
              
              // Animated Buttons
              AnimatedBuilder(
                animation: _buttonsFade,
                builder: (context, child) {
                  return Opacity(
                    opacity: _buttonsFade.value,
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.ink),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tracking coming soon!')),
                              );
                            },
                            child: Text('TRACK ORDER →', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => context.go('/home'),
                          child: Text('continue shopping', style: AppTypography.bodyMD.copyWith(
                            color: AppColors.stone,
                            decoration: TextDecoration.underline,
                          )),
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
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;

  _CheckmarkPainter({required this.circleProgress, required this.checkProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = AppColors.signal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.5708, 6.2832 * circleProgress, false, circlePaint);

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = AppColors.signal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      
      final p1 = Offset(size.width * 0.25, size.height * 0.5);
      final p2 = Offset(size.width * 0.45, size.height * 0.7);
      final p3 = Offset(size.width * 0.75, size.height * 0.35);

      path.moveTo(p1.dx, p1.dy);

      if (checkProgress <= 0.5) {
        final t = checkProgress * 2;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = (checkProgress - 0.5) * 2;
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
           oldDelegate.checkProgress != checkProgress;
  }
}
