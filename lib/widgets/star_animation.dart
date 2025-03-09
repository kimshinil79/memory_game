import 'dart:math';
import 'package:flutter/material.dart';

class StarAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const StarAnimation({Key? key, required this.child, required this.trigger}) : super(key: key);

  @override
  _StarAnimationState createState() => _StarAnimationState();
}

class _StarAnimationState extends State<StarAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Star> stars = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..addListener(() {
      setState(() {});
    });

    // 별들을 카드 크기에 맞춰 생성
    for (int i = 0; i < 10; i++) {
      stars.add(Star(Random().nextDouble(), Random().nextDouble()));
    }
  }

  @override
  void didUpdateWidget(StarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.trigger)
          ...stars.map((star) => Positioned.fill(
            child: Align(
              alignment: Alignment(star.x * 2 - 1, star.y * 2 - 1),
              child: FadeTransition(
                opacity: Tween(begin: 1.0, end: 0.0).animate(_controller),
                child: const Icon(Icons.star, color: Colors.yellow, size: 20),
              ),
            ),
          )).toList(),
      ],
    );
  }
}

class Star {
  final double x;
  final double y;

  Star(this.x, this.y);
}