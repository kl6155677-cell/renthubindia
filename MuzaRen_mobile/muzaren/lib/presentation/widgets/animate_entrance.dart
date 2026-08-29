import 'package:flutter/material.dart';

class AnimateEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Offset offset;
  final Duration duration;
  final double delay;

  const AnimateEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 30),
    this.duration = const Duration(milliseconds: 600),
    this.delay = 0.05,
  });

  @override
  State<AnimateEntrance> createState() => _AnimateEntranceState();
}

class _AnimateEntranceState extends State<AnimateEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
      ),
    );

    _offsetAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: (widget.index * (widget.delay * 1000)).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _offsetAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
