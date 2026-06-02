import '../theme/app_animations.dart';

class AnimationUtils {
  /// Calculates a staggered delay duration based on the index.
  static Duration calculateStaggerDelay(int index) {
    return AppAnimations.staggerOffset * index;
  }

  /// Calculates an animation value based on a given time and curve.
  /// (Useful for pure logic if needed outside widgets)
  static double applyCurve(double t) {
    return AppAnimations.defaultCurve.transform(t);
  }
}
