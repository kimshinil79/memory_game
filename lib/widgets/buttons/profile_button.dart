import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import '../../providers/brain_health_provider.dart';
import '../../providers/language_provider.dart';

class ProfileButton extends StatelessWidget {
  final User? user;
  final String? nickname;
  final VoidCallback onSignInPressed;
  final VoidCallback onProfilePressed;
  final Color gradientStart;
  final Color gradientEnd;
  final String? countryCode;

  const ProfileButton({
    super.key,
    required this.user,
    required this.nickname,
    required this.onSignInPressed,
    required this.onProfilePressed,
    required this.gradientStart,
    required this.gradientEnd,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BrainHealthProvider>(
      builder: (context, brainHealthProvider, child) {
        return GestureDetector(
          onTap: user == null ? onSignInPressed : onProfilePressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE1E8ED),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null && countryCode != null) ...[
                  Flag.fromString(
                    countryCode!.toLowerCase(),
                    height: 12,
                    width: 16,
                    borderRadius: 2,
                  ),
                  const SizedBox(width: 2),
                  // 브레인 레벨 이미지
                  Image.asset(
                    _getBrainLevelImage(
                        brainHealthProvider.brainHealthIndexLevel),
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 2),
                ],
                Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) {
                    final translations = languageProvider.getUITranslations();
                    return Text(
                      user == null
                          ? (translations['login'] ?? 'Login')
                          : (nickname ?? 'User'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF14171A),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getBrainLevelImage(int level) {
    switch (level) {
      case 1:
        return 'assets/icon/level1_brain.png';
      case 2:
        return 'assets/icon/level2_brain.png';
      case 3:
        return 'assets/icon/level3_brain.png';
      case 4:
        return 'assets/icon/level4_brain.png';
      case 5:
        return 'assets/icon/level5_brain.png';
      default:
        return 'assets/icon/level1_brain.png';
    }
  }
}
