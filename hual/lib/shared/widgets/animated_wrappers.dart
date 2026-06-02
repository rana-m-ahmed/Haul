import 'package:flutter/material.dart';
import '../../core/theme/app_animations.dart';
import '../../core/utils/animation_utils.dart';

class StaggeredListWrapper extends StatefulWidget {
  final Widget child;
  final int index;

  const StaggeredListWrapper({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<StaggeredListWrapper> createState() => _StaggeredListWrapperState();
}

class _StaggeredListWrapperState extends State<StaggeredListWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.reveal,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.defaultCurve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.defaultCurve,
      ),
    );

    Future.delayed(AnimationUtils.calculateStaggerDelay(widget.index), () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
