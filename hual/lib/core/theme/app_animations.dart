import 'package:flutter/material.dart';

class AppAnimations {
  // Durations
  static const Duration microFeedback = Duration(milliseconds: 150);
  static const Duration stateChange = Duration(milliseconds: 200);
  static const Duration reveal = Duration(milliseconds: 300);
  static const Duration transition = Duration(milliseconds: 360);
  static const Duration hero = Duration(milliseconds: 400);
  static const Duration staggerOffset = Duration(milliseconds: 55);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
}
