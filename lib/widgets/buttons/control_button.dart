import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final String? badgeText;

  const ControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.badgeText,
  }) : super(key: key);

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 레이블에서 숫자 추출 (예: "4x4"에서 4, "2 Players"에서 2)
  int _extractNumber() {
    if (widget.label.contains('x')) {
      // 그리드 크기 형식 (예: 4x4)
      return int.tryParse(widget.label.split('x').first) ?? 4;
    } else if (widget.label.contains('Player')) {
      // 플레이어 수 형식 (예: 2 Players)
      return int.tryParse(widget.label.split(' ').first) ?? 1;
    }
    return 0;
  }

  // 그리드 크기 또는 플레이어 수에 따라 다른 색상 반환
  Color _getBadgeColor() {
    int value = _extractNumber();

    if (widget.label.contains('x')) {
      // 그리드 크기에 따른 색상
      switch (value) {
        case 4:
          return Colors.lightBlueAccent;
        case 6:
          return Colors.amberAccent;
        default:
          return Colors.greenAccent;
      }
    } else {
      // 플레이어 수에 따른 색상
      switch (value) {
        case 1:
          return Colors.blueAccent;
        case 2:
          return Colors.orangeAccent;
        case 3:
          return Colors.purpleAccent;
        default:
          return Colors.redAccent;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGridSize = widget.label.contains('x');
    final bool isPlayerCount = widget.label.contains('Player');

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [Color(0xFFA14EBF), Color(0xFFE86339)]
                  : [Color(0xFF833AB4), Color(0xFFF77737)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Color(0xFF833AB4).withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 5,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
