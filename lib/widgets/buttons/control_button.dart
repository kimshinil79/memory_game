import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final String? badgeText;
  final bool useTranslation;

  const ControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.badgeText,
    this.useTranslation = false,
  }) : super(key: key);

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final label = widget.label;
    if (label.contains('x')) {
      // 그리드 크기 형식 (예: 4x4)
      return int.tryParse(label.split('x').first) ?? 4;
    } else if (label.contains('Player')) {
      // 플레이어 수 형식 (예: 2 Players)
      return int.tryParse(label.split(' ').first) ?? 1;
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

  // Button gradient colors based on type
  List<Color> _getGradientColors() {
    bool isGridSize = widget.label.contains('x');
    bool isPlayerCount = widget.label.contains('Player');

    if (isGridSize) {
      if (_isPressed) {
        return [Color(0xFF8844BB), Color(0xFFE86339)];
      } else {
        return [Color(0xFF833AB4), Color(0xFFF77737)];
      }
    } else if (isPlayerCount) {
      if (_isPressed) {
        return [Color(0xFF9945BF), Color(0xFFE86339)];
      } else {
        return [Color(0xFF833AB4), Color(0xFFFF8C39)];
      }
    } else {
      if (_isPressed) {
        return [Color(0xFFA14EBF), Color(0xFFE86339)];
      } else {
        return [Color(0xFF833AB4), Color(0xFFF77737)];
      }
    }
  }

  // Get the text to display (without translation provider)
  String get displayText => widget.label;

  @override
  Widget build(BuildContext context) {
    final bool isGridSize = widget.label.contains('x');
    final bool isPlayerCount = widget.label.contains('Player');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
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
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: _isHovered ? 16 : 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: _getGradientColors().first.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: _isHovered ? 8 : 5,
                        spreadRadius: _isHovered ? 1 : 0,
                      ),
                    ],
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      size: _isHovered ? 20 : 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200),
                    style: GoogleFonts.montserrat(
                      fontSize: _isHovered ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    child: Text(displayText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
