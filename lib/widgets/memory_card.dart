import 'package:flutter/material.dart';

class MemoryCard extends StatefulWidget {
  final int index;
  final String imageId;
  final bool isFlipped;
  final bool showMatchEffect;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.index,
    required this.imageId,
    required this.isFlipped,
    required this.showMatchEffect,
    required this.onTap,
  });

  @override
  _MemoryCardState createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _scaleController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_glowController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_scaleController);

    // 색상 애니메이션 - 여러 색상을 순차적으로 전환
    _borderColorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.redAccent,
          end: Colors.orangeAccent,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.orangeAccent,
          end: Colors.yellowAccent,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.yellowAccent,
          end: Colors.greenAccent,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.greenAccent,
          end: Colors.blueAccent,
        ),
        weight: 25,
      ),
    ]).animate(_glowController);

    // 매치 효과가 시작될 때 애니메이션 시작
    if (widget.showMatchEffect) {
      _startMatchAnimation();
    }
  }

  void _startMatchAnimation() {
    _glowController.forward();
    _scaleController.forward();

    // 애니메이션 완료 후 리셋
    Future.delayed(const Duration(milliseconds: 1200), () {
      _glowController.reset();
      _scaleController.reset();
    });
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 매치 효과 상태가 변경될 때 애니메이션 시작
    if (widget.showMatchEffect && !oldWidget.showMatchEffect) {
      _startMatchAnimation();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _scaleController]),
        builder: (context, child) {
          final glowOpacity = _glowAnimation.value;
          final scale = _scaleAnimation.value;
          final borderColor = _borderColorAnimation.value ?? Colors.redAccent;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.showMatchEffect
                    ? [
                        BoxShadow(
                          color: borderColor.withOpacity(glowOpacity * 0.8),
                          blurRadius: 20.0 + (glowOpacity * 10.0),
                          spreadRadius: 2.0 + (glowOpacity * 3.0),
                        ),
                        BoxShadow(
                          color: borderColor.withOpacity(glowOpacity * 0.4),
                          blurRadius: 40.0 + (glowOpacity * 20.0),
                          spreadRadius: 5.0 + (glowOpacity * 5.0),
                        ),
                      ]
                    : null,
              ),
              child: Card(
                elevation:
                    widget.showMatchEffect ? 8.0 + (glowOpacity * 4.0) : 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: widget.showMatchEffect
                      ? BorderSide(
                          color: borderColor,
                          width: 3.0 + (glowOpacity * 3.0),
                        )
                      : BorderSide.none,
                ),
                key: ValueKey(widget.index),
                color: Colors.white,
                child: Container(
                  decoration: widget.showMatchEffect
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              borderColor.withOpacity(glowOpacity * 0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        )
                      : null,
                  child: Center(
                    child: widget.isFlipped
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/pictureDB_webp/${widget.imageId}.webp',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Image.asset(
                            'assets/icon/memoryGame.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
