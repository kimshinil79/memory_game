import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class ItemPopup extends StatelessWidget {
  final bool showItemPopup;
  final Color instagramGradientStart;
  final Color instagramGradientEnd;

  const ItemPopup({
    super.key,
    required this.showItemPopup,
    required this.instagramGradientStart,
    required this.instagramGradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (!showItemPopup) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    
    // 인스타그램 스타일 그라데이션
    final List<Color> backgroundGradient = isDarkMode
        ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D),
            const Color(0xFF1A1A1A),
          ]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xFFFAFAFA),
            const Color(0xFFF5F5F5),
          ];
    
    final Color accentColor = isDarkMode
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF6366F1);
    
    final Color textColor = isDarkMode
        ? const Color(0xFFE5E5E5)
        : const Color(0xFF1F2937);
    
    final Color borderColor = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFE5E7EB);

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: backgroundGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // 외부 그림자
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.15),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 25),
              ),
              // 내부 그림자 효과
              BoxShadow(
                color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.3),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, -10),
              ),
            ],
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 배경 원형
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.shuffle_rounded,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // 텍스트 컨테이너
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  Provider.of<LanguageProvider>(context)
                          .getUITranslations()['random_shake'] ??
                      'Random Shake!!',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 서브텍스트
              Text(
                'Cards shuffled!',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor.withOpacity(0.7),
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
