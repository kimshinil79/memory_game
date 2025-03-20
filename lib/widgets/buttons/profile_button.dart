import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileButton extends StatelessWidget {
  final User? user;
  final String? nickname;
  final VoidCallback onSignInPressed;
  final VoidCallback onProfilePressed;
  final Color gradientStart;
  final Color gradientEnd;

  const ProfileButton({
    Key? key,
    required this.user,
    required this.nickname,
    required this.onSignInPressed,
    required this.onProfilePressed,
    required this.gradientStart,
    required this.gradientEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return IconButton(
        icon: Icon(Icons.login, color: Colors.black87, size: 20),
        onPressed: onSignInPressed,
        tooltip: 'Sign In',
      );
    }

    return InkWell(
      onTap: onProfilePressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientStart.withOpacity(0.1),
              gradientEnd.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          nickname ?? 'User',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: gradientEnd,
          ),
        ),
      ),
    );
  }
}
