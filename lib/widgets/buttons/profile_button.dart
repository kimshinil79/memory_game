import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flag/flag.dart';

class ProfileButton extends StatefulWidget {
  final User? user;
  final String? nickname;
  final VoidCallback onSignInPressed;
  final VoidCallback onProfilePressed;
  final Color gradientStart;
  final Color gradientEnd;
  final String? countryCode;

  const ProfileButton({
    Key? key,
    required this.user,
    required this.nickname,
    required this.onSignInPressed,
    required this.onProfilePressed,
    required this.gradientStart,
    required this.gradientEnd,
    this.countryCode,
  }) : super(key: key);

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onSignInPressed();
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(_isHovered ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.gradientStart.withOpacity(_isHovered ? 0.7 : 0.2),
                    widget.gradientEnd.withOpacity(_isHovered ? 0.7 : 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.gradientStart.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.login_rounded,
                color: _isHovered ? Colors.white : widget.gradientEnd,
                size: _isHovered ? 22 : 20,
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onProfilePressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
                horizontal: _isHovered ? 14 : 12, vertical: _isHovered ? 8 : 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.gradientStart.withOpacity(_isHovered ? 0.9 : 0.1),
                  widget.gradientEnd.withOpacity(_isHovered ? 0.9 : 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.gradientStart.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: _isHovered ? 24 : 20,
                  height: _isHovered ? 24 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.gradientStart,
                        widget.gradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: widget.countryCode != null &&
                            widget.countryCode!.isNotEmpty
                        ? ClipOval(
                            child: Flag.fromString(
                              widget.countryCode!.toLowerCase(),
                              height: _isHovered ? 20 : 18,
                              width: _isHovered ? 20 : 18,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: _isHovered ? 16 : 14,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200),
                    style: GoogleFonts.montserrat(
                      fontSize: _isHovered ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? Colors.white : widget.gradientEnd,
                    ),
                    child: Text(
                      widget.nickname ?? 'User',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
